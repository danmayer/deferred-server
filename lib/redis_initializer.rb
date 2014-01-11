# encoding: utf-8
require 'date'

REDIS = if ENV['RACK_ENV']=='production'
          Redis.new(:host => ENV["REDIS_HOST"], :port => ENV["REDIS_PORT"], :password => ENV["REDIS_PASSWORD"])
        elsif ENV['RACK_ENV']=='test'
          {}
        else
          Redis.new(:host => '127.0.0.1', :port => 6379)
        end