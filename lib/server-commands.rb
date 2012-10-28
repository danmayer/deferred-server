module ServerCommands
  DEFAULT_AMI   = ENV['WAKE_UP_AMI'] || 'ami-0267bb6b'

  def find_server
    compute = Fog::Compute.new(
                               :provider          => 'AWS',
                               :aws_access_key_id => ENV['AMAZON_ACCESS_KEY_ID'],
                               :aws_secret_access_key => ENV['AMAZON_SECRET_ACCESS_KEY'])

    server = compute.servers.detect{ |server| server.image_id==DEFAULT_AMI && server.ready? }
    server ||= compute.servers.detect{ |server| server.image_id==DEFAULT_AMI }

    if server.nil?
      puts "creating new server"
      server = compute.servers.create(:image_id => DEFAULT_AMI,
                                      :name => 'wakeup-hook-responder')
    end
    server
  end

  def start_server
    server = find_server

    if server && !server.ready?
      puts "starting server"
      server.start
    end

    server.wait_for { ready? }

    puts "server is ready"
    server
  end

  def stop_server
    server = find_server
    server.stop
  end

  def post_to_server(wrapper, package, options = {})
    server = options.fetch(:server){ find_server }
    server_ip = options.fetch(:server_ip){ server.public_ip_address }
    puts "posting to #{server_ip} with #{package.inspect}"
    protocal = ENV['RACK_ENV']=='development' ? 'http' : 'https'
    response = RestClient.post "#{protocal}://#{server_ip}?api_token=#{API_KEY}", wrapper => package.to_json, :content_type => :json, :accept => :json
  end

end
