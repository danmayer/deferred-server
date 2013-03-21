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

    def get_projects
      get_projects_by_user(user)
      
      #{"danmayer"=>{"danmayer/server_responder"=>"2013-03-19T18:06:32-07:00", "danmayer/churn"=>"2013-01-29T19:30:31-08:00", "danmayer/deferred-server"=>"2013-03-16T12:35:39-07:00", "danmayer/Resume"=>"2013-02-23T09:59:26-08:00", "danmayer/sinatra_template"=>"2013-03-10T15:12:54-07:00"}}

    end

    def user
      @account_name
    end
    
  end
end
