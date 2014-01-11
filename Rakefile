require 'rubygems'
require "bundler/setup"

$LOAD_PATH << File.dirname(__FILE__) + '/lib'

task :default => :test

task :environment do
  require File.expand_path(File.join(File.dirname(__FILE__), 'deferred_server'))
end

desc "run tests"
task :test do
  require File.expand_path(File.join(File.dirname(__FILE__), 'deferred_server'))
  # just run tests, nothing fancy
  Dir["test/**/*.rb"].sort.each { |test|  load test }
end

MINUTES_SINCE_LAST_JOB = 15
desc "Shutdown server which isn't doing work"
task :shutdown_inactive_server => :environment do
  shutdown_inactive_servers
end

require 'json'
require 'coverband'
require 'redis'
`mkdir ./tmp` unless File.exists?('./tmp')
unless File.exists?('./tmp/coverband_baseline.json')
  `touch ./tmp/coverband_baseline.json` 
  `echo "[]" > ./tmp/coverband_baseline.json`
end
Coverband.configure do |config|
  config.redis             = Redis.new(:host => 'utils.picoappz.com', :port => 49182, :db => 3)
  config.coverage_baseline = JSON.parse(File.read('./tmp/coverband_baseline.json'))
  config.root_paths        = ['/app/']
  config.ignore            = ['vendor']
end

desc "report unused lines"
task :coverband => :environment do
  Coverband::Reporter.report()
end

desc "get coverage baseline"
task :coverband_baseline do
  Coverband::Reporter.baseline {
    require File.expand_path(File.join(File.dirname(__FILE__), 'deferred_server'))
  }
end
