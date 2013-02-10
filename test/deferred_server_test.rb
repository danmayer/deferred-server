require 'sinatra'
require File.expand_path("../../deferred_server", __FILE__)
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

  def test_deferred_code_get
    app.any_instance.expects(:handle_deferred_code).returns({})

    get '/deferred_code'
    assert_match '{}', last_response.body
  end

  def test_deferred_code_post
    app.any_instance.expects(:handle_deferred_code).returns({})

    post '/deferred_code'
    assert_match '', last_response.body
  end

  def test_commits_get
    app.any_instance.expects(:get_commits).returns({'SHA' => 'fake'})
    app.any_instance.expects(:get_file).returns('results for commit')

    get '/project_name/commits/SHA'
    assert_match 'results for commit', last_response.body
  end

  def test_results_get__results
    app.any_instance.expects(:get_file).returns('results for run')

    get '/results/SHA_time'
    assert_match 'results for run', last_response.body
  end

  def test_results_get__not_complete
    app.any_instance.expects(:get_file).returns('')

    get '/results/SHA_time'
    assert_match 'not_complete', last_response.body
  end

  def test_get_project
    app.any_instance.expects(:get_commits).returns({})

    get '/fake_project'
    assert_match 'commits:', last_response.body
  end

  private

  def fake_server
    mock(:state => 'running')
  end

end
