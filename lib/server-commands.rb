module ServerCommands

  class ChefInitError < StandardError; end

  #NEW in progress bootstrapped server
  DEFAULT_AMI = ENV['WAKE_UP_AMI'] || 'ami-210a8b48'
  DEFAULT_CHEF_AMI = ENV['DEFAULT_CHEF_AMI'] || 'ami-de0d9eb7'

  EC2_KEY_PAIR = ENV['EC2_KEY_PAIR'] || 'dans-personal'
  EC2_PRIVATE_KEY = ENV['EC2_PRIVATE_KEY']
  EC2_USER_NAME = ENV['EC2_USER_NAME'] || 'bitnami'
  EC2_CHEF_USER_NAME = ENV['EC2_CHEF_USER_NAME'] || 'ubuntu'
  API_KEY = ENV['SERVER_RESPONDER_API_KEY']
  DEFAULT_SERVER_NAME = 'wakeup-hook-responder'

  def compute
    @compute ||= Fog::Compute.new(:provider          => 'AWS',
                                  :aws_access_key_id => ENV['AMAZON_ACCESS_KEY_ID'],
                                  :aws_secret_access_key => ENV['AMAZON_SECRET_ACCESS_KEY'])
  end
  
  def find_server(options = {})
    image_id        = options['ami_id'] || DEFAULT_AMI
    image_user_name = options['user'] || EC2_USER_NAME

    if options['instance-id']
      server = compute.servers.detect{ |server| server.id==options['instance-id'] }
    else
      server = compute.servers.detect{ |server| server.image_id==image_id && server.ready? }
      server ||= compute.servers.detect{ |server| server.image_id==image_id && server.state!='terminated' }
    end

    if server.nil?
      create_new_server(image_id, options = {})
    end
    server.private_key = EC2_PRIVATE_KEY
    server.username    = image_user_name
    server
  rescue Excon::Errors::Timeout
    puts "timed out try again"
    retry
  end
  
  def create_new_chef_server(options = {})
    create_new_server(DEFAULT_CHEF_AMI, options)
  end

  def create_new_server(image_id, options = {})
    server_name = options['server_name'] || DEFAULT_SERVER_NAME
    puts "creating new server #{server_name}"
    server = compute.servers.create(:image_id => image_id,
                                    :tags => {'Name' => server_name},
                                    :key_name => EC2_KEY_PAIR)
  end

  def start_chef_server(options = {})
    image_id        = options['ami_id'] || DEFAULT_CHEF_AMI
    image_user_name = options['user'] || EC2_CHEF_USER_NAME

    server = find_server({'ami_id' => image_id, 'user' => image_user_name})

    begin
      if server && !server.ready?
        puts "starting server"
        server.start
      end
      
      server.wait_for { ready? }
      puts "server preparing..."
      sleep(20)
    rescue Fog::Compute::AWS::Error => error
      puts "error trying to get server, trying again: #{error}"
      retry
    end

    chef_bootstrap_server(server)    

    puts "server is ready"
    server
  end

  def start_server(options = {})
    user = options['user'] || 'shared'
    
    server = if user=='shared'
               find_server(options)
             else
               find_server(options)
             end

    begin
      if server && !server.ready?
        puts "starting server"
        server.start
      end

      server.wait_for { ready? }
    rescue Fog::Compute::AWS::Error => error
      puts "error trying to get server, trying again: #{error}"
      retry
    end
    begin
      bootstrap_server(server)
    rescue Errno::EHOSTUNREACH
      puts "server not yet ready, trying again"
      retry
    end

    puts "server is ready"
    server
  end

  #TODO why did I have to scp to tmp folder first and then move? grumble
  def copy_files_and_maintain_structure(server, src_dir, dest_dir, options = {})
    directories = Dir.glob("#{src_dir}/**/*/")
    server_cmd(server, "mkdir #{dest_dir}")
    
    files =  Dir.glob("#{src_dir}/**/*")
    files.each do |file|
      tmp_file = file.gsub(/#{src_dir}/,'/tmp')
      remote_file = file.gsub(/#{src_dir}/,dest_dir)
      if File.directory?(file)
        server_cmd(server, "mkdir -p #{tmp_file}")
        server_cmd(server, "mkdir -p #{remote_file}")
      else
        server.scp(file, tmp_file)
        server_cmd(server, "mv #{tmp_file} #{remote_file}")
      end
    end
  end

  def chef_bootstrap_server(server, options = {})
    attempt = 0
    max_attempts = 3
    begin
      puts "bootstrapping server #{server}"

      server_cmd(server, "sudo rm -rf ~/chef")
      copy_files_and_maintain_structure(server, './chef', '~/chef')
      chef_attempts = 0
      begin
        bootstrap_result = server_cmd(server, "cd ~/chef; sudo bash install.sh")
        if bootstrap_result.status!=0
          raise ChefInitError
        end
      rescue ChefInitError
        chef_attempts += 1
        if chef_attempts <= max_attempts
          puts "chef failure, retrying #{chef_attempts} of #{max_attempts}"
          sleep(4)
          retry
        end
      end

    rescue Errno::ECONNREFUSED => error
      attempt += 1
      if attempt <= max_attempts
        puts "connection issue, retrying #{attempt} of #{max_attempts}"
        sleep(4)
        retry
      end
    rescue => error
      puts "error bootstrapping #{error}"
      raise error
    end
  end    

  ####
  # at the moment SSHing some cmds one at a time
  # eventually want to scp over user_data, then ssh to execute it
  # that file should do chef configuration
  #
  # This will wait until the server can respond to SSH, then it will
  # install server_responder, configure apache/passenger to run server_responder
  # it will set up any needed environment variables, SSL, etc
  # eventually this is where users could also attach user specific chef scripts
  # basically the default will always be to setup, server_responder and then
  # additional server specific configuration can be layered on top of this
  ####
  def bootstrap_server(server, options = {})
    attempt = 0
    max_attempts = 3
    begin
      puts "bootstrapping server #{server}"
      if server_cmd(server,"ls /opt/bitnami/apps/").stdout.match(/server_responder/) && options[:level]!='full'
        puts "fast bootstrap"
        server_cmd(server, "cd /opt/bitnami/apps/server_responder\; git checkout .; sudo git pull;")
        server_cmd(server,"sudo chown -R bitnami:bitnami /opt/bitnami/apps/server_responder")
        server_cmd(server,"sudo apachectl restart")
      else
        puts "full bootstrap"
        server_cmd(server,"cd /opt/bitnami/apps/\; sudo git clone https://github.com/danmayer/server_responder.git")
        server.scp('./config/remote_server_files/extra_httpd-vhosts.conf','/tmp/extra_httpd-vhosts.conf')
        server_cmd(server,"sudo mv /tmp/extra_httpd-vhosts.conf /opt/bitnami/apache2/conf/extra/httpd-vhosts.conf")

        server.scp('./config/remote_server_files/bitnamirc','/tmp/bitnamirc')
        server_cmd(server,"sudo mv /tmp/bitnamirc /opt/bitnami/.bitnamirc")

        server.scp('./config/remote_server_files/gemrc','/tmp/gemrc')
        server_cmd(server,"sudo mv /tmp/gemrc /home/bitnami/.gemrc")

        server_cmd(server,"echo 'Include conf/extra/httpd-vhosts.conf' | sudo tee -a /opt/bitnami/apache2/conf/httpd.conf")
        server_cmd(server,"sudo chown -R bitnami:bitnami /opt/bitnami/apps/server_responder")
        server_cmd(server,"sudo chmod -R o+rw apps/server_responder/tmp")
        server_cmd(server,"sudo chmod -R o+rw apps/server_responder/artifacts")
        server_cmd(server,"sudo chmod -R o+rw apps/server_responder/log")

        server_cmd(server,"sudo touch apps/server_responder/log/sinatra.log")
        server_cmd(server,"sudo chmod 666 apps/server_responder/log/sinatra.log")

        server_cmd(server,"sudo mkdir /opt/bitnami/apps/projects/")
        server_cmd(server,"sudo chown -R bitnami:bitnami /opt/bitnami/apps/projects")
        server_cmd(server,"sudo chmod -R o+rw /opt/bitnami/apps/projects")

        server.scp('./config/remote_server_files/passenger.conf','/tmp/passenger.conf')
        server_cmd(server,"sudo mv /tmp/passenger.conf /opt/bitnami/apache2/conf/bitnami/passenger.conf")
        server_cmd(server,"sudo gem install bundler")
        server_cmd(server,"sudo gem install nokogiri -v=1.5.5 -- --with-xml2-dir=/opt/bitnami/common --with-xslt-dir=/opt/bitnami/common --with-xml2-include=/opt/bitnami/common/include/libxml2 --with-xslt-include=/opt/bitnami/common/include --with-xml2-lib=/opt/bitnami/common/lib --with-xslt-lib=/opt/bitnami/common/lib")
        server_cmd(server,'sudo chown -R bitnami:bitnami /opt/bitnami/ruby/')
        server_cmd(server,'sudo chown -R bitnami:bitnami /opt/bitnami/rvm')

        server_cmd(server,"cd /opt/bitnami/apps/server_responder\; sudo bundle install")

        #add env vars
        server_cmd(server,"sudo echo \"export AMAZON_ACCESS_KEY_ID='#{ENV['AMAZON_ACCESS_KEY_ID']}'\" | sudo tee -a /opt/bitnami/scripts/setenv.sh")
        server_cmd(server,"sudo echo \"export AMAZON_SECRET_ACCESS_KEY='#{ENV['AMAZON_SECRET_ACCESS_KEY']}'\" | sudo tee -a /opt/bitnami/scripts/setenv.sh")
        server_cmd(server,"sudo echo \"export SERVER_RESPONDER_API_KEY='#{API_KEY}'\" | sudo tee -a /opt/bitnami/scripts/setenv.sh")

        #enable SSL
        #newer bitnami has ssl enabled already!!! Hooray
        #server.ssh("echo 'Include conf/extra/httpd-ssl.conf' >> /opt/bitnami/apache2/conf/httpd.conf")
        server.scp('./config/remote_server_files/httpd-ssl.conf','/tmp/extra_httpd-ssl.conf')
        server_cmd(server,"sudo mv /tmp/extra_httpd-ssl.conf /opt/bitnami/apache2/conf/extra/httpd-ssl.conf")

        server_cmd(server,"sudo apachectl restart")
      end
    rescue Errno::ECONNREFUSED => error
      attempt += 1
      if attempt <= max_attempts
        puts "connection issue, retrying #{attempt} of #{max_attempts}"
        sleep(4)
        retry
      end
    rescue => error
      puts "error bootstrapping #{error}"
      raise error
    end
  end

  def server_cmd(server, cmd)
    puts "running: #{cmd}" if ENV['SERVER_CMDS_DEBUG']
    result = server.ssh(cmd)
    puts "result: #{result.inspect}" if ENV['SERVER_CMDS_DEBUG']
    result[0]
  end

  def stop_server(options)
    server = find_server(options)
    server.stop
  end

  def restart_server
    server = find_server
    server.reboot
  end

  def post_to_server(wrapper, package, options = {})
    begin
      server = options.fetch(:server){ find_server }
      server_ip = options.fetch(:server_ip){ server.public_ip_address }
      puts "posting to #{server_ip} with #{package.inspect}"
      protocal = ENV['RACK_ENV']=='development' ? 'http' : 'https'
      response = RestClient.post "#{protocal}://#{server_ip}?api_token=#{API_KEY}", wrapper => package.to_json, :content_type => :json, :accept => :json
    rescue Errno::ECONNREFUSED, RestClient::ServerBrokeConnection
      puts "server not ready yet try again"
      sleep(3)
      retry
    end
  end

  def shutdown_inactive_servers
    compute.servers.each do |server|
      server_ip = server.public_ip_address
      last_job_time = Time.now
      begin
        response = RestClient.get "http://#{server_ip}/last_job", :content_type => :json, :accept => :json
        time_data = JSON.parse(response)
        last_job_time = Time.parse(time_data['last_time']) rescue Time.now
        minutes_ago = 60 * MINUTES_SINCE_LAST_JOB
        if last_job_time < Time.at(Time.now.to_i-minutes_ago)
          puts "shutdown"
          server.stop
        else
          puts "#{server.id} still active"
        end
      rescue => err
        puts "on #{server.id} has #{err} server likely not running skipping it"
      end
    end
  end

end
