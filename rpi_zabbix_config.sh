#!/bin/sh
#
#Zabbix Configuration script
# Created by Blake Carpenter for Telcion Communications Group
#
read -p "Press [Enter] to start zabbix proxy configuration..." NULL
#
#
#
# Configuring Zabbix application
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
#
#
# Specify Zabbix Proxy Hostname
echo "Please specify the Zabbix Proxy Hostname."
echo "Format of the Zabbix Proxy Hostname should be ###-ClientName"
read -p 'Zabbix Proxy Hostame: ' HOSTNAMEVAR
#
#
#
# Configuring Zabbix Server
echo "Please specify the Zabbix Server"
read -p 'Zabbix Server: ' ZABBIXSERVER
echo "Setting $ZABBIXSERVER as the Zabbix Server..."
sed -i "s/Server=127.0.0.1/Server=$ZABBIXSERVER/g" /etc/zabbix/zabbix_proxy.conf
echo "Setting $HOSTNAMEVAR as the proxy name..."
sed -i "s/Hostname=Zabbix proxy/Hostname=$HOSTNAMEVAR/g" /etc/zabbix/zabbix_proxy.conf
#
#
#
# Configuring Zabbix Proxy Parameters
echo Configuring Zabbix Proxy DB Connection Parameters...
sed -i 's/DBName=zabbix_proxy/DBName=zabbix/g' /etc/zabbix/zabbix_proxy.conf
sed -i "s/# DBPassword=/DBPassword=$MYSQLZABBIXPW/g" /etc/zabbix/zabbix_proxy.conf
echo Configuring zabbix proxy configuration retrieval frequency
sed -i 's/# ConfigFrequency=3600/ConfigFrequency=1200/g' /etc/zabbix/zabbix_proxy.conf
echo Configuring other zabbix proxy parameters...
sed -i 's/# StartPollers=5/StartPollers=10/g' /etc/zabbix/zabbix_proxy.conf
sed -i 's/# StartPollerUnreachable=1/StartPollerUnreachable=5/g' /etc/zabbix/zabbix_proxy.conf
sed -i 's/# StartPingers=1/StartPingers=10/g' /etc/zabbix/zabbix_proxy.conf
sed -i 's/# StartDiscoverers=1/StartDiscoverers=5/g' /etc/zabbix/zabbix_proxy.conf
sed -i 's/# StartVMwareCollectors=0/StartVMwareCollectors=5/g' /etc/zabbix/zabbix_proxy.conf
sed -i 's/# VMwareCacheSize=8M/VMwareCacheSize=100M/g' /etc/zabbix/zabbix_proxy.conf
sed -i 's/# CacheSize=8M/CacheSize=100M/g' /etc/zabbix/zabbix_proxy.conf
sed -i 's/# AllowRoot=0/AllowRoot=1/g' /etc/zabbix/zabbix_proxy.conf
echo Zabbix Proxy Parameters have been configured
#
#
#
# Configuring TLS PSK Encryption
echo Configuring TLS settings...
echo "Please specify the Zabbix Proxy PSK ID.  This should be in the format of PSK###."
echo "You should use the same number as you specified in the hostname ($HOSTNAMEVAR)."
read -p 'Zabbix Proxy PSK ID: ' PSKID
echo "You have chosen $PSKID."
#
#
#
# Configuring PSK ID
echo "Configuring PSK ID settings..."
sed -i 's/# TLSConnect=unencrypted/TLSConnect=psk/g' /etc/zabbix/zabbix_proxy.conf
sed -i "s/# TLSPSKIdentity=/TLSPSKIdentity=$PSKID/g" /etc/zabbix/zabbix_proxy.conf
sed -i "s+# TLSPSKFile=+TLSPSKFile=/etc/zabbix/zabbix_proxy.psk+g" /etc/zabbix/zabbix_proxy.conf
#
#
#
# Configuring PSK Encryption Key
echo "Creating PSK Encryption Key..."
touch /etc/zabbix/zabbix_proxy.psk
openssl rand -hex 32 > /etc/zabbix/zabbix_proxy.psk
#
#
#
# Instruct to add information to Zabbix Server
echo "Please add the following information to the Zabbix Server for the Zabbix Proxy setup:"
echo "Zabbix Proxy Name: $(tput setaf 1)$HOSTNAMEVAR $(tput sgr 0)"
echo "Zabbix Proxy PSK Identity: $(tput setaf 1)$PSKID $(tput sgr 0)"
echo "Zabbix Proxy PSK: $(tput setaf 1)$(cat /etc/zabbix/zabbix_proxy.psk) $(tput sgr 0)"
echo "Zabbix Proxy Address: echo $(tput setaf 1) $(curl -s ipv4.icanhazip.com) $(tput sgr 0)"
echo " "
echo " "
read -p "Once the above information has been added to the Zabbix Server, press [Enter] to restart the zabbix proxy..." NULL
#
#
#
# Configuring Zabbix Proxy Service
echo Restarting Zabbix Proxy Service...
systemctl restart zabbix-proxy
