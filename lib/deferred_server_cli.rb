class DeferredServerCli

  def initialize(args)
    @args = args
  end

  def run
    puts "running as local script"
    puts "options: #{@args.inspect}"
    option = @args.shift
    if option.match(/debug/) || option.match(/-d/)
      debug
    elsif option.match(/start/) || option.match(/-s/)
      start(@args)
    end

    puts "done"
  end

  def debug
    require 'ruby-debug'
    debugger
  end

  def start(args)
    puts "start server options #{args.inspect}"
    server = start_server
    puts "server: #{server.inspect}"
  end

    #write_file('projects-test',"test-data")
    #projects = get_file('projects-test')
    #puts projects

    #

    # server_ip = server.public_ip_address
    # #server_ip = "127.0.0.1:3000"

    # push = {:test => 'fake'}

    # puts "server is at #{server_ip}"
    # response = post_to_server(:payload, push, {:server => server, :server_ip => server_ip})
    # puts response.inspect
    # #stop_server

end
