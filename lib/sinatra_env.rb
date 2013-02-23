module SinatraEnv

  def self.included(base)
    require 'sinatra/jsonp'
    require 'sinatra_auth_github'
    base.helpers Sinatra::Jsonp

    base.set :public_folder, File.dirname(__FILE__) + '/../public'
    base.set :root, File.dirname(__FILE__) + '/../'

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
    base.extend(ClassMethods)
  end

  module ClassMethods
  end

end
