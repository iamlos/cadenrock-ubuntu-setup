#!/bin/bash

mysqlUser=""
mysqlPass=""

backup="/data/backups/"
temp="$PWD/backup.tmp"


echo "Starting Backup..."
stamp=$(date -u  +%F)
backup=$backup$stamp
if [ ! -d "$backup" ]; then
  mkdir "$backup"
fi
echo "-----"
echo -ne "Preparing to backup MySQL tables... "
databases=( $(mysql -u"$mysqlUser" -p"$mysqlPass" --skip-column-names --batch -e "show databases;" 2>"$temp") );
echo "found ${#databases[@]} databases.";
for i in ${databases[@]}; do
  if [ $i != "information_schema" ] && [ $i != "phpmyadmin" ]; then
    echo -ne "Optimizing and backing up database $i ... "
    #nice mysql -u"$mysqlUser" -p"$mysqlPass" -D "$i" --skip-column-names --batch -e "optimize table $i" 2>"$temp" >/dev/null
    #mysqldump -u"$mysqlUser" -p"$mysqlPass" --master-data --opt $i | bzip2 -c > "$backup/db_$i.sql.bz2"
    mysqldump -u"$mysqlUser" -p"$mysqlPass" --opt $i | bzip2 -c > "$backup/db_$i.sql.bz2"
    echo "Done."
  fi
done
if [ ! -s $temp ]; then
  rm -f "$temp"
fi
echo "-----"
echo "Backup Complete!"
exit 0
