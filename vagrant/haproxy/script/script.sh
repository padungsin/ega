#!/bin/bash

yum -y install wget

if [ "`systemctl is-active haproxy`" == "active" ]; then

	echo "HAProxy Exists"
else

	echo "Install HAProxy"

	yum -y install openssl-devel.x86_64
	yum -y install pcre-devel
	yum provides pcre.h
	sudo wget https://www.haproxy.org/download/1.7/src/haproxy-1.7.8.tar.gz -O ~/haproxy.tar.gz

	sudo tar xzvf ~/haproxy.tar.gz -C ~/
	sudo cd ~/haproxy-1.7.8


	sudo make TARGET=linux2628 USE_PCRE=1 USE_OPENSSL=1 USE_ZLIB=1 USE_CRYPT_H=1 USE_LIBCRYPT=1
	sudo make install

	sudo mkdir -p /etc/haproxy
	sudo mkdir -p /run/haproxy
	sudo mkdir -p /var/lib/haproxy 
	sudo touch /var/lib/haproxy/stats

	sudo ln -s /usr/local/sbin/haproxy /usr/sbin/haproxy
	sudo cp /vagrant_data/haproxy/haproxy.cfg /etc/haproxy


	sudo cp ~/haproxy-1.7.8/examples/haproxy.init /etc/init.d/haproxy
	sudo chmod 755 /etc/init.d/haproxy
	sudo systemctl daemon-reload

	sudo useradd -r haproxy

	#if firewall is enabled
	#sudo firewall-cmd --permanent --zone=public --add-service=http
	#sudo firewall-cmd --permanent --zone=public --add-port=8181/tcp
	#sudo firewall-cmd --reload

	 sudo mkdir -p /etc/haproxy/sslkeys
	 sudo cp /vagrant_data/haproxy/sslkeys/marloega.pem /etc/haproxy/sslkeys

	 sudo systemctl enable haproxy
	 sudo systemctl start haproxy


	echo "Install keepalived"
	sudo yum install -y keepalived
	sudo mv /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf.ori
	sudo cp /vagrant_data/haproxy/keepalived.conf /etc/keepalived/keepalived.conf
	sudo systemctl enable keepalived
	sudo systemctl start keepalived
	
fi






