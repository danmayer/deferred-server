class DeferredServerCli

  def initialize(*args)
    @args = args
  end

  def run
    puts "running as local script"
    require 'ruby-debug'
    debugger
    #write_file('projects-test',"test-data")
    #projects = get_file('projects-test')
    #puts projects

    # server = start_server

    # server_ip = server.public_ip_address
    # #server_ip = "127.0.0.1:3000"

    # push = {:test => 'fake'}

    # puts "server is at #{server_ip}"
    # response = post_to_server(:payload, push, {:server => server, :server_ip => server_ip})
    # puts response.inspect
    # #stop_server

    puts "done"
  end

end
