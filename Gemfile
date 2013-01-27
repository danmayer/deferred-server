source :rubygems
gem 'rake'
gem 'sinatra'
gem 'fog'
gem 'json'
gem 'rest-client'
gem 'sinatra-jsonp'
gem 'main'

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
     #gem 'thin'
     #gem 'ruby-debug', :require => 'ruby-debug'
  end
end