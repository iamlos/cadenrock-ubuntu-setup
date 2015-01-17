#!/bin/bash

WGET="/usr/bin/wget"

cd /etc/nginx/conf.d
$WGET $GITHUB/nginx/conf.d/cache.conf
$WGET $GITHUB/nginx/conf.d/gzip.conf
$WGET $GITHUB/nginx/conf.d/log.conf

cd /etc/nginx/sites-available
$WGET $GITHUB/nginx/sites-available/cadenrock
$WGET $GITHUB/nginx/sites-available/sagercreek

cd /etc/nginx/sites-enabled
rm default
ln -s ../sites-available/cadenrock
ln -s ../sites-available/sagercreek
