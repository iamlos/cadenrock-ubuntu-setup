#!/bin/bash

SSHPORT=$1
MYSQL_ROOT=$2

GITHUB="https://raw.githubusercontent.com/cadenrock/cadenrock-ubuntu-setup/master"
WGET="/usr/bin/wget"

if [ "x$SSHPORT" -e "x" -o "x$MYSQL_ROOT" -e "x" ]; then
    echo "$0 <SSH Port> <MySQL root password>"
    echo "Please enter an SSH Port and MySQL root password"
    exit 1;
fi

/usr/sbin/useradd -c "Steve Helms" -s /bin/bash -m shelms
/bin/mkdir /home/shelms/.ssh
cat > /home/shelms/.ssh/authorized_keys2 << _EOF_
ssh-dss AAAAB3NzaC1kc3MAAACBAOMP1x0f43G+YyBzlhyXnVUGKUJkIDpCFXCpFnFMKTZxh++zeIWvi3a6H8LNH1xrHyxnX13cweWwj5fWvZ/KFkVx/Dimqs22BC27ZUIE6dfACF9Y64Zart8VeNAVoDcwO2atdpl+urp2XXJunyIBchSROwhEawuQ5V3nyBpLWzi/AAAAFQDyYaazXATy6UCYQOYLaPT3jDrIpwAAAIAjwstwpugI0JAE63FKKPEles9bBeFLwYf/bmD3u0Jyj7s5v8JF6G/T0A0T9YdxqeYbqwZEnsxfn9bU6Za+8GbC9x8iO84BTKz+cFKkawZNkrbrEcimQ2h+3Qj9vyyk6AcXajinS4pp6gYpkAlop1HECQocwjD7Q73jZYwQKiRVGgAAAIEA1KiEl+z34XPJ0NSe3R5AbujZfvG9J/SehUMPeGA6NTXv3gDQQHvpG+MQvvfEBizWnQm5uMeFy8FYgTr+5Sn+xJ3bBGBpSSt4AKtUO0WMIM1PCNxzz+cKqsBDTsesSL667gQsPLmZxkWD4fNfp0NLQUbtBbPiEfJgG/LDEnGaBWo= nucleus
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCgSJ3tzRTIQ3nU1ELQ9yIBMgFtN3yKMFmbjIK7qK3RlzqhXj4ok3v1YzeH9nNHmcKDbpq78WVi0nvqh+aGEaKmZaWrBVxo/8n8AfiHe/Fd7Wpiut7hex0TQgBF8HekASUwrafT9Eq9xqJZT2lOiavll7A8oFmHsW7VZS98gqm6M4n8TWlYbwPZZDtvAaSAnBEYCJqq2um1xpsirHa1lRt+YBFURzJ7v+Sc5hPVg/rdQ8FI8e/zby3rV0s4eWSNvL2ehPAcokO2+PWQ/3Y+BvmorkJ643uZrSEyoXR9fS4E7b33X+55PVRfDI3o2OptFT8CfgNOaeUkKFp3Epe/kuFH droplet
_EOF_
/bin/chown -R shelms.shelms /home/shelms
/usr/sbin/adduser shelms sudo


cd /root

# Install various apps necessary but not installed by default
$WGET $GITHUB/apt.sh
bash ./apt.sh

$WGET $GITHUB/secure.sh
bash ./secure.sh $SSHPORT

if [ ! -f /usr/local/bin/ghoststart.sh ]; then
    /bin/bash /root/installGhost.sh
    $WGET $GITHUB/installGhost.sh
    bash ./installGhost.sh


    $WGET $GITHUB/installGhostMysql.sh
    bash ./installGhostMysql.sh $MYSQL_ROOT
fi

