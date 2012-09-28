require 'sinatra'
require './heroku-hookr'
$stdout.sync = true
run Sinatra::Application