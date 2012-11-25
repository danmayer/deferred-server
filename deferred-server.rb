require 'json'
require 'fog'
require 'rest-client'
require 'digest/md5'
require './lib/server-commands'
require './lib/server-files'
require './lib/code-signing'
include ServerFiles
include ServerCommands
include CodeSigning

ALLOWED_USERS = ['danmayer']

API_KEY = ENV['SERVER_RESPONDER_API_KEY']

#trusted IPs from GH /admin/hooks
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
  require "sinatra/jsonp"
  helpers Sinatra::Jsonp
  set :public_folder, File.dirname(__FILE__) + '/public'

  get '/' do
    @server_state = find_server.state
    @projects = get_projects_by_user
    erb :index
  end

  get '/deferred_code' do
    jsonp handle_deferred_code
  end

  get '/*/commits/*' do |project_key,commit|
    commits = get_commits(project_key)
    commit_key = commits[commit]

    @project_key = project_key
    @commit = commit
    @results = get_file(commit_key)
    erb :project_commit_results
  end

  get '/results/*' do |results_future|
    results = get_file(results_future)
    if results && results!=''
      jsonp {:results => results}.to_json
    else
      jsonp {:not_complete => true}.to_json
    end
  end

  get '/*' do |project_key|
    @project_key = project_key
    @commits = get_commits(project_key)
    erb :project
  end

  post '/deferred_code' do
    handle_deferred_code
  end

  def handle_deferred_code
    payload_signature = params['signature']
    script_payload = params['script_payload']
    if payload_signature == code_signature(script_payload)

      if ENV['RACK_ENV']=='development' && false
        server = "fake"
        server_ip = '127.0.0.1:3001'
      else
        server = start_server
        #get server endpoint
        server_ip = server.public_ip_address
      end

      results_future = "results_for_#{payload_signature}_#{Time.now.utc.to_i}"

      push = {
        :results_location => results_future,
        :script_payload => script_payload
      }

      response = post_to_server(:payload, push, {:server => server, :server_ip => server_ip})

      {:results_location => "results/#{results_future}"}.to_json
    else
      'invalid signed code'
    end
  end

  post '/' do
    push = JSON.parse(params['payload'])
    user = push['repository']['owner']['name'] rescue nil
    puts "user #{user} user allowed: #{ALLOWED_USERS.include?(user)}"
    puts "trust ip: #{TRUSTED_IPS.include?(request.ip)} ip: #{request.ip}"
    if ALLOWED_USERS.include?(user) && TRUSTED_IPS.include?(request.ip)
      project_name = push['repository']['name']
      project_key = "#{user}/#{project_name}"
      project_last_updated = push['commits'].last['timestamp'] rescue Time.now

      projects = get_projects
      projects[project_key] = project_last_updated
      write_file('projects_json',projects.to_json)

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
