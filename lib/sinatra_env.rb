module SinatraEnv

  def self.included(base)
    require 'sinatra/jsonp'
    require 'sinatra_auth_github'
    require 'account_actions'

    base.helpers Sinatra::Jsonp

    base.set :public_folder, File.dirname(__FILE__) + '/../public'
    base.set :root, File.dirname(__FILE__) + '/../'
    base.enable :logging

    base.use Rack::Session::Cookie, :key => 'rack.session',
    :path => '/',
    :expire_after => 2592000,
    :secret => "#{API_KEY}cookie",
    :old_secret => "#{API_KEY}_old_cookie"

    base.set :github_options, {
      :scopes    => "user",
      :secret    => ENV['DS_GH_Client_Secret'],
      :client_id => ENV['DS_GH_Client_ID'],
    }

    base.register Sinatra::Auth::Github

    base.configure :development do
      require "sinatra/reloader"
      base.register Sinatra::Reloader
      also_reload 'app/**/*.rb'
      also_reload 'lib/**/*.rb'
      also_reload 'conf/**/*.rb'
      set :raise_errors, true
      require "better_errors"
      use BetterErrors::Middleware
      BetterErrors.application_root = File.dirname(__FILE__)
    end

    base.configure :production do
      require 'newrelic_rpm'
    end

    base.extend(ClassMethods)
  end

  module ClassMethods
  end

end
