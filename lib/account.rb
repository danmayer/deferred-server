module DeferredServer
  class Account
    
    def initialize(account_name)
      @account_name = account_name
    end

    def init_user
      servers = get_servers(user)
      if servers.length==0
        server_name = "default-server-#{user}"
        initial_server = create_new_server(ServerCommands::DEFAULT_AMI, {'server_name' => server_name})
        add_server(user, initial_server.id, {'default' => true, 'name' => server_name})
      end
    end

    def default_server
      @default_server ||= find_server('instance-id' => get_servers(user).select{|key, val| val['default']==true }.keys.first)
    end

    def user
      @account_name
    end
    
  end
end
