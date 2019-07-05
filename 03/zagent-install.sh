#!/bin/bash

source functions

echo "installing zabbix agent"
server_ip='192.168.56.100'
lport=10050 # listen port
sport=10051 # server port

packets=('mc' 'http://repo.zabbix.com/zabbix/3.2/rhel/7/x86_64/zabbix-release-3.2-1.el7.noarch.rpm' 'zabbix-agent' 'nginx' 'java-1.8.0-openjdk-devel')
for p in ${packets[@]}
{
  yuminstall ${p}
}

AGENT_CONF_FILE='/etc/zabbix/zabbix_agentd.conf'

bl='^[[:blank:]]*'
tl='.*'
PATTERN_1=$bl'PidFile='$tl
PATTERN_2=$bl'LogFile='$tl
PATTERN_3=$bl'DebugLevel='$tl

PATTERN_4=$bl'Server='$tl
PATTERN_5=$bl'ListenPort='$tl
PATTERN_6=$bl'ListenIP='$tl
PATTERN_7=$bl'StartAgents='$tl

PATTERN_8=$bl'ServerActive='$tl
PATTERN_9=$bl'Hostname='$tl
PATTERN_10=$bl'HostnameItem='$tl


STR_1='PidFile=/var/run/zabbix/zabbix_agentd.pid'
STR_2='LogFile=/var/log/zabbix/zabbix_agentd.log'
STR_3='DebugLevel=3'

# passive agent
STR_4="Server=$server_ip"
STR_5="ListenPort=$lport"
STR_6='ListenIP=0.0.0.0'
STR_7='StartAgents=3'

# active agent
STR_8="ServerActive=$server_ip:$sport"
STR_9='Hostname=Zabbix server'
STR_10='HostnameItem=system.hostname'

for i in {1..10}
do
  p=PATTERN_$i; pat=${!p}; s=STR_$i; st=${!s};
  #echo $pat $st $AGENT_CONF_FILE
  mygrep $pat $st $AGENT_CONF_FILE
done


#First, create a new tomcat group:
sudo groupadd tomcat

#Then create a new tomcat user.
sudo useradd -M -s /bin/nologin -g tomcat -d /opt/tomcat tomcat

cd ~
wget http://ftp.byfly.by/pub/apache.org/tomcat/tomcat-8/v8.5.42/bin/apache-tomcat-8.5.42.tar.gz
sudo mkdir /opt/tomcat
sudo tar xvf apache-tomcat-8*tar.gz -C /opt/tomcat --strip-components=1

#Change to the Tomcat installation path:
cd /opt/tomcat

#Give the tomcat group ownership over the entire installation directory:
sudo chgrp -R tomcat /opt/tomcat

#Next, give the tomcat group read access to the conf directory and all of its contents, and execute access to the directory itself:
sudo chmod -R g+r conf
sudo chmod g+x conf


#Then make the tomcat user the owner of the webapps, work, temp, and logs directories:
sudo chown -R tomcat webapps/ work/ temp/ logs/

cd /home/vagrant
echo ... copy tomcat.service file
cp tomcat.service /etc/systemd/system/

# deploying war application
cp TestApp.war /opt/tomcat/webapps/

services=('nginx' 'tomcat' 'zabbix-agent')
for s in ${services[@]}
{
  enstart ${s}
}
