#!/bin/sh
#
# This script set-ups automatic security updates, and installs and configures a Tor relay or
#  bridge node. It's made to be specifically used with Ubuntu 14.04.

# TODO:
# 1) set -e or -x? Have a wrapper script for this?
# 2) Sign this script and download it from github and check sig and run that way instead, have
#     a method for error reporting back encrypted failures w/ opt-in?

usage() {
  echo "Usage: $0 <relay | bridge | private_bridge> <# of GB bandwidth cap> <node nickname> <contactinfo>"
  exit 1
}

if [ "$#" -ne 4 ]; then
  usage
fi

NODE_TYPE=$1
if [ $NODE_TYPE != "relay" -a $NODE_TYPE != "bridge" -a $NODE_TYPE != "private_bridge" ]; then
  echo "Invalid tor node type '$NODE_TYPE'"
  usage
fi

BANDWIDTH_CAP=$2
# TODO: Check that it's numeric and reasonable

NODE_NICKNAME=$3
# TODO: Validation?

CONTACTINFO=$4
# TODO: Validation?

### RUN UPDATES
apt-get update
apt-get -y upgrade

### INSTALL THE TOR CLIENT
# https://www.torproject.org/docs/debian.html.en#ubuntu
echo "deb http://deb.torproject.org/torproject.org `lsb_release -cs` main" >> /etc/apt/sources.list

# Generated with:
#gpg --keyserver keys.gnupg.net --recv 886DDD89
#gpg --armor --export-options export-minimal --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89
gpg --import << EOF
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1

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
=DMFk
-----END PGP PUBLIC KEY BLOCK-----
EOF
gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | sudo apt-key add -

apt-get update
apt-get -y install tor tor-arm deb.torproject.org-keyring obfsproxy

### SET-UP AUTOMATIC UPDATES
# https://help.ubuntu.com/community/AutomaticSecurityUpdates

# We don't enable rebooting upgrades. These nodes are not multi-user systems, and we're not
#  worried about kernel exploitation. (TODO: Is this missing anything? Updates other than the
#  kernel requiring reboots?))
cat > /etc/cron.daily/apt-security-updates <<EOF
echo "**************" >> /var/log/apt-security-updates
date >> /var/log/apt-security-updates
aptitude update >> /var/log/apt-security-updates
aptitude safe-upgrade -o Aptitude::Delete-Unused=false --assume-yes --target-release `lsb_release -cs`-security >> /var/log/apt-security-updates
echo "Security updates (if any) installed"
EOF

chmod +x /etc/cron.daily/apt-security-updates

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

# Set-up port forwarding for the onion routing port. Serve on port 443 to help users avoid
#  restrictive firewalls. Tor privilege seperation makes opening low-numbered ports infeasible.
echo 1 > /proc/sys/net/ipv4/conf/eth0/forwarding 
cat > /etc/iptables.rules <<EOF
*nat
:PREROUTING ACCEPT [368:102354]
:POSTROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [92952:20764374]
-A PREROUTING -p tcp -i eth0 -j REDIRECT -m tcp --dport 443 --to-ports 9001
COMMIT
EOF

cat > /etc/network/if-pre-up.d/iptables <<EOF
#!/bin/sh
/sbin/iptables-restore < /etc/iptables.rules
EOF
chmod +x /etc/network/if-pre-up.d/iptables
/etc/network/if-pre-up.d/iptables

# Patch https://trac.torproject.org/projects/tor/ticket/13716
if [ -d /sys/kernel/security/apparmor/features/signal ]; then
  echo 'signal (send) set=("term") peer="unconfined",' >>/etc/apparmor.d/local/system_tor
  apparmor_parser -r /etc/apparmor.d/system_tor
fi

apt-get -y install ruby
# Use ERb templating to generate the torrc
ruby -rerb -rostruct -e 'puts ERB.new($stdin.read, nil, "-").result(OpenStruct.new(:config => ARGV[0], :bandwidth_cap => ARGV[1]).instance_eval { binding })' $NODE_TYPE $BANDWIDTH_CAP > /etc/tor/torrc <<EOF
# Don't open a local SOCKS port, this host is just running a relay/bridge
SocksPort 0

# This is not an exit node
ExitPolicy reject *:*

# Advertise our directory/onion ports as 80/443 but actually listen on high ports and redirect
#  requests using iptables rules (to avoid problems with the Tor Daemon binding on low ports.)
ORPort 443 NoListen
ORPort 0.0.0.0:9001 NoAdvertise

# We don't run a directory because they're heavily skewed towards download and will make us hit
#  our AccountingMax prohibitively early (since AccountingMax stops as soon as it hits that
#  amount for either DL and UL)

# Cap our weekly bandwidth consumption so we don't go beyond our monthly allowance.
AccountingStart week 1 00:00
# We assume 4 weeks per month * 2 because accountingmax is the cap for upload OR download
AccountingMax <%= bandwidth_cap.to_i / 8 %> GB

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
EOF

service tor restart
