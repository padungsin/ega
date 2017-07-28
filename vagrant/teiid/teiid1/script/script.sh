#!/bin/bash

# example of using arguments to a script



yum -y install wget
yum -y install zip unzip

yum -y install java-1.8.0-openjdk.i686

sudo su

if [ ! -d "/opt/teiid" ]; then
	echo "Downloading teiid"
	wget -d /home/vagrant https://repository.jboss.org/nexus/service/local/repositories/releases/content/org/jboss/teiid/teiid/9.3.1/teiid-9.3.1-wildfly-server.zip
	unzip -d /home/vagrant /home/vagrant/teiid-9.3.1-wildfly-server.zip
	cp -r /home/vagrant/teiid-9.3.1 /opt/
  	ln -s /opt/teiid-9.3.1/ /opt/teiid

	cp -r /vagrant_data/teiid/modules/* /opt/teiid/modules/
	yes|cp /vagrant_data/teiid/standalone-teiid.xml /opt/teiid/standalone/configuration/


	echo "Store password in vault"
	mkdir -p /opt/teiid/vault
	keytool -genseckey -alias vault -keystore /opt/teiid/vault/vault.keystore -storetype jceks -keyalg AES -keysize 128 -storepass vault22 -keypass vault22


	echo "Generate SSL Key"
	keytool -genkeypair -alias teiid -storetype jks -keyalg RSA -keysize 2048 -keypass Password1! -keystore /opt/teiid/standalone/configuration/teiid.jks -storepass Password1! -dname "CN=teiid,OU=ega,L=Bangkok,C=TH" -validity 730 -v

	keytool -importkeystore -srckeystore /opt/teiid/standalone/configuration/teiid.jks \
	       -destkeystore /vagrant_data/ha-proxy/teiid-ssl-key/teiid.p12 \
	       -srcstoretype jks \
	       -deststoretype pkcs12 \
	       -srcstorepass Password1! \
	       -deststorepass Password1!

	openssl pkcs12 -in /vagrant_data/ha-proxy/teiid-ssl-key/teiid.p12 -out /vagrant_data/ha-proxy/teiid-ssl-key/teiid.pem -password pass:Password1! 
	sh /opt/teiid/bin/vault.sh --keystore /opt/teiid/vault/vault.keystore --keystore-password vault22 --alias vault --vault-block vb --attribute teiid --sec-attr password1! --enc-dir /opt/teiid/vault/ --iteration 120 --salt 1234abcd

	echo "Adding MariaDB Password"
	sh /opt/teiid/bin/vault.sh -k /opt/teiid/vault/vault.keystore -p vault22 -e /opt/teiid/vault -i 120 -s 1234abcd -v vault -b mariadb -a password -x Password1!


	touch /opt/teiid/standalone/configuration/https-users.properties
	

	useradd -r teiid
	chown -R teiid:teiid /opt/teiid*
	chmod -R 755 /opt/teiid*

	echo "Register teiid service"
	ln -s /opt/teiid/docs/contrib/scripts/init.d/wildfly-init-redhat.sh /etc/init.d/teiid.sh
	cp /vagrant_data/teiid/init.d/wildfly.conf /etc/default/wildfly.conf

	chkconfig --add teiid.sh
	systemctl enable teiid.service


	
	echo "Install Mod Cluster"
	wget -d /home/vagrant http://downloads.jboss.org/mod_cluster//1.3.1.Final/linux-x86_64/mod_cluster-1.3.1.Final-linux2-x64-ssl.tar.gz
	tar -xvf /home/vagrant/mod_cluster-1.3.1.Final-linux2-x64-ssl.tar.gz
	cp -r /home/vagrant/opt/jboss /opt

	yes|cp /vagrant_data/mod_cluster/httpd.conf /opt/jboss/httpd/httpd/conf/
fi






