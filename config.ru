require 'sinatra'
require './deferred_server.rb'
$stdout.sync = true
run Sinatra::Application