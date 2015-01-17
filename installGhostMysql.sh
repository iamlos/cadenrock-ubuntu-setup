#!/bin/bash


#
# Setup MySQL for ghost install
#
MYSQL_PASSWD=`tr -dc A-Za-z0-9_ < /dev/urandom | head -c 16 | xargs`
cat >/root/mysql-ghost.sql <<__EOF__
create database ghostdev;
create database ghost;
create user 'ghost'@'localhost' identified by '$MYSQL_PASSWD';
grant all privileges on ghost.* to 'ghost'@'localhost';
grant all privileges on ghostdev.* to 'ghost'@'localhost';
flush privileges;
quit
__EOF__
mysql -uroot -p$MYSQL_ROOT < /root/mysql-ghost.sql
chmod 400 /root/mysql-ghost.sql
echo "New ghost database password: $MYSQL_PASSWD"

