module DeferredServer
  class App < Sinatra::Base

    get '/account' do
      authenticate!
      @account = Account.new(github_user.login)
      @account.init_user
      default_server = @account.default_server
      @server_state = default_server.state
      @projects = get_projects_by_user(github_user.login)
      erb :account
    end

    get '/unauthenticated' do
      @server_state = find_server.state
      @projects = {}
      @error = "Error logging in try again"
      erb :index
    end

    get '/servers' do
      authenticate!
      @account = Account.new(github_user.login)
      @server = find_server
      @projects = get_projects_by_user(github_user.login)
      erb :servers
    end

    post '/add_server' do
      authenticate!
      @account = Account.new(github_user.login)
      server_name = params['server_name']
      ami_type    = params['server_base_ami'] || ServerCommands::DEFAULT_AMI
      server   = create_new_server(ami_type, {'server_name' => server_name})
      add_server(github_user.login, server.id, server, {'default' => true, 'name' => server_name})
      "params #{params.inspect}"
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
