module DeferredServer
  class App < Sinatra::Base

    get '/account' do
      authenticate!
      @account = Account.new(github_user.login)
      @account.init_user
      default_server = @account.default_server
      @server_state = default_server.state
      @projects = @account.get_projects
      erb :account
    end

    get '/unauthenticated' do
      @server_state = find_server.state
      @projects = {}
      @error = "Error logging in try again"
      erb :index
    end

    get '/servers' do
      #TODO match up servers with active status, by getting servers from EC2 and selecting users servers
      authenticate!
      @account = Account.new(github_user.login)
      @server = find_server
      @projects = get_projects_by_user(github_user.login)
      erb :servers
    end

    #TODO um why you rebuilding rest, servers is clearly a rest endpoint nested under account
    post '/server_action' do
      authenticate!
      @account = Account.new(github_user.login)
      puts params.inspect

      server_id = params['id']
      server    = find_server('instance-id' => server_id)
      unless server
        flash[:notice] = "unknown server!"
        redirect "/servers"
      end

      action    = params['submit']
      case action
      when "Start"
        start_server('instance-id' => server_id)
        flash[:notice] = "Server started"
      when "Stop"
        stop_server('instance-id' => server_id)
        flash[:notice] = "Server Stoped"
      when "Destroy"
        remove_server(github_user.login, server_id)
        server.destroy
        flash[:notice] = "Server Destroy, no turning back, hope you meant it!"
      else
        flash[:notice] = "unknown action, back to you weatherman!"
      end

      redirect "/servers"
    end

    post '/add_server' do
      authenticate!
      @account    = Account.new(github_user.login)
      server_name = params['server_name']
      ami_type    = params['server_base_ami']
      ami_type    = ServerCommands::DEFAULT_AMI if ami_type==''
      default     = params['make_default'] && params['make_default']=='true'
      server      = create_new_server(ami_type, {'server_name' => server_name})
      add_server(github_user.login, server.id, server, {'default' => default, 'name' => server_name})
      
      flash[:notice] = "Added server '#{server_name}' and the ID is #{server.id}!"
      redirect "/servers"
    end

    after '/signed_script' do
      session['user_script'] = nil
      session['signature'] = nil
    end

    get '/signed_script' do
      authenticate!
      @server_state = find_server.state
      user          = github_user.login
      @scripts      = get_scripts(user)
      @signature    = session['signature'] || nil
      @user_script  = session['user_script'] || "puts 'enter ruby code here'"
      erb :signed_script
    end
    
    post '/sign_script' do
      authenticate!
      code       = params['user_script']
      signature  = code_signature(code)
      user       = github_user.login
      script_key = "#{user}/scripts/#{signature}"

      add_or_update_signed_script(user, script_key, code)
      session['user_script'] = code
      session['signature'] = signature
      redirect "/signed_script"
    end

    get '/logout' do
      logout!
      redirect "/"
    end

  end
end
