require 'json'

get '/' do
  "Server Status #{find_server.state}"
end

post '/' do
  push = JSON.parse(params[:payload])
  puts "I got some JSON: #{push.inspect}"
  start_server
  "I got some JSON: #{push.inspect}"
end

require 'fog'

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
end

def stop_server
  server = find_server
  server.stop
end

#start_server
#stop_server
