#!/bin/sh
# Variables

LIST_OF_APPS="vim telnet wget perl"

#read -p "Script beginning, press [Enter] to continue..." NULL
echo "Script process beginning..."
#Updating Operating System
echo "Updating device..."
apt-get update
apt-get -y upgrade

echo "Updates have completed..."
#read -p "Press [Enter] to change hostname..." NULL
# Changing Hostname of Device
echo Please specify a hostname for this device...
echo This hostname has nothing to do with the zabbix proxy hostname you will configure later...
read -p 'Hostname: ' HOSTNAME
hostnamectl set-hostname $HOSTNAME
echo Setting hostname...
sed -i "s/raspberrypi/$HOSTNAME/g" /etc/hosts
sleep 2

#read -p "Press [Enter] to continue" NULL
# Change IP address
#echo Please specify IP address for eth0:
#read -p 'IP Address: ' IPADDRESS
#echo Please specify Subnet Mask for eth0:
#read -p 'Subnet Mask: ' SUBNETMASK
#echo Please specify Default Gateway for eth0:
#read -p 'Gateway: ' GATEWAY
#echo Configuring IP settings...
#sleep 5
#ifconfig eth0 $IPADDRESS netmask $SUBNETMASK
#route add default gw $GATEWAY eth0

echo "Hostname has been set to $HOSTNAME..."
#read -p "Press [Enter] to create the telcion user account..." NULL
# Add users
echo Creating telcion user...please specify password and provide details when prompted...
adduser telcion
adduser telcion sudo
sleep 2

echo "Telcion user has been created..."
#read -p "Press [Enter] to configure ssh settings..." NULL
# Configuring SSH
echo Configuring ssh settings...
sleep 2
sed -i 's/#Protocol 2/Protocol 2/g' /etc/ssh/ssh_config
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/g' /etc/ssh/sshd_config
echo 'AllowUsers telcion' >> /etc/ssh/sshd_config
systemctl restart ssh

echo "SSH settings have been configured..."
#read -p "Press [Enter] to install default applications..." NULL
#Installing initial apps
echo Installing default applications...
sleep 2
apt install -y $LIST_OF_APPS

echo "Default applications have been installed..."
#read -p "Press [Enter] to change the root user and pi user passwords..." NULL
# Changing password for root and pi
sleep 2
echo Change root Password...
echo Please specify password for root...
passwd root
echo The root password has been changed...
sleep 2
echo Change pi Password...
echo Please specify password for pi...
passwd pi
echo The pi user password has been changed...
sleep 2

echo "root user and pi user passwords have now been changed..."
#read -p "Press [Enter] to configure sudo password requirement..." NULL
# Requiring sudo Password
echo Configuring sudo password requirement...
sleep 2
sed -i 's/pi ALL=(ALL) NOPASSWD: ALL/pi ALL=(ALL) PASSWD: ALL/g' /etc/sudoers.d/010_pi-nopasswd
echo 'telcion ALL=(ALL) PASSWD: ALL' >> /etc/sudoers.d/010_pi-nopasswd

echo "Sudo password requirement configuration has been completed..."
#read -p "Press [Enter] to configure device timezone..." NULL
# Configure timezone information
echo Configuring timezone...
sleep 2
timedatectl set-timezone America/Los_Angeles
echo 'FallbackNTP=0.us.pool.ntp.org 1.us.pool.ntp.org 2.us.pool.ntp.org' >> /etc/systemd/timesyncd.conf
echo "Timezone has been configured as America/Los_Angeles"

#read -p "Press [Enter] to install and configure the ufw firewall..." NULL
echo "Installing and configuring firewall settings..."
# Configure Firewall
echo Installing ufw firewall...
apt install ufw -y
echo Configuring ufw firewall...
ufw allow ssh
ufw limit ssh/tcp
echo 'y' | ufw enable
echo Installing fail2ban...
apt install fail2ban -y
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
echo "Firewall has been installed and configured..."

#read -p "Updating .bashrc for all users..."
echo "updating .bashrc for all users..."
wget -O /home/telcion/.bashrc.new "https://telcion-my.sharepoint.com/:u:/g/personal/telcionsoftwarerepo_telcion_onmicrosoft_com/EbFFiUTKb7BIlc_NhnzWrPQB268jDlCqzadnR6pItfW-Jw?e=rQhh4J&download=1"
mv /root/.bashrc /root/.bashrc.orig
cp /home/telcion/.bashrc.new /root/.bashrc
mv /home/pi/.bashrc /home/pi/.bashrc.orig
cp /home/telcion/.bashrc.new /home/pi/.bashrc
mv /home/telcion/.bashrc /home/telcion/.bashrc.orig
mv /home/telcion/.bashrc.new /home/telcion/.bashrc
echo "Settings for .bashrc configured for all users"

#read -p "Press [Enter] to install zabbix proxy..." NULL
# Installing Zabbix Proxy
echo "Installing Zabbix Proxy and Zabbix Agent..."
wget https://repo.zabbix.com/zabbix/4.4/raspbian/pool/main/z/zabbix-release/zabbix-release_4.4-1+buster_all.deb
dpkg -i zabbix-release_4.4-1+buster_all.deb
apt update
apt install -y zabbix-proxy-mysql zabbix-agent
#read -p "Press [Enter] to configure the Zabbix database..." NULL

# Configuring Zabbix database
echo Please configure root and zabbix user passwords based on our documentation in ITG.
echo You can find the information here:
echo "For the mysql root user: $(tput setaf 1)https://telcion.itglue.com/775995/passwords/5380548#partial=&sortBy=name:asc&filters=%5B%5D $(tput sgr 0)"
echo "For the mysql zabbix user: $(tput setaf 1)https://telcion.itglue.com/775995/passwords/5380562#partial=&sortBy=name:asc&filters=%5B%5D $(tput sgr 0)"
read -p 'Specify password for mysql root user: ' MYSQLROOTPW
read -p 'Specify password for mysql zabbix user: ' MYSQLZABBIXPW
mysql -uroot -e "create database zabbix character set utf8 collate utf8_bin;"
mysql -uroot -e "grant all privileges on zabbix.* to zabbix@localhost identified by '$MYSQLZABBIXPW';"
mysql -uroot -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$MYSQLROOTPW');"
mysql -uroot -e "FLUSH PRIVILEGES;"
echo "Importing the initial schema.  When prompted provide the mysql zabbix user password as specified above.  This process takes a few minutes so please be patient.  Pressing additional keys could interrupt script process..."
zcat /usr/share/doc/zabbix-proxy-mysql*/schema.sql.gz | mysql -uzabbix -p zabbix
echo "Importing of the initial schema has completed."

read -p "Press [Enter] to start zabbix proxy configuration..." NULL
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
# Specify Zabbix Proxy Hostname
echo "Please specify the Zabbix Proxy Hostname."
echo "Format of the Zabbix Proxy Hostname should be ###-ClientName"
read -p 'Zabbix Proxy Hostame: ' HOSTNAMEVAR
echo "You have chosen $(tput setaf 1)$HOSTNAMEVAR $(tput sgr 0)."
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
# Configuring Zabbix Proxy Parameters
echo Configuring Zabbix Proxy DB Connection Parameters...
sed -i 's/DBName=zabbix_proxy/DBName=zabbix/g' /etc/zabbix/zabbix_proxy.conf
sed -i "s/# DBPassword=/DBPassword=$MYSQLZABBIXPW/g" /etc/zabbix/zabbix_proxy.conf
sleep 5
echo Configuring zabbix proxy configuration retrieval frequency
sed -i 's/# ConfigFrequency=3600/ConfigFrequency=1200/g' /etc/zabbix/zabbix_proxy.conf
sleep 5
echo Configuring other zabbix proxy parameters...
sed -i 's/# StartPollers=5/StartPollers=10/g' /etc/zabbix/zabbix_proxy.conf
sed -i 's/# StartPollerUnreachable=1/StartPollerUnreachable=5/g' /etc/zabbix/zabbix_proxy.conf
sed -i 's/# StartPingers=1/StartPingers=10/g' /etc/zabbix/zabbix_proxy.conf
sed -i 's/# StartDiscoverers=1/StartDiscoverers=5/g' /etc/zabbix/zabbix_proxy.conf
sed -i 's/# StartVMwareCollectors=0/StartVMwareCollectors=5/g' /etc/zabbix/zabbix_proxy.conf
sed -i 's/# VMwareCacheSize=8M/VMwareCacheSize=100M/g' /etc/zabbix/zabbix_proxy.conf
sed -i 's/# CacheSize=8M/CacheSize=100M/g' /etc/zabbix/zabbix_proxy.conf
sed -i 's/# AllowRoot=0/AllowRoot=1/g' /etc/zabbix/zabbix_proxy.conf
sleep 10
echo Zabbix Proxy Parameters have been configured
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
#
#
# Gather WAN IP Address Information
echo "Gathering WAN IP Address Information..."
sleep 5
#
#
# Instruct to add information to Zabbix Server
echo "Please add the following information to the Zabbix Server for the Zabbix Proxy setup:"
echo "Zabbix Proxy Name: $(tput setaf 1)$HOSTNAMEVAR $(tput sgr 0)"
echo "Zabbix Proxy PSKID: $(tput setaf 1)$PSKID $(tput sgr 0)"
echo "Zabbix Proxy Encryption Key: $(tput setaf 1)$(cat /etc/zabbix/zabbix_proxy.psk) $(tput sgr 0)"
echo "Zabbix Proxy WAN IP Address: echo $(tput setaf 1) $(curl -s ipv4.icanhazip.com) $(tput sgr 0)"
echo " "
echo " "
read -p "Once the above information has been added to the Zabbix Server, press [Enter] to start the zabbix proxy..." NULL
#
#
echo Configuring Zabbix Proxy startup...
systemctl enable zabbix-proxy
echo Starting Zabbix Proxy...
systemctl start zabbix-proxy
echo Please review status of Zabbix Proxy...
systemctl status zabbix-proxy
#
#
# Configuring Zabbix Agent
echo "Configuring Zabbix Agent"
sed -i 's/ServerActive=127.0.0.1/# ServerActive=127.0.0.1/g' /etc/zabbix/zabbix_agentd.conf
sed -i 's/Hostname=Zabbix server/# Hostname=Zabbix server/g' /etc/zabbix/zabbix_agentd.conf
systemctl enable zabbix-agent
systemctl start zabbix-agent
# Cleanup
echo "Running cleanup..."
echo "-> sudo apt-get -y autoremove"
apt-get -y autoremove
echo
echo "-> sudo apt-get clean"
sudo apt-get clean
echo
echo "Downloading rpi_zabbix_config.sh script for future configuration changes..."
wget -O /home/telcion/rpi_zabbix_config.sh "https://telcion-my.sharepoint.com/:u:/g/personal/telcionsoftwarerepo_telcion_onmicrosoft_com/EewLnIAmm_BNglBtVfHmhXgBmjP9MflCBC6WgcJSLTwOAw?e=VvUnuH&download=1"
echo "A copy of the Zabbix configuration script has been placed in the following location: /home/telcion/rpi_zabbix_config.sh"
echo "You can re-run this configuration script of you need to make changes to the zabbix server connection such as zabbix server name, proxy name and encryption settings."
echo "A reboot is required to complete the setup process."
read -p "Press [Enter] to reboot the system..." NULL
echo "The system will be rebooting in 10 seconds..."
sleep 10
reboot
