require 'json'
require 'fog'
require 'rest-client'

DEFAULT_AMI = ENV['WAKE_UP_AMI'] || 'ami-0267bb6b'

# Run me with 'ruby' and I run as a script
if $0 =~ /#{File.basename(__FILE__)}$/
  puts "running as local script"

  server = start_server

  server_ip = server.public_ip_address
  #server_ip = "127.0.0.1:3000"

  push = {:test => 'fake'}

  puts "server is at #{server_ip}"
  response = post_to_server(:payload, push, {:server => server, :server_ip => server_ip})
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
    response = post_to_server(:payload, push, {:server => server, :server_ip => server_ip})
  end

end
