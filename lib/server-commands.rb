module ServerCommands
  #DEFAULT_AMI = ENV['WAKE_UP_AMI'] || 'ami-0267bb6b'
  DEFAULT_AMI = ENV['WAKE_UP_AMI'] || 'ami-210a8b48'
  EC2_KEY_PAIR = ENV['EC2_KEY_PAIR'] || 'dans-personal'
  EC2_PRIVATE_KEY = ENV['EC2_PRIVATE_KEY']
  EC2_USER_NAME = ENV['EC2_USER_NAME'] || 'bitnami'

  def find_server
    compute = Fog::Compute.new(
                               :provider          => 'AWS',
                               :aws_access_key_id => ENV['AMAZON_ACCESS_KEY_ID'],
                               :aws_secret_access_key => ENV['AMAZON_SECRET_ACCESS_KEY'])

    server = compute.servers.detect{ |server| server.image_id==DEFAULT_AMI && server.ready? }
    server ||= compute.servers.detect{ |server| server.image_id==DEFAULT_AMI }
    server = nil

    if server.nil?
      puts "creating new server"
      user_data = File.read('./config/user_data.txt')
      puts "adding user data:\n #{user_data}"
      server = compute.servers.create(:image_id => DEFAULT_AMI,
                                      :name => 'wakeup-hook-responder',
                                      :key_name => EC2_KEY_PAIR,
                                      :user_data => user_data)
    end
    server.private_key = EC2_PRIVATE_KEY
    server.username    = EC2_USER_NAME
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

    puts "server is ready"
    server
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
  def bootstrap_server(server)
    begin
      unless server.ssh("ls /opt/bitnami/apps/").first.stdout.match(/server_responder/)
        server.ssh("cd /opt/bitnami/apps/\; sudo git clone https://github.com/danmayer/server_responder.git")
        server.scp('./config/remote_server_files/extra_httpd-vhosts.conf','/tmp/extra_httpd-vhosts.conf')
        server.ssh("sudo mv /tmp/extra_httpd-vhosts.conf /opt/bitnami/apache2/conf/extra/httpd-vhosts.conf")

        server.ssh("echo 'Include conf/extra/httpd-vhosts.conf' >> /opt/bitnami/apache2/conf/httpd.conf")
        server.ssh("sudo chown -R bitnami:root /opt/bitnami/apps/server_responder")
        server.ssh("sudo gem install bundler")
        server.ssh("sudo gem install nokogiri -v=1.5.5 -- --with-xml2-dir=/opt/bitnami/common --with-xslt-dir=/opt/bitnami/common --with-xml2-include=/opt/bitnami/common/include/libxml2 --with-xslt-include=/opt/bitnami/common/include --with-xml2-lib=/opt/bitnami/common/lib --with-xslt-lib=/opt/bitnami/common/lib")
        server.ssh("cd /opt/bitnami/apps/server_responder\; sudo bundle install")

        #add env vars
        server.ssh("sudo echo \"export AMAZON_ACCESS_KEY_ID='#{ENV['AMAZON_ACCESS_KEY_ID']}'\" >> /opt/bitnami/scripts/setenv.sh")
        server.ssh("sudo echo \"export AMAZON_SECRET_ACCESS_KEY='#{ENV['AMAZON_SECRET_ACCESS_KEY']}'\" >> /opt/bitnami/scripts/setenv.sh")
        server.ssh("sudo echo \"export SERVER_RESPONDER_API_KEY='#{ENV['SERVER_RESPONDER_API_KEY']}'\" >> /opt/bitnami/scripts/setenv.sh")

        #enable SSL
        #newer bitnami has ssl enabled already!!! Hooray
        #server.ssh("echo 'Include conf/extra/httpd-ssl.conf' >> /opt/bitnami/apache2/conf/httpd.conf")
        server.scp('./config/remote_server_files/httpd-ssl.conf','/tmp/extra_httpd-ssl.conf')
        server.ssh("sudo mv /tmp/extra_httpd-ssl.conf /opt/bitnami/apache2/conf/extra/httpd-ssl.conf")

        server.ssh("sudo apachectl restart")
    end
    rescue => error
      puts error
    end
  end


  def stop_server
    server = find_server
    server.stop
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
