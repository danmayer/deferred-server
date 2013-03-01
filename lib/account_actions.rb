module AccountActions

  get '/account' do
    authenticate!
    @server_state = find_server.state
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
    @server = find_server
    @projects = get_projects_by_user(github_user.login)
    erb :servers
  end

  after '/signed_script' do
    session['user_script'] = nil
    session['signature'] = nil
  end

  get '/signed_script' do
    authenticate!
    @server_state = find_server.state
    @projects = get_projects_by_user(github_user.login)
    @signature = session['signature'] || nil
    @user_script = session['user_script'] || "puts 'enter ruby code here'"
    erb :signed_script
  end
  
  post '/sign_script' do
    authenticate!
    code = params['user_script']
    signature = code_signature(code)
    session['user_script'] = code
    session['signature'] = signature
    redirect "/signed_script"
  end

  get '/logout' do
    logout!
    redirect "/"
  end

end
