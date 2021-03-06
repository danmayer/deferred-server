module DeferredServer
  class Account

    def initialize(account_name)
      @account_name = account_name
    end

    def self.user_from_project(project_name)
      user_name = project_name.split('/')[0]
      DeferredServer::Account.new(user_name)
    end

    def init_user
      create_default_server
    end

    def servers
      @servers ||= get_servers(user)
    end

    def create_default_server
      servers = get_servers(user)
      if servers.length==0
        server_name = "default-server-#{user}"
        initial_server = create_new_server(ServerCommands::DEFAULT_AMI, {'server_name' => server_name})
        add_server(user, initial_server.id, initial_server, {'default' => true, 'name' => server_name})
      end
      initial_server
    end

    def default_server
      @default_server ||= find_server('instance-id' => get_servers(user).select{|key, val| val['default']==true }.keys.first) || create_default_server
    end

    def get_user_projects
      @get_user_projects ||= get_projects_by_user_with_settings(user)
    end

    def project_owner?(project_name)
      !!get_user_projects[project_name]
    end

    def project_data_from_name(project_name)
      get_user_projects[project_name]
    end

    def server_for_project(project)
      get_server_for_project(project, get_user_projects[project])
    end

    def get_server_for_project(project, project_data)
      project_server = if project_data.is_a?(String)
        default_server
      elsif project_data['server']
        find_server('instance-id' => project_data['server'])
      end
      project_server ||= default_server
    end

    def user
      @account_name
    end

    def get_hook_enabled_for_project?(project_data)
      if project_data.is_a?(String)
        true
      elsif project_data && project_data['hook_enabled']
        project_data['hook_enabled']=='true'
      else
        true
      end
    end

    def git_hook_enabled?(push)
      project_name = push['repository']['name'] rescue nil
      if project_name
        project_data = get_user_projects[project_name]
        get_hook_enabled_for_project?(project_data)
      else
        false
      end
    end
    
  end
end
