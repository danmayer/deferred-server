Deferred-Server
===

A app which takes commands from various sources and can spin up a server to handle the work and return the results.

__Current Features__
  * accepts github post commit webhooks
  * spins up ec2 server, forwards github post commit hook
  * run deferred signed scripts

__To Run Locally__
  * `bundle exec thin -R config.ru start`
  * `bundle exec ruby deferred-server.rb` #run commands in script section or enter IRB
    

__TODO__

  * Add tagging to created servers to associate them to users, or shared servers
  * Support multiple embedded code examples (two runners should run entirely independantly)
  * Needs better response cycle for first attempts, when waking the server.
     * perhaps button goes 'waiting…'
     * results box appears, but says 'no server available to handle request waking server'
     * server status: *
     * retrying original request
     * code sent awaiting results (not_complete)
     * results displayed and button flips back to 'run'
  * support passing commands via curl / gem
  * possibly support accounts / projects per accounts
  * auth tokens or secure way to limit which apps can post to deferred-server
    * possibly having to register the app with deferred-server prior to forwarding posts
    * currently limited to a white list of GH IPs, users, and signed ruby scripts
  * support spot instances for cheaper backend servers
  * rake tasks that can run rake commands remotely against project (probably better as a client gem)
  * support running deferred tasks on other branches than master
  * deferred / executable gists?
  * Store / be able to retrieve and display full post message received with the hook
  * sort commits based one time
  * improve JS signing script, could be passed a script file and could output the entire script tag output with the signature embedded
  * Start to treat lib / code a bit more real and refactor into proper objects opposed to just including modules
  * Build user auth system and user restricted script signing web-UI
  * use PDF generation view deferred server for the resume project the first real world usage example of deferred_server
  * in the boot process each step needs to be conditional as in it only runs if the result of the command hasn't already been completed
  * Servers need to be associated to users / projects based on instance ID, accounts / project create servers based on AMI IDs
  * improve logging / exception tracking
  
__In Progress__
  * deferred-server shouldn't just wake up a preconfigured ec2, but built the environment if it isn't configured

__Bugs__

  * First request to EC2 seems to sometimes miss or timeout, after the EC2 has been warmed up further requests seem to work.
  * EC2 bootstrap process can't run fast enough in a heroku web request, perhaps move to upload file then execute / poll
    * bootstrap seems to stall inside of local thin execution, investigate

__Completed__

  * support display results via S3 files
  * support list of projects
  * a way to have deferred-server shut down the ec2 instances? Or should the end server shutdown itself? (currently heroku cron puts any ec2 server inactive for 30 minutes back to sleep)
  * convert to rails this app will have some frontend work, and rails helpers are better than a collection of buggy replacements for rails helpers (instead added bootstrap, KISS)
    * add form to add user / projects (still needed)
    * show listing of projects (done)
    * show past results for projects / etc (done)
  * Bug doesn't clear the artifacts folder between runs. The code should auto create the artifacts directory
  * Move all the deferred JS to a JQuery plugin
  * Add some basic test coverage
  * posts deferred / executable code
    * post {:script_body => "{:result => (7^7)}.to_json"} #returns deferred_result, url which will eventually host the JSON response
    * a jquery plugin that can send up rubyscript and poll until the response is completed
  * currently expects results with some data, but if you write to artifacts and have no data it polls for ever. Write a results.json which includes exit status so even empty results will write something / be complete.
    
    
