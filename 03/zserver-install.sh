#!/bin/bash

source functions

db='zabbix' # mysql database name
user='zabbix' # mysql user name
read password < .password # read password for mysql user from file

echo "installing zabbix server"

packets=('mc' 'http://repo.zabbix.com/zabbix/3.2/rhel/7/x86_64/zabbix-release-3.2-1.el7.noarch.rpm' \
 'mariadb' 'mariadb-server' 'zabbix-server-mysql' 'zabbix-web-mysql')
for p in ${packets[@]}
{
  yuminstall ${p}
}


sudo systemctl stop mariadb
##sudo systemctl stop httpd


# 1.2 Mysql Initial configuration
sudo /usr/bin/mysql_install_db --user=mysql

# 1.3 Starting and enabling mysqld service
enstart mariadb

# 1.4 Creating initial database
mysql -uroot -e "drop database $db"
mysql -uroot -e "create database $db character set utf8 collate utf8_bin"
mysql -uroot -e "grant all privileges on $db.* to $user@localhost identified by '$password'"
echo "Finish init database !!!"
echo 

#2.2 Import initial schema and data
sudo zcat /usr/share/doc/zabbix-server-mysql-*/create.sql.gz | mysql -u$user --password=$password --database=$db


#2.3 Database configuration for Zabbix server

# vi /etc/zabbix/zabbix_server.conf
echo
echo patching zabbix_server.conf !!!
echo
echo
echo Comment zabbix conf !!!

ZABBIX_CONF_FILE='/etc/zabbix/zabbix_server.conf'

ZABBIX_PATTERN_1=$bl'DBHost='$tl
ZABBIX_PATTERN_2=$bl'DBName='$tl
ZABBIX_PATTERN_3=$bl'DBUser='$tl
ZABBIX_PATTERN_4=$bl'DBPassword='$tl

ZABBIX_STR_1='DBHost=localhost'
ZABBIX_STR_2="DBName=$db"
ZABBIX_STR_3="DBUser=$user"
ZABBIX_STR_4="DBPassword=$password"



for i in {1..4}   # patching zabbix_server.conf
do
  p=ZABBIX_PATTERN_$i; pat=${!p}; s=ZABBIX_STR_$i; st=${!s};
  #echo $pat $st ${ZABBIX_CONF_FILE}
  mygrep $pat $st ${ZABBIX_CONF_FILE}
done



# php_value date.timezone Europe/Riga
ZABBIX_CONF_FILE2='/etc/httpd/conf.d/zabbix.conf'
ZABBIX_PATTERN_12='.*Riga.*'
ZABBIX_STR_12='        php_value date.timezone Europe\/Minsk'


if grep -q -E "$ZABBIX_PATTERN_12" $ZABBIX_CONF_FILE2;
then
    echo "patching httpd/conf.d/zabbix.conf"
    sudo sed -i "s|$ZABBIX_PATTERN_12|$ZABBIX_STR_12|" $ZABBIX_CONF_FILE2
    else
    echo no patch!!!
fi

enstart zabbix-server
enstart httpd
