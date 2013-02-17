require 'test/unit'
require 'rack/test'
require 'mocha/setup'

class MyAppTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    DeferredServer::App
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

  def test_extract_hash
    json_data = JSON.parse(example_commit_hash)
    #puts json_data['push'].keys
    assert_equal "update readme",json_data['push']['commits'][0]['message']
  end

  def test_failure
    assert_equal false,true
  end

  private

  def fake_server
    mock(:state => 'running')
  end

  def example_commit_hash
    <<"JSONEND"
{"uri":"danmayer/deferred-server/9c9072e0b51e2d795b24bfcc014aa60c3cd5a81f","push":{"ref":"refs/heads/master","deleted":false,"head_commit":{"distinct":true,"added":[],"timestamp":"2013-02-17T13:03:23-08:00","removed":[],"author":{"email":"dan@email_fake.com","username":"danmayer","name":"Dan Mayer"},"message":"update readme","committer":{"email":"dan@email_fake.com","username":"danmayer","name":"Dan Mayer"},"url":"https://github.com/danmayer/deferred-server/commit/9c9072e0b51e2d795b24bfcc014aa60c3cd5a81f","modified":["README.md"],"id":"9c9072e0b51e2d795b24bfcc014aa60c3cd5a81f"},"created":false,"repository":{"open_issues":0,"size":636,"watchers":0,"description":"App the takes work and defers it until a server is really to handle it. Perhaps I should call this delegate-server which might match the goals a bit better.","fork":false,"has_issues":true,"owner":{"email":"danmayer@gmail.com","name":"danmayer"},"pushed_at":1361135008,"language":"JavaScript","url":"https://github.com/danmayer/deferred-server","has_wiki":true,"name":"deferred-server","created_at":1349545918,"stargazers":0,"id":6105230,"master_branch":"master","private":false,"has_downloads":true,"forks":0},"before":"a1d298c396e906b191f3a359a1f97edd6ad5d4b8","compare":"https://github.com/danmayer/deferred-server/compare/a1d298c396e9...9c9072e0b51e","pusher":{"email":"danmayer@gmail.com","name":"danmayer"},"after":"9c9072e0b51e2d795b24bfcc014aa60c3cd5a81f","commits":[{"distinct":true,"added":[],"timestamp":"2013-02-17T13:03:23-08:00","removed":[],"author":{"email":"dan@email_fake.com","username":"danmayer","name":"Dan Mayer"},"message":"update readme","committer":{"email":"dan@mayerdan.com","username":"danmayer","name":"Dan Mayer"},"url":"https://github.com/danmayer/deferred-server/commit/9c9072e0b51e2d795b24bfcc014aa60c3cd5a81f","modified":["README.md"],"id":"9c9072e0b51e2d795b24bfcc014aa60c3cd5a81f"}],"forced":false}}
JSONEND
  end

end
