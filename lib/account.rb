module DeferredServer
  class Account
    
    def initialize(account_name)
      @account_name = account_name
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
      get_projects_by_user_with_settings(user)
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
    
  end
end
