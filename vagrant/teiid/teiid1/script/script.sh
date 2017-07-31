#!/bin/bash

# example of using arguments to a script



yum -y install wget
yum -y install zip unzip

yum -y install java-1.8.0-openjdk.i686


if [ ! -d "/opt/teiid" ]; then
	echo "Downloading teiid"
	sudo wget -P ~/ https://repository.jboss.org/nexus/service/local/repositories/releases/content/org/jboss/teiid/teiid/9.3.1/teiid-9.3.1-wildfly-server.zip
	sudo unzip -d ~/ ~/teiid-9.3.1-wildfly-server.zip
	sudo cp -r ~/teiid-9.3.1 /opt/
	sudo ln -s /opt/teiid-9.3.1/ /opt/teiid

	sudo cp -r /vagrant_data/teiid/modules/* /opt/teiid/modules/
	sudo yes|cp /vagrant_data/teiid/standalone-teiid.xml /opt/teiid/standalone/configuration/

	

	echo "Store password in vault"
	sudo mkdir -p /opt/teiid/vault
	sudo keytool -genseckey -alias vault -keystore /opt/teiid/vault/vault.keystore -storetype jceks -keyalg AES -keysize 128 -storepass vault22 -keypass vault22
	sudo sh /opt/teiid/bin/vault.sh --keystore /opt/teiid/vault/vault.keystore --keystore-password vault22 --alias vault --vault-block vb --attribute teiid --sec-attr password1! --enc-dir /opt/teiid/vault/ --iteration 120 --salt 1234abcd

	

	echo "Generate SSL Key"
	sudo keytool -genkeypair -alias teiid -storetype jks -keyalg RSA -keysize 2048 -keypass Password1! -keystore /opt/teiid/standalone/configuration/teiid.jks -storepass Password1! -dname "CN=teiid,OU=ega,L=Bangkok,C=TH" -validity 730 -v

	sudo keytool -importkeystore -srckeystore /opt/teiid/standalone/configuration/teiid.jks \
	       -destkeystore /vagrant_data/ha-proxy/teiid-ssl-key/teiid.p12 \
	       -srcstoretype jks \
	       -deststoretype pkcs12 \
	       -srcstorepass Password1! \
	       -deststorepass Password1!

	sudo openssl pkcs12 -in /vagrant_data/ha-proxy/teiid-ssl-key/teiid.p12 -out /vagrant_data/ha-proxy/teiid-ssl-key/teiid.pem -password pass:Password1! 
	
	sudo touch /opt/teiid/standalone/configuration/https-users.properties
	
	echo "Adding Keystore Password"
	sudo sh /opt/teiid/bin/vault.sh -k /opt/teiid/vault/vault.keystore -p vault22 -e /opt/teiid/vault -i 120 -s 1234abcd -v vault -b keystore -a password -x Password1!
	


	echo "Adding MariaDB Password"
	sudo sh /opt/teiid/bin/vault.sh -k /opt/teiid/vault/vault.keystore -p vault22 -e /opt/teiid/vault -i 120 -s 1234abcd -v vault -b mariadb -a password -x Password1!


	
	sudo mkdir -p /var/log/teiid

	echo "Register teiid service"
	sudo ln -s /opt/teiid/docs/contrib/scripts/init.d/wildfly-init-redhat.sh /etc/init.d/teiid.sh
	sudo cp /vagrant_data/teiid/wildfly.conf /etc/default/wildfly.conf


	sudo useradd -r teiid
	sudo chown -R teiid:teiid /opt/teiid*
	sudo chmod -R 755 /opt/teiid*

	sudo chown -R teiid:teiid /var/log/teiid
	sudo chmod -R 755 /var/log/teiid

	sudo chmod 755 /etc/init.d/teiid.sh
	sudo chmod 755 /etc/default/wildfly.conf




	sudo chkconfig --add teiid.sh
	sudo service teiid start
	

	
	echo "Install Mod Cluster"
	sudo wget -P ~/ http://downloads.jboss.org/mod_cluster//1.3.1.Final/linux-x86_64/mod_cluster-1.3.1.Final-linux2-x64-ssl.tar.gz
	sudo tar -xvf ~/mod_cluster-1.3.1.Final-linux2-x64-ssl.tar.gz
	sudo cp -r ~/opt/jboss /opt

	sudo yes|cp /vagrant_data/mod_cluster/httpd.conf /opt/jboss/httpd/httpd/conf/

	
fi






