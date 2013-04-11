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

  * `bundle exec rackup -p 3000` # The web app
  * `bundle exec ruby deferred-server.rb` # A CLI to start, stop, and boot strap servers

__Example Usage__

  One example of this being used as a real feature is at [http://resume.mayerdan.com](http://resume.mayerdan.com), which uses deferred-server to generate a PDF on demand. The front end for this app is on heroku which can't run the `pdfkit` gem, so using deferred-server we boot up a machine and generate the PDF and redirect the user to the file on S3. To see the code example view the source on the resume link.

__In Progress__



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
  * Servers need to be associated to users / projects based on instance ID, accounts / project create servers based on AMI IDs
  * improve logging / exception tracking
  * a way to setup required environment like DB, memcache, redis, etc (follow travis CIs lead?)
    * might be specifying Chef scripts, or a project boot strap file
    * specify boot strap followed by chef cookbook repo in .deferred_server file?
    * move .deferred_server file to a json hash of various options
  * Each server gets its own S3 buckets
  * System know what types of scripts are being used (as in run counts incremented liked below)
  * Call Redis and increment a counter each time a script or server is called or used. Need a way to track usage
  * Create a unique S3 / EC2 key-pair for each server, possibly allow users to actually see / connect to the EC2 boxes
  * Need a user account / profile, somewhere to start storing preferences and possibly key pairs, etc
  * all file changes happen through deferred server

__Feature Ideas__

  * deferred / executable gists?
  * support running deferred tasks on other branches than master
  * Images for deferred_server on github, like travis / code-climate show status, link to assets
  * Deferred-URL, runs like deferred-script except opposed to signing a payload and pushing it, you can request a URL that includes the signature and it runs and returns the script. Need to think about how to return, either files, redirects, html, or json results
  * Possibly no app, but just a way to deferred-server boot a Redis or graphite box, which was configured via chef. This only opens ports on the box you need. 
      * Another example is open street map tile server http://tiledrawer.com/ python-mapnik2 is required script is out of date / broken. Work through and fix these steps http://tiledrawer.com/scripts/script-LBFwku.sh.txt 
  * I think all the projects and what a person does with a server should be a entirely separate service… Perhaps there is one API but it is a different API / endpoint and data. This project has gotten far to big. First split off the library deferred server and the CLI, then split off all the project specific code

__Bugs__

  * First request to EC2 seems to sometimes miss or timeout, after the EC2 has been warmed up further requests seem to work.
  * EC2 bootstrap process can't run fast enough in a Heroku web request, perhaps move to upload file then execute / poll
    * bootstrap seems to stall inside of local thin execution, investigate
  * Boot up doesn't always seem to work then requires some manual debugging, seems to have the ec2 restart required as it stops responding to requests…
  * First boot never responds to HTTP traffic anymore, something seems to screw up the connection after a timeout or two a ec2 restart seems to fix that issue. (need to start adding server progress messages to script / user, and then fix broken connections)
  * Code signing that results in a signature with a '/' in it causes issues with S3 files
  * CI builds frequently miss the first push as the server isn't awake and misses the first push from the GH post commit hook. We need somewhere to store / retry them until push hits the woken up server successfully
  


