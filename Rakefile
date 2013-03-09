require 'rubygems'
require "bundler/setup"

$LOAD_PATH << File.dirname(__FILE__) + '/lib'
require File.expand_path(File.join(File.dirname(__FILE__), 'deferred_server'))
require 'rake'

task :default => :test

desc "run tests"
task :test do
  # just run tests, nothing fancy
  Dir["test/**/*.rb"].sort.each { |test|  load test }
end

MINUTES_SINCE_LAST_JOB = 15
desc "Shutdown server which isn't doing work"
task :shutdown_inactive_server do
  shutdown_inactive_servers
end
