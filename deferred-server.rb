require 'json'
require 'fog'
require 'rest-client'
require 'digest/md5'
require './lib/server-commands'
require './lib/server-files'
include ServerFiles
include ServerCommands

DEFAULT_AMI   = ENV['WAKE_UP_AMI'] || 'ami-0267bb6b'
ALLOWED_USERS = ['danmayer']
TRUSTED_IPS   = ['207.97.227.253', '50.57.128.197', '108.171.174.178', '127.0.0.1']

# Run me with 'ruby' and I run as a script
if $0 =~ /#{File.basename(__FILE__)}$/
  puts "running as local script"

  write_file('projects-test',"test-data")
  projects = get_file('projects-test')
  puts projects

  # server = start_server

  # server_ip = server.public_ip_address
  # #server_ip = "127.0.0.1:3000"

  # push = {:test => 'fake'}

  # puts "server is at #{server_ip}"
  # response = post_to_server(:payload, push, {:server => server, :server_ip => server_ip})
  # puts response.inspect
  # #stop_server

  puts "done"
else

  get '/' do
    projects = get_projects
    @server_state = find_server.state
    @projects = projects
    erb :index
  end

  post '/' do
    push = JSON.parse(params['payload'])
    puts push['repository']['owner']
    user = push['repository']['owner']['name'] rescue nil
    puts "user #{user} user allowed: #{ALLOWED_USERS.include?(user)}"
    puts "trust ip: #{TRUSTED_IPS.include?(request.ip)} ip: #{request.ip}"
    if ALLOWED_USERS.include?(user) && TRUSTED_IPS.include?(request.ip)
      project_name = push['repository']['name']
      project_key = "#{user}/#{project_name}"

      projects = get_projects
      unless projects[project_key]
        projects[project_key] = true
        write_file('projects_json',projects.to_json)
      end

      server = start_server

      #get server endpoint
      server_ip = server.public_ip_address

      #post payload to ec2 server
      response = post_to_server(:payload, push, {:server => server, :server_ip => server_ip})
    else
      "not allowed"
    end
  end

end
