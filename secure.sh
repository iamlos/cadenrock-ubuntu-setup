#!/bin/bash

CURL="/usr/bin/curl -s -O"

SSHPORT=$1
if [ "x$SSHPORT" = "x" ]; then
    SSHPORT=2222
fi


debInstalled()
{
    pkg=$1
    is_installed=0
    test_installed=( `apt-cache policy $pkg | grep "Installed:" ` )
    [ ! "${test_installed[1]}" == "(none)" ] && is_installed=1
}


# Secure shared memory
grep -v shm /etc/fstab >/tmp/fstab.$$
mv /tmp/fstab.$$ /etc/fstab
echo "tmpfs     /dev/shm     tmpfs     defaults,noexec,nosuid     0     0">>/etc/fstab

# Secure su binary
sudo groupadd admin
sudo usermod -a -G admin shelms
sudo dpkg-statoverride --update --add root admin 4750 /bin/su

# Secure SSH
sed -i -e "s/Port 22/Port $SSHPORT/" \
    -e "s/PermitRootLogin yes/PermitRootLogin without-password/" \
    -e "s/#PasswordAuthentication yes/PasswordAuthentication no/" \
    -e "s/#Banner \/etc\/issue.net/Banner \/etc\/issue.ssh/" \
    /etc/ssh/sshd_config

cat > /etc/issue.ssh << _EOF_
***************************************************************************
                            NOTICE TO USERS


This computer system is for authorized use only. Users (authorized or
unauthorized) have no explicit or implicit expectation of privacy.

Any or all uses of this system and all files on this system may be
intercepted, monitored, recorded, copied, audited, inspected, and disclosed 
to authorized site and law enforcement personnel.

By using this system, the user consents to such interception, monitoring,
recording, copying, auditing, inspection, and disclosure at the discretion 
of authorized site.

Unauthorized or improper use of this system may result in administrative
disciplinary action and civil and criminal penalties. By continuing to use
this system you indicate your awareness of and consent to these terms and
conditions of use. LOG OFF IMMEDIATELY if you do not agree to the conditions
stated in this warning.

***************************************************************************
_EOF_

# Restart SSH
/usr/sbin/service ssh restart

# Prevent unauthorized use of various hosts files
for FILE in /root/.rhosts /root/.shosts /etc/hosts.equiv /etc/shosts.equiv; do
    rm -f $FILE
    ln -s /dev/null $FILE
done


# Secure sysctl. Simply append so we don't miss any new OS settings
cat >> /etc/sysctl.conf << __EOF__
#
# CUSTOM CADENROCK HARDENING
#
# Uncomment the next two lines to enable Spoof protection (reverse-path filter)
# Turn on Source Address Verification in all interfaces to
# prevent some spoofing attacks
net.ipv4.conf.default.rp_filter=1
net.ipv4.conf.all.rp_filter=1

# Uncomment the next line to enable TCP/IP SYN cookies
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5

# Do not accept ICMP redirects (prevent MITM attacks)
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0 
net.ipv6.conf.default.accept_redirects = 0

# Do not send ICMP redirects (we are not a router)
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Do not accept IP source route packets (we are not a router)
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Log Martian Packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Ignore ICMP broadcast requests
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Ignore Directed pings
net.ipv4.icmp_echo_ignore_all = 1
__EOF__


## Install and configure Fail2ban on our SSH port
if [ debInstalled "fail2ban" -eq 0 ]; then
    apt-get -y install fail2ban
fi
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.conf.dist
cat >/etc/fail2ban/jail.local << __EOF__
#
# Cadenrock Consulting LLC - www.cadenrock.com
#
# Custom fail2ban setup for Ubuntu/Debian
[ssh]
enabled  = true
port     = $SSHPORT
filter   = sshd
logpath  = /var/log/auth.log
maxretry = 6

[ssh-ddos]
enabled  = true
port     = $SSHPORT
filter   = sshd-ddos
logpath  = /var/log/auth.log
maxretry = 10

[recidive]
enabled  = true
filter   = recidive
logpath  = /var/log/fail2ban.log
action   = iptables-allports[name=recidive]
       sendmail-whois-lines[name=recidive, logpath=/var/log/fail2ban.log]
bantime  = 604800  ; 1 week
findtime = 86400   ; 1 day
maxretry = 5

#
# From http://snippets.aktagon.com/snippets/554-how-to-secure-an-nginx-server-with-fail2ban
#
[nginx-auth]
enabled = true
filter = nginx-auth
action = iptables-multiport[name=NoAuthFailures, port="http,https,8888"]
logpath = /var/log/nginx*/*error*.log
bantime = 600 # 10 minutes
maxretry = 6

[nginx-login]
enabled = true
filter = nginx-login
action = iptables-multiport[name=NoLoginFailures, port="http,https,8888"]
logpath = /var/log/nginx*/*access*.log
bantime = 600 # 10 minutes
maxretry = 6
 
[nginx-badbots]
enabled  = true
filter = apache-badbots
action = iptables-multiport[name=BadBots, port="http,https,8888"]
logpath = /var/log/nginx*/*access*.log
bantime = 86400 # 1 day
maxretry = 1
 
[nginx-noscript]
enabled = true
action = iptables-multiport[name=NoScript, port="http,https,8888"]
filter = nginx-noscript
logpath = /var/log/nginx*/*access*.log
maxretry = 6
bantime  = 86400 # 1 day
 
[nginx-proxy]
enabled = true
action = iptables-multiport[name=NoProxy, port="http,https,8888"]
filter = nginx-proxy
logpath = /var/log/nginx*/*access*.log
maxretry = 0
bantime  = 86400 # 1 day
__EOF__

cd /etc/fail2ban/filter.d
$CURL $GITHUB/fail2ban/filter.d/nginx-auth.conf
$CURL $GITHUB/fail2ban/filter.d/nginx-login.conf
$CURL $GITHUB/fail2ban/filter.d/nginx-noscript.conf
$CURL $GITHUB/fail2ban/filter.d/nginx-proxy.conf

cd /root

#
# Setup up some basic firewall rules
#
if [ -f /usr/sbin/ufw ]; then
    ALLOW="/usr/sbin/ufw allow"
    $ALLOW from any to any port 80,443 proto tcp
    $ALLOW from 0.0.0.0/0 to any port $SSHPORT proto tcp
    $ALLOW from 2001:470:1f0f:9d8::/64 to any port $SSHPORT,8888 proto tcp
    /usr/sbin/ufw -f enable
exit 0

#
# Setup our port knocker
#
sed -i -e "s/START_KNOCKD=0/START_KNOCKD=1/" /etc/default/knockd

/bin/cat > /etc/knockd.conf << _EOF_
[options]
    UseSyslog

[quickSSH]
    sequence    = 8000:udp,7000:tcp,9000:udp
    seq_timeout = 8
    command     = /sbin/iptables -I INPUT -s %IP% -p tcp --dport 8637 -j ACCEPT
    tcpflags    = syn
    cmd_timeout = 60
    stop_command = /sbin/iptables -D INPUT -s %IP% -p tcp --dport 8637 -j ACCEPT

[openWebDB]
    sequence    = 9000:tcp,8000:udp,7000:tcp
    seq_timeout = 12
    tcpflags    = syn
    command     = /sbin/iptables -I INPUT -s %IP% -p tcp --dport 8888 -j ACCEPT

[closeWebDB]
    sequence    = 7000:tcp,8000:udp,9000:tcp
    seq_timeout = 12
    tcpflags    = syn
    command     = /sbin/iptables -D INPUT -s %IP% -p tcp --dport 8888 -j ACCEPT

_EOF_

/bin/chmod 640 /etc/knockd.conf
/usr/sbin/service knockd start
