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
    elsif option.match(/restart/) || option.match(/-r/)
      restart
    elsif option.match(/start/) || option.match(/-s/)
      start(@args)
    elsif option.match(/stop/) || option.match(/-e/)
      stop
    elsif option.match(/terminate/) || option.match(/-t/)
      terminate
    elsif option.match(/write/) || option.match(/-w/)
      write_s3_file(@args)
    elsif option.match(/post/) || option.match(/-p/)
      post_to_deferred_server(@args)
    elsif option.match(/bootstrap/) || option.match(/-b/)
      bootstrap(@args)
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
    puts "    restart (-r)"
    puts "    terminate (-t)"
    puts "    write (-w) filename file_contents"
    puts "    post (-p) XXXTODOXXX"
    puts "    bootstrap (-b) level (default normal)"
    puts "    help (-h)"
    puts ""
    puts "example: `bundle exec ruby deferred_server.rb bootstrap full`"
  end

  def debug
    require 'ruby-debug'
    debugger
  end

  def start(args)
    puts "start server options #{args.inspect}"
    if args.include?('chef')
      options = {}
      if new_name = args.detect{|arg| arg.match(/new=(.*)/)}
        options['server_name'] = new_name.match(/new=(.*)/)[1]
        server = create_new_chef_server(options)
        puts "server initializing"
        sleep(40)
        options['instance-id'] = server.id
      end
      if instance_id = args.detect{|arg| arg.match(/id=(.*)/)}
        options['instance-id'] = instance_id.match(/id=(.*)/)[1]
      end
      server = start_chef_server(options)
    else
      server = start_server
    end
    puts "server: #{server.inspect}"
  end

  def stop
    puts "stop server"
    stop_server
  end

  def restart
    puts "restart server"
    restart_server
  end

  def terminate
    puts "terminate server"
    server = find_server
    server.destroy
  end

  def bootstrap(args)
    level = args[0] || 'default'
    options = {:level => level}

    server = find_server
    bootstrap_server(server, options)
  end

  def write_s3_file(args)
    filename  = args[0] || 'projects-test'
    file_data = args[1] || 'test-data'

    write_file(filename, file_data)
    file_results = get_file(filename)
    puts "file results: #{file_results}"
  end

  def post_to_deferred_server(args)
    push_data = eval(args[0]) || {:test => 'data'}
    server    = args[1] || find_server
    server_ip = args[2] || server.public_ip_address

    puts "posting to server at #{server_ip}, with #{push_data.inspect}"
    response = post_to_server(:payload, push_data, {:server => server, :server_ip => server_ip})
    puts response.inspect
  end

end
