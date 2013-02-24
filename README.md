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
  * runs default or user specified, script against codebase once running
  * run deferred signed scripts, log in and sign a script, which can be embedded anywhere

__To Run Locally__

  * `bundle exec thin -R config.ru start` # The web app
  * `bundle exec ruby deferred-server.rb` # A CLI to start, stop, and boot strap servers

__Example Usage__

  One example of this being used as a real feature is at [http://resume.mayerdan.com](http://resume.mayerdan.com), which uses deferred-server to generate a PDF on demand. The front end for this app is on heroku which can't run the `pdfkit` gem, so using deferred-server we boot up a machine and generate the PDF and redirect the user to the file on S3. To see the code example view the source on the resume link.

__Todo__

  * Add tagging to created servers to associate them to users, or shared servers, different keys per server?
  * Needs better response cycle for first attempts, when waking the server.
     * perhaps button goes 'waiting…'
     * results box appears, but says 'no server available to handle request waking server'
     * server status: *
     * retrying original request
     * code sent awaiting results (not_complete)
     * results displayed and button flips back to 'run'
  * auth tokens or secure way to limit which apps can post to deferred-server
    * possibly having to register the app with deferred-server prior to forwarding posts
  * support spot instances for cheaper backend servers
  * Start to treat lib / code a bit more real and refactor into proper objects opposed to just including modules
  * in the boot process each step needs to be conditional as in it only runs if the result of the command hasn't already been completed
  * Servers need to be associated to users / projects based on instance ID, accounts / project create servers based on AMI IDs
  * improve logging / exception tracking
  * a way to setup required environment like DB, memcache, redis, etc (follow travis CIs lead?)
    * might be specifying Chef scripts, or a project boot strap file
    * specify boot strap followed by chef cookbook repo in .deferred_server file?
    * move .deferred_server file to a json hash of various options

__Feature Ideas__

  * deferred / executable gists?
    * improve JS signing script, could be passed a script file and could output the entire script tag output with the signature embedded
  * support running deferred tasks on other branches than master
  * servers per accounts, single default user server, then servers for specific projects
  * Images for deferred_server on github, like travis / code-climate show status, link to assets

__Bugs__

  * First request to EC2 seems to sometimes miss or timeout, after the EC2 has been warmed up further requests seem to work.
  * EC2 bootstrap process can't run fast enough in a Heroku web request, perhaps move to upload file then execute / poll
    * bootstrap seems to stall inside of local thin execution, investigate
  * Boot up doesn't always seem to work then requires some manual debugging, seems to have the ec2 restart required as it stops responding to requests…
  * First boot never responds to HTTP traffic anymore, something seems to screw up the connection after a timeout or two a ec2 restart seems to fix that issue. (need to start adding server progress messages to script / user, and then fix broken connections)
  * Code signing that results in a signature with a '/' in it causes issues with S3 files


