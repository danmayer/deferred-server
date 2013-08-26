# encoding: UTF-8
require 'rubygems'
require 'bundler/setup'
$LOAD_PATH << File.dirname(__FILE__) + '/lib'

require 'env'
include DeferredEnv

# Run me with 'ruby' and I run as a script
if $0 =~ /#{File.basename(__FILE__)}$/
  DeferredServerCli.new(ARGV).run
else
  require 'sinatra'
  require 'sinatra_env'
  require 'airbrake'

  module Rack
    class Catcher
    
      def initialize(app)
        @app = app
      end
      
      def call(env)
        begin
          response = @app.call(env)
        rescue => ex
          "error"
        end
        response
      end

    end
  end

  module DeferredServer
    class App < Sinatra::Base
      include SinatraEnv

      if ENV['RACK_ENV'] == "production"
        Airbrake.configure do |config|
          config.api_key = 'eb803888751bf13cc69fda7480a3a91f'
          config.host    = 'errors.picoappz.com'
          config.port    = 80
          config.secure  = config.port == 443
        end
        use Airbrake::Rack
        set :raise_errors, true
        use Rack::Catcher
      end

      get '/' do
        @server_state = find_server.state
        @projects = get_projects_by_user
        erb :index
      end

      get '/examples' do
        @title = "Examples of Deferred-Server"
        erb :examples
      end

      get '/deferred_code' do
        jsonp handle_deferred_code
      end

      post '/deferred_code' do
        handle_deferred_code
      end

      post '/deferred_project_command' do
        deferred_project_command
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

      get '/scripts/*' do |project_key|
        @project_key = project_key
        @commits = get_commits(project_key)
        @title = "Deferred Server: #{@project_key}"

        erb :project
      end

      get '/*' do |key|
        @title = "Deferred Server: #{key}"
        if key.match(/\/scripts\//)
          @script_key  = key
          @signature   = key.match(/\/scripts\/(.*)/)[1]
          @user_script = get_script(@script_key)
     
          erb :script
        else
          if github_user
            @account = Account.new(github_user.login)
          end
          @project_key = key
          @commits = get_commits(@project_key)
     
          erb :project
        end
      end

      post '/' do
        if params['payload']
          push = JSON.parse(params['payload'])
          user = push['repository']['owner']['name'] rescue nil
          puts "user #{user} user allowed: #{ALLOWED_USERS.include?(user)}"
          puts "trust ip: #{TRUSTED_IPS.include?(request.ip)} ip: #{request.ip}"
          account = Account.new(user)
          if ALLOWED_USERS.include?(user) && TRUSTED_IPS.include?(request.ip) && account.git_hook_enabled?(push)
            update_project_and_defer_run(push, user)
          else
            "not allowed"
          end
        else
          handle_remote_deferred_project_command(params)
        end
      end

      private

      def report_exception(e)
        $stderr.puts "Error: #{e.class}: #{e.message}"
        $stderr.puts "\t#{e.backtrace.join("\n\t")}"
        
        # Let exception middleware catch this
        raise e
      end

      def hash_to_querystring(hash)
        hash.keys.inject('') do |query_string, key|
          query_string << '&' unless key == hash.keys.first
          query_string << "#{URI.encode(key.to_s)}=#{URI.encode(hash[key])}"
        end
      end


      def handle_remote_deferred_project_command(params)
        payload_signature = params['signature']
        project = params['project']
        commit  = params['commit']
        command = params['command']

        if payload_signature == DEFERRED_SERVER_TOKEN

          if ENV['RACK_ENV']!='development' && find_server.state=="stopped"
            server = start_server
            {:server => {:state => 'starting'}}.to_json
            return
          elsif ENV['RACK_ENV']=='development' && false
            server = "fake"
            server_ip = '127.0.0.1:3001'
          else
            #hard coded to the shared public 'scripts' server
            server = start_server('instance-id' => 'i-b411c7c4')
            server_ip = server.public_ip_address
          end

          results_future = "project_results/results_for_#{project}_#{commit}_#{command}"

          push = {
            :results_location => results_future,
            :project => project,
            :commit => commit,
            :command => command
          }

          puts "server_ip #{server_ip}"
          puts "posting #{push.inspect}"

          response = post_to_server(:payload, push, {:server => server, :server_ip => server_ip})
          puts "response from server_responder: ********************"
          puts response

          {:results_location => "results/#{results_future}"}.to_json

        else
          puts "error signature was passed #{payload_signature} expecting #{code_signature(project)}"
          'invalid signed code'
        end
      end

      ######
      #
      # Thoughts forming around this but basically
      # * if you try to run a command against a project
      # * we could either support commands like 
      #   * rake task with args
      #   * irb and script to execute
      #   * boot app and send web request
      #
      # I feel like the web request will be the most verisitle
      # for now process would look like:
      #   * boot app to random port
      #   * hit with web request
      #   * store request results
      #   * show down app that was started
      ######
      def deferred_project_command
        payload_signature = params['signature']
        project = params['project']
        request = params['project_request']

        if payload_signature == code_signature(project)

          server = DeferredServer::Account.user_from_project(project).server_for_project(project)

          if ENV['RACK_ENV']!='development' && server.state=="stopped"
            server.start
            {:server => {:state => 'starting'}}.to_json
            return
          elsif ENV['RACK_ENV']=='development' && false
            server = "fake"
            server_ip = '127.0.0.1:3001'
          else
            server.start
            server_ip = server.public_ip_address
          end

          results_future = "project_results/results_for_#{project}_#{Time.now.utc.to_i}"

          push = {
            :results_location => results_future,
            :project => project,
            :project_request => request
          }

          puts "server_ip #{server_ip}"
          puts "posting #{push.inspect}"

          response = post_to_server(:payload, push, {:server => server, :server_ip => server_ip})
          puts "response from server_responder: ********************"
          puts response

          {:results_location => "results/#{results_future}"}.to_json

        else
          puts "error signature was passed #{payload_signature} expecting #{code_signature(project)}"
          'invalid signed code'
        end
      end

      def handle_deferred_code
        payload_signature = params['signature']
        script_payload = params['script_payload']
        if payload_signature == code_signature(script_payload)

          if ENV['RACK_ENV']!='development' && find_server.state=="stopped"
            server = start_server
            {:server => {:state => 'starting'}}.to_json
            return
          elsif ENV['RACK_ENV']=='development' && false
            server = "fake"
            server_ip = '127.0.0.1:3001'
          else
            server = start_server
            server_ip = server.public_ip_address
          end

          results_future = "script_results/results_for_#{payload_signature}_#{Time.now.utc.to_i}"

          push = {
            :results_location => results_future,
            :script_payload => script_payload
          }

          puts "server_ip #{server_ip}"

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
