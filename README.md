Deferred-Server
===============

A app which takes commands from various sources and can spin up a server to handle the work and display the results.

__Current Features__  
  * accepts github post commit webhooks
  * spins up ec2 server, forwards github post commit hook

__To Run Locally__  
`bundle exec thin -R config.ru start`

__TODO__ 

  * support passing commands via curl / gem    
  * possibly support accounts / projects per accounts
  * auth tokens or secure way to limit which apps can post to deferred-server
    * possibly having to register the app with deferred-server prior to forwarding posts
  * deferred-server shouldn't just wake up a preconfigured ec2, but built the environment if it isn't configured
  * support spot instances for cheaper backend servers
  * rake tasks that can run rake commands remotely against project (probably better as a client gem)
  * support running deferred tasks on other branches than master
  * deferred / executable gists?
  * posts deferred / executable code
      * post {:script_body => "{:result => (7^7)}.to_json"} #returns deferred_result, url which will eventually host the JSON response
      * a jquery plugin that can send up rubyscript and poll until the response is completed
  * Store / be able to retrieve and display full post message received with the hook
    
__Bugs__
  
  * First request to EC2 seems to sometimes miss or timeout, after the EC2 has been warmed up further requests seem to work. 
    
__Completed__

  * support display results via S3 files
  * support list of projects
  * a way to have deferred-server shut down the ec2 instances? Or should the end server shutdown itself? (currently heroku cron puts any ec2 server inactive for 30 minutes back to sleep)
  * convert to rails this app will have some frontend work, and rails helpers are better than a collection of buggy replacements for rails helpers (instead added bootstrap, KISS)
    * add form to add user / projects (still needed)
    * show listing of projects (done)
    * show past results for projects / etc (done)
