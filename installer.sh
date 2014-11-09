#!/bin/sh

# TODOs:
# set -e or -x? Have a wrapper script for this?
# Sign this script and download it from github and check sig and run that way instead?

### RUN UPDATES
apt-get update
apt-get -y upgrade

### INSTALL THE TOR CLIENT
# https://www.torproject.org/docs/debian.html.en#ubuntu
echo "deb http://deb.torproject.org/torproject.org `lbs_release -cs` main" >> /etc/apt/sources.list

gpg --keyserver keys.gnupg.net --recv 886DDD89
gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | sudo apt-key add -
# TODO: Do manually like ec2-prep.sh does

apt-get update
apt-get -y install tor tor-arm deb.torproject.org-keyring obfsproxy

### SET-UP AUTOMATIC UPDATES
# https://help.ubuntu.com/community/AutomaticSecurityUpdates

# TODO: Daily?
cat > /etc/cron.weekly/apt-security-updates <<EOF
echo "**************" >> /var/log/apt-security-updates
date >> /var/log/apt-security-updates
aptitude update >> /var/log/apt-security-updates
aptitude safe-upgrade -o Aptitude::Delete-Unused=false --assume-yes --target-release `lsb_release -cs`-security >> /var/log/apt-security-updates
echo "Security updates (if any) installed"
EOF

chmod +x /etc/cron.weekly/apt-security-updates

cat > /etc/logrotate.d/apt-security-updates <<EOF
/var/log/apt-security-updates {
        rotate 2
        weekly
        size 250k
        compress
        notifempty
}
EOF

### CONFIGURE TOR
# https://www.torproject.org/docs/tor-relay-debian.html.en#setup
apt-get -y install openntpd

exit 0

# TODO: Actually do DirPort?
# Relay
echo >> /etc/tor/torrc <<EOF
# Don't open a local SOCKS port, this host is just running a relay/bridge
SocksPort 0

# Advertise our directory/onion ports as 80/443 but actually listen on high ports and redirect
#  requests using iptables rules (to avoid problems with the Tor Daemon binding on low ports.)
ORPort 443 NoListen
ORPort 127.0.0.1:9001 NoAdvertise
DirPort 80 NoListen
DirPort 127.0.0.1:9030 NoAdvertise

# Never send or receive more than 10GB of data per week. The accounting
# period runs from 10 AM on the 1st day of the week (Monday) to the same
# day and time of the next week.
AccountingStart week 1 10:00
AccountingMax 128 GB
BandwidthRate 250KB
BandwidthBurst 1GB

# This is not an exit node
ExitPolicy reject *:*
EOF
