class DeferredServerCli

  def initialize(args)
    @args = args
  end

  def run
    puts "running as local script"
    puts "options: #{@args.inspect}"
    option = @args.shift || ''
    if option.match(/debug/) || option.match(/-d/)
      debug
    elsif option.match(/start/) || option.match(/-s/)
      start(@args)
    elsif option.match(/stop/) || option.match(/-e/)
      stop
    elsif option.match(/terminate/) || option.match(/-t/)
      terminate
    else
      help
    end

    puts "done"
  end

  def help
    puts "deferred_server should be called as such `bundle exec ruby deferred-server.rb ARGS`"
    puts "currently supports ARGS:"
    puts "    start (-s)"
    puts "    stop (-e)"
    puts "    terminate (-t)"
    puts "    help (-h)"
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

  def stop
    puts "stop server"
    stop_server
  end

  def terminate
    puts "terminate server"
    server = find_server
    server.destroy
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
