module ServerFiles

  def connection
    @connection ||= Fog::Storage.new(
                                  :provider          => 'AWS',
                                  :aws_access_key_id => ENV['AMAZON_ACCESS_KEY_ID'],
                                  :aws_secret_access_key => ENV['AMAZON_SECRET_ACCESS_KEY'])
  end

  def get_file(filename)
    begin
      file = directory.files.get(filename)
      file.body
    rescue
      ''
    end
  end

  def get_projects
    projects_data = get_file('projects_json')
    @projects = JSON.parse(projects_data) rescue {}
  end

  def get_projects_by_user(user = nil)
    projects = get_projects
    projects_by_user = {}
    projects.each_pair do |proj, val|
      proj_user = proj.split('/').first
      if user.nil? || proj_user==user
        unless projects_by_user[proj_user]
          projects_by_user[proj_user] = {}
        end
        projects_by_user[proj_user][proj] = val
      end
    end
    projects_by_user
  end

  def get_servers(user)
    servers_data = get_file("#{user}/servers/servers_index")
    servers = JSON.parse(servers_data) rescue {}
  end

  def add_server(user, server_key, server, options = {})
    servers = get_servers(user)
    servers[server_key] = options.merge(:updated_at => Time.now, 'image_id' => server.image_id)
    write_file("#{user}/servers/servers_index", servers.to_json)
    servers
  end

  def get_scripts(user)
    scripts_data = get_file("#{user}/scripts/scripts_index")
    scripts = JSON.parse(scripts_data) rescue {}
  end

  def get_script(script_key)
    get_file(script_key)
  end

  def add_or_update_signed_script(user, script_key, code)
    scripts =  get_scripts(user)
    scripts[script_key] = Time.now
    write_file("#{user}/scripts/scripts_index", scripts.to_json)
    write_file(script_key, code)
  end

  def get_commits(project_key)
    commits_data = get_file(project_key)
    @commits = JSON.parse(commits_data) rescue {}
  end

  def write_commits(project_key, after_commit, commit_key, push)
    commits_data = get_file(project_key)
    @commits = JSON.parse(commits_data) rescue {}
    @commits[after_commit] = {:uri => commit_key, :push => push }
    write_file(project_key, @commits.to_json)
  end

  def write_file(filename, body)
    file = directory.files.new({
                                 :key    => filename,
                                 :body   => body,
                                 :public => true
                               })
    file.save
  end

  def extract_author_email(project_key, commit_key)
    commits = get_commits(project_key)
    commit_data = commits[commit_key]
    if commit_data.is_a?(Hash)
      json_data['push']['commits'][0]['author']['email']
    else
      'dan@mayerdan.com'
    end
  end

  def get_commit_key_and_data(project_key, commit)
    commits = get_commits(project_key)
    commit_key = commits[commit]
    commit_hash = nil
    if commit_key.is_a?(Hash)
      commit_hash = commit_key['push']
      commit_key = commit_key['uri']
    end
    [commit_key, commit_hash]
  end

  def get_run_results_data(commit_key)
    results_data = {}
    results_file_data = get_file(commit_key)
    begin
      results_data = JSON.parse(results_file_data)
    rescue
      #old format just straight results
      results_data['results'] = results_file_data
    end
    results_data
  end

  def directory
    directory = connection.directories.create(
                                              :key    => "deferred-server",
                                              :public => true
                                              )
  end

end
