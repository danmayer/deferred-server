module ServerCommands

  #NEW in progress bootstrapped server
  DEFAULT_AMI = ENV['WAKE_UP_AMI'] || 'ami-210a8b48'

  EC2_KEY_PAIR = ENV['EC2_KEY_PAIR'] || 'dans-personal'
  EC2_PRIVATE_KEY = ENV['EC2_PRIVATE_KEY']
  EC2_USER_NAME = ENV['EC2_USER_NAME'] || 'bitnami'
  API_KEY = ENV['SERVER_RESPONDER_API_KEY']

  def find_server(opts = {})
    image_id = opts['ami_id'] || DEFAULT_AMI
    image_user_name = opts['user'] || EC2_USER_NAME
    compute = Fog::Compute.new(:provider          => 'AWS',
                               :aws_access_key_id => ENV['AMAZON_ACCESS_KEY_ID'],
                               :aws_secret_access_key => ENV['AMAZON_SECRET_ACCESS_KEY'])

    server = compute.servers.detect{ |server| server.image_id==image_id && server.ready? }
    server ||= compute.servers.detect{ |server| server.image_id==image_id && server.state!='terminated' }

    if server.nil?
      puts "creating new server"
      user_data = File.read('./config/user_data.txt')
      puts "adding user data:\n #{user_data}"
      server = compute.servers.create(:image_id => image_id,
                                      :name => 'wakeup-hook-responder',
                                      :key_name => EC2_KEY_PAIR,
                                      :user_data => user_data)
    end
    server.private_key = EC2_PRIVATE_KEY
    server.username    = image_user_name
    server
  end

  def start_chef_server
    server = find_server({'ami_id' => 'ami-de0d9eb7',
                         'user' => 'ubuntu'})

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

    chef_bootstrap_server(server)    

    puts "server is ready"
    server
  end

  def start_server
    server = find_server

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
    bootstrap_server(server)

    puts "server is ready"
    server
  end

  def chef_bootstrap_server(server, options = {})
    attempt = 0
    max_attempts = 3
    begin
      puts "bootstrapping server #{server}"

      server.scp('./chef/install.sh','/tmp/install.sh')
      server.scp('./chef/solo.rb','/tmp/solo.rb')
      server.scp('./chef/solo.json','/tmp/solo.json')
      server.scp('./chef/cookbooks/op/recipes/default.rb','/tmp/default.rb')
      server_cmd(server, "sudo rm -rf ~/chef && mkdir ~/chef")
      server_cmd(server, "mv /tmp/install.sh ~/chef/install.sh")
      server_cmd(server, "mv /tmp/solo.rb ~/chef/solo.rb")
      server_cmd(server, "mv /tmp/solo.json ~/chef/solo.json")
      server_cmd(server, "mkdir -p ~/chef/cookbooks/op/recipes/")
      server_cmd(server, "mv /tmp/default.rb ~/chef/cookbooks/op/recipes/default.rb")
      server_cmd(server, "cd ~/chef; sudo bash install.sh")

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
      if server_cmd(server,"ls /opt/bitnami/apps/").first.stdout.match(/server_responder/) && options[:level]!='full'
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
    result
  end

  def stop_server
    server = find_server
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
    rescue Errno::ECONNREFUSED
      puts "server not ready yet try again"
      sleep(3)
      retry
    end
  end

end
