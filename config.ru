ENV['RACK_ENV'] ||= 'development'
require "rubygems"
require "bundler/setup"

$LOAD_PATH << File.dirname(__FILE__) + '/lib'
require File.expand_path(File.join(File.dirname(__FILE__), 'deferred_server'))

$stdout.sync = true

use Rack::Static, :urls => ["/css", "/img", "/javascript"], :root => "public"
run DeferredServer::App