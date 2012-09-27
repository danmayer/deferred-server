source :rubygems
gem 'rake'
gem 'sinatra'
gem 'fog'

# Prevent installation on Heroku with
# heroku config:add BUNDLE_WITHOUT="development:test"
group :development, :test do
#  gem 'ruby-debug19', :require => 'ruby-debug'
end

group :development do
  gem 'thin'
  gem 'pry'
end