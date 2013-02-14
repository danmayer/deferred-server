Deferred-Server
===

A app which takes commands from various sources and can spin up a server to handle the work and return the results.

trigger

example usages:

  * CI runs on commits
  * execute code from JS scripts
  * quickly start up and shutdown EC2 server
  * queue and run longer processing jobs on a disposable server

__Current Features__
  * accepts github post commit webhooks
  * spins up ec2 server, forwards github post commit hook
  * run deferred signed scripts

__To Run Locally__
  * `bundle exec thin -R config.ru start`
  * `bundle exec ruby deferred-server.rb` #run commands in script section or enter IRB
    

__TODO__

  * Add tagging to created servers to associate them to users, or shared servers
  * Needs better response cycle for first attempts, when waking the server.
     * perhaps button goes 'waiting…'
     * results box appears, but says 'no server available to handle request waking server'
     * server status: *
     * retrying original request
     * code sent awaiting results (not_complete)
     * results displayed and button flips back to 'run'
  * support passing commands via curl
  * possibly support accounts / projects per accounts
  * auth tokens or secure way to limit which apps can post to deferred-server
    * possibly having to register the app with deferred-server prior to forwarding posts
    * currently limited to a white list of GH IPs, users, and signed ruby scripts
  * support spot instances for cheaper backend servers
  * rake tasks that can run rake commands remotely against project (probably better as a client gem)
  * support running deferred tasks on other branches than master
  * deferred / executable gists?
    * improve JS signing script, could be passed a script file and could output the entire script tag output with the signature embedded
  * Start to treat lib / code a bit more real and refactor into proper objects opposed to just including modules
  * Build user auth system and user restricted script signing web-UI
  * use PDF generation view deferred server for the resume project the first real world usage example of deferred_server
  * in the boot process each step needs to be conditional as in it only runs if the result of the command hasn't already been completed
  * Servers need to be associated to users / projects based on instance ID, accounts / project create servers based on AMI IDs
  * improve logging / exception tracking
  * Integration for notifications / web-hooks
  
__Ideas__

__Bugs__

  * First request to EC2 seems to sometimes miss or timeout, after the EC2 has been warmed up further requests seem to work.
  * EC2 bootstrap process can't run fast enough in a Heroku web request, perhaps move to upload file then execute / poll
    * bootstrap seems to stall inside of local thin execution, investigate

    
