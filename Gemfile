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

# Prevent installation on Heroku with
# heroku config:add BUNDLE_WITHOUT="development:test"
group :test do
   gem 'rack-test'
   gem 'mocha'
end

# why does this not really work for heroku which seems to still need my development gems?
# for now I comment these in when deploying to heroku
if RbConfig::CONFIG['host_os'] =~ /darwin/
  group :development do
     gem 'ruby-debug19', :require => 'ruby-debug'
  end
end