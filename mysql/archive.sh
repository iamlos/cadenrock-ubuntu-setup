#!/bin/bash
#
# 1) create our archive directory if necessary
# 2) archive the first of the month
# 3) delete the rest > 14 days old
#

daysold=14
backup="/data/backups/"
archive=$backup"archive/"

if [ ! -d "$archive" ]; then
  mkdir "$archive"
fi

for dir in `ls -1 $backup|grep -v \.sh`; do 
    if [ $dir = "archive" ]; then continue; fi
    DAY=`echo $dir|cut -d'-' -f3`; 
    if [ $DAY -eq 01 ]; then 
        /bin/mv $backup"$dir" $archive
    fi 
done

wayold=`find $backup -mtime +$daysold -print | grep -v $archive | grep -v \.sh`

for dir in $wayold; do
    echo "Purging $dir"
    /bin/rm -rf $dir
done
