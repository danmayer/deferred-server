ENV['RACK_ENV'] ||= 'development'
require 'rubygems'
require 'bundler/setup'
require 'coverband'
require 'redis'

use Coverband::Middleware, :root => Dir.pwd,
          :reporter => Redis.new(:host => 'utils.picoappz.com', :port => 49182, :db => 3),
          :ignore => ['vendor'],
          :percentage => 60.0

$LOAD_PATH << File.dirname(__FILE__) + '/lib'
require File.expand_path(File.join(File.dirname(__FILE__), 'deferred_server'))

$stdout.sync = true

use Rack::Static, :urls => ["/css", "/img", "/javascript"], :root => "public"
run DeferredServer::App