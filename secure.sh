#!/bin/bash

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
apt-get -y install fail2ban
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
port     = 8888
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
__EOF__

