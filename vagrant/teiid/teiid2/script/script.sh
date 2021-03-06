#!/bin/bash

# example of using arguments to a script



yum -y install wget
yum -y install zip unzip

yum -y install java-1.8.0-openjdk.i686


if [ ! -d "/opt/teiid" ]; then
	echo "Downloading teiid"
	sudo wget -d ~/ https://repository.jboss.org/nexus/service/local/repositories/releases/content/org/jboss/teiid/teiid/9.3.1/teiid-9.3.1-wildfly-server.zip
	sudo unzip -d ~/teiid-9.3.1-wildfly-server.zip
	sudo cp -r ~/teiid-9.3.1 /opt/
  	sudo ln -s /opt/teiid-9.3.1/ /opt/teiid

	sudo cp -r /vagrant_data/teiid/modules/* /opt/teiid/modules/
	sudo yes|cp /vagrant_data/teiid/standalone-teiid.xml /opt/teiid/standalone/configuration/

	sudo mkdir -p /var/log/teiid

	echo "Store password in vault"
	sudo mkdir -p /opt/teiid/vault
	sudo keytool -genseckey -alias vault -keystore /opt/teiid/vault/vault.keystore -storetype jceks -keyalg AES -keysize 128 -storepass vault22 -keypass vault22

	echo "Adding MariaDB Password"
	sudo sh /opt/teiid/bin/vault.sh -k /opt/teiid/vault/vault.keystore -p vault22 -e /opt/teiid/vault -i 120 -s 1234abcd -v vault -b mariadb -a password -x Password1!


	echo "Generate SSL Key"
	sudo keytool -genkeypair -alias teiid -storetype jks -keyalg RSA -keysize 2048 -keypass Password1! -keystore /opt/teiid/standalone/configuration/teiid.jks -storepass Password1! -dname "CN=teiid,OU=ega,L=Bangkok,C=TH" -validity 730 -v


	echo "Adding Keystore Password"
	sudo sh /opt/teiid/bin/vault.sh -k /opt/teiid/vault/vault.keystore -p vault22 -e /opt/teiid/vault -i 120 -s 1234abcd -v vault -b keystore -a password -x Password1!

	sudo keytool -importkeystore -srckeystore /opt/teiid/standalone/configuration/teiid.jks \
	       -destkeystore /vagrant_data/ha-proxy/teiid-ssl-key/teiid.p12 \
	       -srcstoretype jks \
	       -deststoretype pkcs12 \
	       -srcstorepass Password1! \
	       -deststorepass Password1!

	sudo openssl pkcs12 -in /vagrant_data/ha-proxy/teiid-ssl-key/teiid.p12 -out /vagrant_data/ha-proxy/teiid-ssl-key/teiid.pem -password pass:Password1! 
	sudo sh /opt/teiid/bin/vault.sh --keystore /opt/teiid/vault/vault.keystore --keystore-password vault22 --alias vault --vault-block vb --attribute teiid --sec-attr password1! --enc-dir /opt/teiid/vault/ --iteration 120 --salt 1234abcd



	sudo touch /opt/teiid/standalone/configuration/https-users.properties
	

	sudo useradd -r teiid
	sudo chown -R teiid:teiid /opt/teiid*
	sudo chmod -R 755 /opt/teiid*

	sudo chown -R teiid:teiid /var/log/teiid
	sudo chmod -R 755 /var/log/teiid



	echo "Register teiid service"
	sudo ln -s /opt/teiid/docs/contrib/scripts/init.d/wildfly-init-redhat.sh /etc/init.d/teiid.sh
	sudo cp /vagrant_data/teiid/wildfly.conf /etc/default/wildfly.conf

	sudo chkconfig --add teiid.sh
	sudo service teiid start
	sudo chkconfig teiid.sh on

	
	echo "Install Mod Cluster"
	sudo wget -d /home/vagrant http://downloads.jboss.org/mod_cluster//1.3.1.Final/linux-x86_64/mod_cluster-1.3.1.Final-linux2-x64-ssl.tar.gz
	sudo tar -xvf ~/mod_cluster-1.3.1.Final-linux2-x64-ssl.tar.gz
	cp -r ~/opt/jboss /opt

	sudo yes|cp /vagrant_data/mod_cluster/teiid2/httpd.conf /opt/jboss/httpd/httpd/conf/
	sudo cp /vagrant_data/mod_cluster/mod_cluster /etc/init.d/
	sudo chmod 755 /etc/init.d/mod_cluster
	sudo chkconfig --add mod_cluster
	sudo chkconfig mod_cluster on

	sudo sh /opt/bpm/jbpms/add-user.sh -up /opt/teiid/standalone/configuration/https-users.properties -r httpsRealm -a --user teiidAdmin --password Password1! --role admin
	sudo sh /opt/teiid/bin/add-user.sh -r ApplicationRealm -a --user user --password password --role odata
	
	
	sudo cp /vagrant_data/mod_cluster/mod_cluster

fi






