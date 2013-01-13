require 'sinatra'
require 'deferred_server'
require 'test/unit'
require 'rack/test'
require 'mocha/setup'

class MyAppTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_root
    app.any_instance.expects(:find_server).returns(fake_server)
    app.any_instance.expects(:get_projects_by_user).returns({})

    get '/'
    assert_match 'projects', last_response.body
  end

  private

  def fake_server
    mock(:state => 'running')
  end

end
