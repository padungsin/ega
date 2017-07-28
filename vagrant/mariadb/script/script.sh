#!/bin/bash


sudo su
if [ "`systemctl is-active mariadb`" == "active" ]; then
    echo "Mariadb is actived"
else
	yes|cp /vagrant_data/mariadb/MariaDB.repo /etc/yum.repos.d
	yum install MariaDB-server MariaDB-client -y
	systemctl start mariadb.service
	systemctl enable mariadb.service

	cp /vagrant_data/mariadb/server.cnf /etc/my.cnf.d/

fi