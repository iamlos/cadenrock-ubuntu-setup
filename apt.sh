#!/bin/bash

apt-get update
apt-get -y install php5-mcrypt fail2ban libxml-treepp-perl \
    libmath-round-perl libexcel-writer-xlsx-perl cpanminus \
    libcrypt-ssleay-perl libjson-perl liblwp-protocol-https-perl

php5enmod mcrypt
#
# Install a few non packaged items. Use cpanm for low memory systems
#
cpanm WWW::Twilio::API

