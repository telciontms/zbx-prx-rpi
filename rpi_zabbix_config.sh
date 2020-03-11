#!/bin/sh
#
#Zabbix Configuration script
# Created by Blake Carpenter for Telcion Communications Group
#
# Checking for existence of zabbix_proxy.conf backup file
if [ -f "/etc/zabbix/zabbix_proxy.conf.orig" ]; then
	echo "zabbix_proxy.conf.orig exists"
	cp /etc/zabbix/zabbix_proxy.conf.orig /etc/zabbix/zabbix_proxy.conf
else
	echo "zabbix_proxy.conf.orig does not exist"
	echo "creating zabbix_proxy.conf.orig file"
	cp /etc/zabbix/zabbix_proxy.conf /etc/zabbix/zabbix_proxy.conf.orig
fi
#
# Specify Zabbix Proxy Hostname
echo "Please specify the Zabbix Proxy Hostname."
echo "Format of the Zabbix Proxy Hostname should be ###-ClientName"
read -p 'Zabbix Proxy Hostame: ' HOSTNAMEVAR
echo "You have chosen $(tput setaf 1)$HOSTNAMEVAR $(tput sgr 0)."
echo "Please be sure to use $(tput setaf 1)$HOSTNAMEVAR $(tput sgr 0)as the proxy name when you name your proxy server in Zabbix."
#
#
# Configuring Zabbix Server
echo "Setting tms.telcion.com as the destination server..."
sleep 5
sed -i 's/Server=127.0.0.1/Server=tms.telcion.com/g' /etc/zabbix/zabbix_proxy.conf
echo "Setting $HOSTNAMEVAR as the proxy name..."
sleep 5
sed -i "s/Hostname=Zabbix proxy/Hostname=$HOSTNAMEVAR/g" /etc/zabbix/zabbix_proxy.conf
#
#
# Configuring TLS PSK Encryption
echo Configuring TLS settings...
sleep 5
echo "Please specify the Zabbix Proxy PSK ID.  This should be in the format of PSK###.  You should use the same number as you specified in the hostname."
echo "If you specified the name to be 999-ClientName then your PSK ID should be PSK999.  Make note of this PSK ID when you add your proxy to the Zabbix Server."
read -p 'Zabbix Proxy PSK ID: ' PSKID
echo "You have chosen $(tput setaf 1)$PSKID $(tput sgr 0)."
#
#
# Configuring PSK ID
echo "Configuring PSK ID settings..."
sleep 10
sed -i 's/# TLSConnect=unencrypted/TLSConnect=psk/g' /etc/zabbix/zabbix_proxy.conf
sed -i "s/# TLSPSKIdentity=/TLSPSKIdentity=$PSKID/g" /etc/zabbix/zabbix_proxy.conf
sed -i "s+# TLSPSKFile=+TLSPSKFile=/etc/zabbix/zabbix_proxy.psk+g" /etc/zabbix/zabbix_proxy.conf
#
#
# Configuring PSK Encryption Key
echo "Creating PSK Encryption Key..."
sleep 5
touch /etc/zabbix/zabbix_proxy.psk
openssl rand -hex 32 > /etc/zabbix/zabbix_proxy.psk
echo "Please make note of the following encryption key as you will need it when you add this proxy to the Zabbix Server:"
echo $(tput setaf 1)$(cat /etc/zabbix/zabbix_proxy.psk) $(tput sgr 0)
#
#
# Gather WAN IP Address Information
echo "Gathering WAN IP Address Information..."
sleep 5
echo "Your WAN IP address is:"
echo $(tput setaf 1) $(curl -s ipv4.icanhazip.com) $(tput sgr 0)
echo "Please use the above information in order to create the proxy connection in the Zabbix server.
