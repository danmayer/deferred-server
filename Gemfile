source :rubygems
gem 'rake'
gem 'sinatra'
gem 'fog'
gem 'json'
gem "rest-client"
gem "sinatra-jsonp"

# Prevent installation on Heroku with
# heroku config:add BUNDLE_WITHOUT="development:test"
#group :development, :test do
#  gem 'ruby-debug19', :require => 'ruby-debug'
#   gem 'thin'
#end

if RbConfig::CONFIG['host_os'] =~ /darwin/
  group :development do
    #gem 'thin'
  end
end