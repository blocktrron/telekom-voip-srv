#!/bin/sh

# This script resolves a SIP SRV record and updates a file in the format of /etc/hosts
# with the A record of the resolved SRV record.

# Use with OpenWrt:
# 1. Copy this script to /usr/bin/update-record.sh
# 2. Make it executable with:
#    $ chmod +x /usr/bin/update-record.sh
# 3. Add the following line to /etc/crontabs/root:
#    * */6 * * * /usr/bin/update-record.sh /etc/tel.hostfile _sip._udp.tel.t-online.de resolved.tel.t-online.de
# 4. Instruct dnsmasq to use the host file by adding the following line to /etc/config/dhcp:
#    list addnhosts '/etc/tel.hostfile'
# 5. Restart cron and dnsmasq with:
#    $ /etc/init.d/cron restart
#    $ /etc/init.d/dnsmasq restart
# 6. Instruct OpenWrt to preserve the Script and the host file by adding the following lines to /etc/sysupgrade.conf:
#    $ echo "/usr/bin/update-record.sh" >> /etc/sysupgrade.conf
#    $ echo "/etc/tel.hostfile" >> /etc/sysupgrade.conf

usage() {
	echo "Usage: $0 <host file> <SRV record host> <A record name>"
	echo "Example: $0 /etc/tel.hostfile _sip._udp.tel.t-online.de resolved.tel.t-online.de"
	echo "	Resolves the SRV record _sip._udp.tel.t-online.de and writes the A record of the"
	echo "	resolved SRV record to /etc/tel.hostfile with the name resolved.tel.t-online.de"
	exit 1
}

# Check if all arguments are given
if [ $# -ne 3 ]; then
	usage
fi

HOST_FILE="$1"
SRV_RECORD_HOST="$2"
A_RECORD_NAME="$3"

# Get the SRV record using nslookup
SRV_RECORD="$(nslookup -type=SRV $SRV_RECORD_HOST | grep -m 1 "service =" | awk '{print $NF}')"

echo "SRV record: $SRV_RECORD"

# Resolve the A record of the SRV record
A_RECORD="$(nslookup -type=A $SRV_RECORD | grep "Address:" | tail -1 | awk '{print $NF}')"

# Check if the A record is a valid IPv4 address
if ! [[ $A_RECORD =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
	echo "A record is not a valid IPv4 address: $A_RECORD"
	exit 1
fi

# Generte content for host file. Syntax is as in /etc/hosts
HOST_FILE_CONTENT="$A_RECORD\t$A_RECORD_NAME"

echo "Host file content: $HOST_FILE_CONTENT"

# Write to host file
echo -e "$HOST_FILE_CONTENT" > "$HOST_FILE"
exit 0
