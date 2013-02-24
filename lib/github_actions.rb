module GithubActions

  def update_project_and_defer_run(push, user)
    project_name = push['repository']['name']
    project_key = "#{user}/#{project_name}"
    project_last_updated = push['commits'].last['timestamp'] rescue Time.now

    projects = get_projects
    projects[project_key] = project_last_updated
    write_file('projects_json',projects.to_json)

    server = start_server
    server_ip = server.public_ip_address

    response = post_to_server(:payload, push, {:server => server, :server_ip => server_ip})
  end

end
