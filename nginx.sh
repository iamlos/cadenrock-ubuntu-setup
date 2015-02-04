#!/bin/bash

CURL="/usr/bin/curl -s -O"

cd /etc/nginx/conf.d
$CURL $GITHUB/nginx/conf.d/cache.conf
$CURL $GITHUB/nginx/conf.d/gzip.conf
$CURL $GITHUB/nginx/conf.d/log.conf
$CURL $GITHUB/nginx/conf.d/limits.conf

cd /etc/nginx/sites-available
$CURL $GITHUB/nginx/sites-available/cadenrock
$CURL $GITHUB/nginx/sites-available/sagercreek

cd /etc/nginx/sites-enabled
rm default
ln -s ../sites-available/cadenrock
ln -s ../sites-available/sagercreek
