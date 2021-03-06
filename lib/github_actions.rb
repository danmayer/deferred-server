module GithubActions

  def update_project_and_defer_run(push, user)
    project_name = push['repository']['name']
    project_key = "#{user}/#{project_name}"
    project_last_updated = push['commits'].last['timestamp'] rescue Time.now

    projects = get_projects
    projects[project_key] = project_last_updated
    write_file('projects_json',projects.to_json)

    # TODO getting a server and then start_server with a server.id which does a find server is dumb
    # we should find a server and if we want to use a given server perhaps a prepare_server and start are different
    # definitely can pass a full server object opposed to a stupid id and looking it up again
    account = DeferredServer::Account.new(user)
    server  = account.default_server
    server = start_server('instance-id' => server.id)

    server_ip = server.public_ip_address

    response = post_to_server(:payload, push, {:server => server, :server_ip => server_ip})
  end

end
