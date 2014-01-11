source 'https://rubygems.org'
gem 'rake'
gem 'sinatra'
gem 'fog'
gem 'json'
gem 'rest-client'
gem 'sinatra-jsonp'
gem 'main'
gem 'sinatra_auth_github'
gem 'rest-client'
gem 'rack-flash3'
gem 'sinatra-contrib'
gem 'airbrake'
gem 'coverband'

group :production do
  gem 'unicorn'
  gem 'newrelic_rpm'
end

# Prevent installation on Heroku with
# heroku config:add BUNDLE_WITHOUT="development:test"
group :test do
   gem 'rack-test'
   gem 'mocha'
end

group :development do
  # gem 'ruby-debug19', :require => 'ruby-debug'
  #gem 'pry'
  #gem 'foreman'
  gem "better_errors"
  gem "binding_of_caller"
end
