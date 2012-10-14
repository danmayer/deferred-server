require 'rake'
require 'json'
require 'fog'
require 'rest-client'
require './lib/server-commands'
require './lib/server-files'
include ServerFiles
include ServerCommands

desc "Shutdown server which isn't doing work"
task :shutdown_inactive_server do
  server = find_server
  server_ip = server.public_ip_address
  response = RestClient.get "http://#{server_ip}/last_job", :content_type => :json, :accept => :json
  time_data = JSON.parse(response)
  last_job_time = Time.parse(time_data['last_time']) rescue Time.now
  minutes_ago = 60 * 3
  if last_job_time < Time.at(Time.now.to_i-minutes_ago)
    puts "shutdown"
    stop_server
  else
    # puts "still active"
  end
end