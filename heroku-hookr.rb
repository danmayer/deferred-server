require 'json'
require 'fog'
require 'rest-client'

DEFAULT_AMI = ENV['WAKE_UP_AMI'] || 'ami-0267bb6b'

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

# Run me with 'ruby' and I run as a script
if $0 =~ /#{File.basename(__FILE__)}$/
  puts "running as local script"

  server = start_server

  #server_ip = server.public_ip_address
  server_ip = "127.0.0.1:3000"

  puts "server is at #{server_ip}"
  response = RestClient.post "http://#{server_ip}", :data => {:test => 'data'}.to_json, :content_type => :json, :accept => :json
  puts response.inspect
  #stop_server

  puts "done"

else

  get '/' do
    "Server Status #{find_server.state}"
  end

  post '/' do
    push = JSON.parse(params[:payload])
    server = start_server

    #get server endpoint
    server_ip = server.public_ip_address

    #post payload to ec2 server
    response = RestClient.post "http://#{server_ip}", params.to_json, :content_type => :json, :accept => :json
    puts response.inspect
  end

end
