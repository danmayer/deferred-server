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
  * support display results via S3 files  
  * support list of projects
  * possibly support accounts / projects per accounts
  * auth tokens or secure way to limit which apps can post to deferred-server
    * possibly having to register the app with deferred-server prior to forwarding posts
  * a way to have deferred-server shut down the ec2 instances? Or should the end server shutdown itself?
  * deferred-server shouldn't just wake up a preconfigured ec2, but built the environment if it isn't configured
  * support spot instances for cheaper backend servers
  * rake tasks that can run rake commands remotely against project
  * support running deferred tasks on other branches than master
  * deferred / executable gists?
  * posts deferred / executable code
      * post {:script_body => "{:result => (7^7)}.to_json"} #returns deferred_result, url which will eventually host the JSON response
      * a jquery plugin that can send up rubyscript and poll until the response is completed
  * convert to rails this app will have some frontend work, and rails helpers are better than a collection of buggy replacements for rails helpers
    * add form to add user / projects
    * show listing of projects
    * show past results for projects / etc    