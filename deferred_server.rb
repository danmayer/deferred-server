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

include ServerFiles
include ServerCommands
include CodeSigning

ALLOWED_USERS = ['danmayer']

API_KEY = ENV['SERVER_RESPONDER_API_KEY']
MAIL_API_KEY = ENV['MAILGUN_API_KEY']
MAIL_API_URL = "https://api:#{MAIL_API_KEY}@api.mailgun.net/v2/app7941314.mailgun.org"

#trusted IPs from GH /admin/hooks
#https://github.com/danmayer/deferred-server/settings/hooks
TRUSTED_IPS   = ['207.97.227.253', '50.57.128.197',
                 '108.171.174.178', '127.0.0.1',
                 '50.57.231.61', '54.235.183.49',
                 '54.235.183.23', '54.235.118.251',
                 '54.235.120.57', '54.235.120.61',
                 '54.235.120.62']

# Run me with 'ruby' and I run as a script
if $0 =~ /#{File.basename(__FILE__)}$/
  DeferredServerCli.new(ARGV).run
else
  require 'sinatra'
  module DeferredServer
    class App < Sinatra::Base
      require 'sinatra/jsonp'
      require 'sinatra_auth_github'
      helpers Sinatra::Jsonp

      set :public_folder, File.dirname(__FILE__) + '/public'
      set :root, File.dirname(__FILE__)

      use Rack::Session::Cookie, :key => 'rack.session',
      :path => '/',
      :expire_after => 2592000,
      :secret => "#{API_KEY}cookie",
      :old_secret => "#{API_KEY}_old_cookie"

      set :github_options, {
        :scopes    => "user",
        :secret    => ENV['DS_GH_Client_Secret'],
        :client_id => ENV['DS_GH_Client_ID'],
      }

      register Sinatra::Auth::Github

      get '/' do
        @server_state = find_server.state
        @projects = get_projects_by_user
        erb :index
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

      get '/examples' do
        @title = "Examples of Deferred-Server"
        erb :examples
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
        commits = get_commits(project_key)
        commit_key = commits[commit]
        if commit_key.is_a?(Hash)
          @commit_hash = commit_key['push']
          commit_key = commit_key['uri']
        end

        @project_key = project_key
        @commit = commit
        results_file_data = get_file(commit_key)
        begin
          results_data = JSON.parse(results_file_data)
          @results = results_data['results']
          @exit_status = results_data['exit_status']
          @cmd_run = results_data['cmd_run']
        rescue
          #old format just straight results
          @results = results_file_data
        end
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
            server = start_server
            #get server endpoint
            server_ip = server.public_ip_address
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
