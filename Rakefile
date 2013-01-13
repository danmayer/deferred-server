require 'rake'
require 'json'
require 'fog'
require 'rest-client'
require './lib/server-commands'
require './lib/server-files'
include ServerFiles
include ServerCommands

task :default => :test

desc "run tests"
task :test do
  # just run tests, nothing fancy
  Dir["test/**/*.rb"].sort.each { |test|  load test }
end

MINUTES_SINCE_LAST_JOB = 15
desc "Shutdown server which isn't doing work"
task :shutdown_inactive_server do
  server = find_server
  server_ip = server.public_ip_address
  last_job_time = Time.now
  begin
    response = RestClient.get "http://#{server_ip}/last_job", :content_type => :json, :accept => :json
    time_data = JSON.parse(response)
    last_job_time = Time.parse(time_data['last_time']) rescue Time.now
  rescue
    #server likely not running
  end
  minutes_ago = 60 * MINUTES_SINCE_LAST_JOB
  if last_job_time < Time.at(Time.now.to_i-minutes_ago)
    puts "shutdown"
    stop_server
  else
    # puts "still active"
  end
end