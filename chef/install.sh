#!/bin/bash

# This runs as root on the server

chef_binary=/var/lib/gems/1.9.1/gems/chef-11.4.0/bin/chef-solo

# Are we on a vanilla system?
if ! test -f "$chef_binary"; then
    export DEBIAN_FRONTEND=noninteractive
    # Upgrade headlessly (this is only safe-ish on vanilla systems)
    aptitude update &&
    apt-get -o Dpkg::Options::="--force-confnew" \
        --force-yes -fuy dist-upgrade &&
    # Install Ruby and Chef
    aptitude install -y ruby1.9.1 ruby1.9.1-dev make &&
    #sudo gem1.9.1 install --no-rdoc --no-ri  net-ssh --version 2.6.5 &&
    #sudo gem1.9.1 install --no-rdoc --no-ri  net-ssh --version 2.1.4 &&
    #--version 0.10.0
    sudo gem1.9.1 install --no-rdoc --no-ri chef 
fi &&

"$chef_binary" -c solo.rb -j solo.json