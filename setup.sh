#!/bin/bash

apt-get install git
apt-get install dirmngr
apt-get install vim
apt-get install curl
apt-get install build-essential

# Install mongodb
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4
echo "deb http://repo.mongodb.org/apt/debian stretch/mongodb-org/4.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.0.list
apt-get update
apt-get install -y mongodb-org
service mongod start

# Install cpanm 
curl -L https://cpanmin.us | perl - --sudo App::cpanminus 

# Install Perl Modules 
cpanm Mojolicious
cpanm Mango
