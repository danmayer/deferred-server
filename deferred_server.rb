require 'rubygems'
require 'bundler/setup'
$LOAD_PATH << File.dirname(__FILE__) + '/lib'

require 'json'
require 'fog'
require 'rest-client'
require 'digest/md5'
require 'server-commands'
require 'server-files'
require 'code-signing'
require 'deferred_server_cli'
require 'env'

include ServerFiles
include ServerCommands
include CodeSigning
include DeferredEnv

# Run me with 'ruby' and I run as a script
if $0 =~ /#{File.basename(__FILE__)}$/
  DeferredServerCli.new(ARGV).run
else
  require 'sinatra'
  require 'sinatra_env'

  module DeferredServer
    class App < Sinatra::Base
      include SinatraEnv

      get '/' do
        @server_state = find_server.state
        @projects = get_projects_by_user
        erb :index
      end

      get '/examples' do
        @title = "Examples of Deferred-Server"
        erb :examples
      end

      after '/account' do
        session['user_script'] = nil
        session['signature'] = nil
      end

      get '/account' do
        authenticate!
        @server_state = find_server.state
        @projects = get_projects_by_user(github_user.login)
        @signature = session['signature'] || nil
        @user_script = session['user_script'] || "puts 'enter ruby code here'"
        erb :account
      end

      post '/sign_script' do
        authenticate!
        code = params['user_script']
        signature = code_signature(code)
        session['user_script'] = code
        session['signature'] = signature
        redirect "/account"
      end

      get '/deferred_code' do
        jsonp handle_deferred_code
      end

      post '/deferred_code' do
        handle_deferred_code
      end

      get '/results/*' do |results_future|
        results = get_file(results_future)
        if results && results!=''
          jsonp ({:results => results}.to_json)
        else
          jsonp ({:not_complete => true}.to_json)
        end
      end

      get '/*/commits/*' do |project_key,commit|
        @project_key = project_key
        @commit = commit
        @title = "Deferred Server: #{@project_key} : #{@commit}"

        commit_key, @commit_hash = get_commit_key_and_data(project_key, commit)
        @run_results = get_run_results_data(commit_key)

        erb :project_commit_results
      end

      post '/request_complete' do
        project_key = params['project_key']
        commit_key = params['commit_key']
        results_file_data = get_file(commit_key)
        results_data = JSON.parse(results_file_data)

        if results_data['exit_status'].to_i > 0
          body_txt = "while running `#{results_data['cmd_run']}` on your project there was a failure \n\n"
          body_txt += results_data['results']
          to_email = extract_author_email(project_key, commit_key)

          RestClient.post MAIL_API_URL+"/messages",
          :from => "dan@mayerdan.com",
          :to => to_email,
          :subject => "project #{project_key} had a failure",
          :text => body_txt,
          :html => body_txt.gsub("\n","<br/>")
        end
      end

      get '/*' do |project_key|
        @project_key = project_key
        @commits = get_commits(project_key)
        @title = "Deferred Server: #{@project_key}"

        erb :project
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

      private

      def hash_to_querystring(hash)
        hash.keys.inject('') do |query_string, key|
          query_string << '&' unless key == hash.keys.first
          query_string << "#{URI.encode(key.to_s)}=#{URI.encode(hash[key])}"
        end
      end

      def handle_deferred_code
        payload_signature = params['signature']
        script_payload = params['script_payload']
        if payload_signature == code_signature(script_payload)

          if ENV['RACK_ENV']=='development' && false
            server = "fake"
            server_ip = '127.0.0.1:3001'
          else
            if find_server.state=="stopped"
              server = start_server
              {:server => {:state => 'starting'}}.to_json
              return
            else
              server = start_server
              server_ip = server.public_ip_address
            end
          end

          results_future = "script_results/results_for_#{payload_signature}_#{Time.now.utc.to_i}"

          push = {
            :results_location => results_future,
            :script_payload => script_payload
          }

          response = post_to_server(:payload, push, {:server => server, :server_ip => server_ip})

          {:results_location => "results/#{results_future}"}.to_json
        else
          puts "error signature was passed #{payload_signature} expecting #{code_signature(script_payload)}"
          'invalid signed code'
        end
      end
    end
  end

end
