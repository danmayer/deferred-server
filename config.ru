require 'sinatra'
require './deferred-server.rb'
$stdout.sync = true
run Sinatra::Application