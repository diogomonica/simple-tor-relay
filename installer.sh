#!/bin/sh

# TODOs:
# set -e or -x? Have a wrapper script for this?
# Sign this script and download it from github and check sig and run that way instead?

### RUN UPDATES
apt-get update
apt-get -y upgrade

### INSTALL THE TOR CLIENT
# https://www.torproject.org/docs/debian.html.en#ubuntu
echo "deb http://deb.torproject.org/torproject.org `lsb_release -cs` main" >> /etc/apt/sources.list

gpg --keyserver keys.gnupg.net --recv 886DDD89
gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | sudo apt-key add -
# TODO: Do manually like ec2-prep.sh does

apt-get update
apt-get -y install tor tor-arm deb.torproject.org-keyring obfsproxy

### SET-UP AUTOMATIC UPDATES
# https://help.ubuntu.com/community/AutomaticSecurityUpdates

# TODO: Updates that require reboots?
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

# Set-up port forwards.
echo 1 > /proc/sys/net/ipv4/conf/eth0/forwarding 
cat > /etc/iptables.rules <<EOF
*nat
:PREROUTING ACCEPT [368:102354]
:POSTROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [92952:20764374]
-A PREROUTING -p tcp -i eth0 -j REDIRECT -m tcp --dport 443 --to-ports 9001
-A PREROUTING -p tcp -i eth0 -j REDIRECT -m tcp --dport 80 --to-ports 9030
COMMIT
EOF

cat > /etc/network/if-pre-up.d/iptables <<EOF
#!/bin/sh
/sbin/iptables-restore < /etc/iptables.rules
EOF
chmod +x /etc/network/if-pre-up.d/iptables
/etc/network/if-pre-up.d/iptables

# Patch https://trac.torproject.org/projects/tor/ticket/13716
echo 'signal (send) set=("term") peer="unconfined",' >>/etc/apparmor.d/local/system_tor
apparmor_parser -r /etc/apparmor.d/system_tor

apt-get -y install ruby
# Use ERb templating to generate the torrc
# TODO: Actually do DirPort? Is it covered under Accounting?
ruby -rerb -rostruct -e 'puts ERB.new($stdin.read, nil, "-").result(OpenStruct.new(:config => ARGV[0], :bandwidth_cap => ARGV[1]).instance_eval { binding })' private_bridge 1024 > /etc/tor/torrc <<EOF
# Don't open a local SOCKS port, this host is just running a relay/bridge
SocksPort 0

# This is not an exit node
ExitPolicy reject *:*

# Advertise our directory/onion ports as 80/443 but actually listen on high ports and redirect
#  requests using iptables rules (to avoid problems with the Tor Daemon binding on low ports.)
ORPort 443 NoListen
ORPort 0.0.0.0:9001 NoAdvertise
#DirPort 80 NoListen
#DirPort 0.0.0.0:9030 NoAdvertise

# Cap our monthly bandwidth consumption so we don't go beyond our monthly allowance.
AccountingStart month 1 00:00
AccountingMax <%= bandwidth_cap.to_i / 2 %> GB
# Should we even have this here? Do we care?
BandwidthRate 1MB
BandwidthBurst 1GB

# TODO Nickname
# TODO ContactInfo

<% if config == 'private_bridge' || config == 'bridge' -%>
# Bridge configuration
BridgeRelay 1
ServerTransportPlugin obfs2,obfs3 exec /usr/bin/obfsproxy --managed
ServerTransportListenAddr obfs2 0.0.0.0:<%= 1024 + rand(65535 - 1024) %>
ServerTransportListenAddr obfs3 0.0.0.0:<%= 1024 + rand(65535 - 1024) %>
<% end -%>

<% if config == 'private_bridge' -%>
# This bridge is private, don't advertise it.
PublishServerDescriptor 0
<% end -%>

<% if config == 'relay' -%>
<% end -%>
EOF

service tor restart
