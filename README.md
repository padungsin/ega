# Manual Installation
# Required
## Wget
    sudo yum -y install wget
## Zip
    sudo yum -y install zip unzip
## Jdk
    sudo yum -y install java-1.8.0-openjdk.i686

# Install Teiid
## Download and Extract
    sudo wget -P ~/ https://repository.jboss.org/nexus/service/local/repositories/releases/content/org/jboss/teiid/teiid/9.3.1/teiid-9.3.1-wildfly-server.zip
    sudo unzip -d ~/ ~/teiid-9.3.1-wildfly-server.zip
    sudo cp -r ~/teiid-9.3.1 /opt/
    sudo ln -s /opt/teiid-9.3.1/ /opt/teiid


## Create password vault
    sudo mkdir -p /opt/teiid/vault
    sudo keytool -genseckey -alias vault -keystore /opt/teiid/vault/vault.keystore -storetype jceks -keyalg AES -keysize 128 -storepass vault22 -keypass vault22
    sudo sh /opt/teiid/bin/vault.sh --keystore /opt/teiid/vault/vault.keystore --keystore-password vault22 --alias vault --vault-block vb --attribute teiid --sec-attr password1! --enc-dir /opt/teiid/vault/ --iteration 120 --salt 1234abcd

## Copy Result to standalone-teiid.xml
    Please make note of the following:
    ********************************************
    Vault Block:vb
    Attribute Name:teiid
    Configuration should be done as follows:
    VAULT::vb::teiid::1
    ********************************************
    WFLYSEC0048: Vault Configuration in WildFly configuration file:
    ********************************************`
    ...
    </extensions>
    <vault>
      <vault-option name="KEYSTORE_URL" value="/opt/teiid/vault/vault.keystore"/>
      <vault-option name="KEYSTORE_PASSWORD" value="MASK-5dOaAVafCSd"/>
      <vault-option name="KEYSTORE_ALIAS" value="vault"/>
      <vault-option name="SALT" value="1234abcd"/>
      <vault-option name="ITERATION_COUNT" value="120"/>
      <vault-option name="ENC_FILE_DIR" value="/opt/teiid/vault/"/>
    </vault><management> ...
    ********************************************
## Generate SSL Key
    sudo keytool -genkeypair -alias teiid -storetype jks -keyalg RSA -keysize 2048 -keypass Password1! -keystore /opt/teiid/standalone/configuration/teiid.jks -storepass Password1! -dname "CN=teiid,OU=ega,L=Bangkok,C=TH" -validity 730 -v
    sudo keytool -importkeystore -srckeystore /opt/teiid/standalone/configuration/teiid.jks \
	       -destkeystore /vagrant_data/ha-proxy/teiid-ssl-key/teiid.p12 \
	       -srcstoretype jks \
	       -deststoretype pkcs12 \
	       -srcstorepass Password1! \
	       -deststorepass Password1!
    sudo openssl pkcs12 -in /vagrant_data/ha-proxy/teiid-ssl-key/teiid.p12 -out /vagrant_data/ha-proxy/teiid-ssl-key/teiid.pem -password pass:Password1! 
	
## Create HTTPS Realm
### Execute Following command 
    sudo touch /opt/teiid/standalone/configuration/https-users.properties

### Store keystore password in vault
    sudo sh /opt/teiid/bin/vault.sh -k /opt/teiid/vault/vault.keystore -p vault22 -e /opt/teiid/vault -i 120 -s 1234abcd -v vault -b keystore -a password -x Password1!

### Use highlighted line from the result as a password in next step
    ********************************************
    Vault Block:keystore
    Attribute Name:password
    Configuration should be done as follows:
    VAULT::keystore::password::1
    ********************************************
    WFLYSEC0048: Vault Configuration in WildFly configuration file:
    ********************************************
    ...
    </extensions>
    <vault>
      <vault-option name="KEYSTORE_URL" value="/opt/teiid/vault/vault.keystore"/>
      <vault-option name="KEYSTORE_PASSWORD" value="MASK-5dOaAVafCSd"/>
      <vault-option name="KEYSTORE_ALIAS" value="vault"/>
      <vault-option name="SALT" value="1234abcd"/>
      <vault-option name="ITERATION_COUNT" value="120"/>
      <vault-option name="ENC_FILE_DIR" value="/opt/teiid/vault/"/>
    </vault><management> ...
    ********************************************
 
### Add <security-realm name="httpsRealm"> to standalone-teiid.xml

     <management>
            <security-realms>
    	...
                <security-realm name="httpsRealm">
                    <server-identities>
                        <ssl>
                            <keystore path="teiid.jks" relative-to="jboss.server.config.dir" keystore-password="${VAULT::keystore::password::1}" alias="teiid"/>
                        </ssl>
                    </server-identities>
                    <authentication>
                        <properties path="https-users.properties" relative-to="jboss.server.config.dir"/>
                    </authentication>
                </security-realm>
    	...
    	 </security-realms>
    	 ...
    	</management>


## Change management to secure port
### Modify Management Interface
        <management-interfaces>
            <http-interface security-realm="httpsRealm" http-upgrade-enabled="true">
                <socket-binding http="management-http" https="management-https"/>
            </http-interface>
        </management-interfaces>

### Add Management User
sudo sh /opt/teiid/bin/add-user.sh -up /opt/teiid/standalone/configuration/https-users.properties -r httpsRealm -a --user teiidAdmin --password Password1! --role admin

## Add HTTPS Listener
### Add https-listener to standalone-teiid.xml
        <subsystem xmlns="urn:jboss:domain:undertow:3.0">
            ...
            <server name="default-server">
                ..
    <http-listener name="default" socket-binding="http" redirect-socket="https"/>
                <https-listener name="default-https" security-realm="httpsRealm" socket-binding="https"/>
                ...
	</server>
		...
	</subsystem>


## Copy JDBC Module and Configuration
sudo cp -r /vagrant_data/teiid/modules/* /opt/teiid/modules/

### Add JDBC Driver
                <drivers>
                    ...
                    <driver name="teiid" module="org.jboss.teiid.client">
                        <driver-class>org.teiid.jdbc.TeiidDriver</driver-class>
                        <xa-datasource-class>org.teiid.jdbc.TeiidDataSource</xa-datasource-class>
                    </driver>
                    <driver name="mariadb" module="org.mariadb">
                        <xa-datasource-class>org.mariadb.jdbc.MariaDbDataSource</xa-datasource-class>
                    </driver>
                </drivers>
## Configuring jdbc datasource
### Add jdbc password to vault
    sudo sh /opt/teiid/bin/vault.sh -k /opt/teiid/vault/vault.keystore -p vault22 -e /opt/teiid/vault -i 120 -s 1234abcd -v vault -b mariadb -a password -x Password1!
### Use following result in a password field
    =========================================================================      
                                                                                   
    Jul 31, 2017 8:09:31 AM org.picketbox.plugins.vault.PicketBoxSecurityVault init
    INFO: PBOX00361: Default Security Vault Implementation Initialized and Ready   
    WFLYSEC0047: Secured attribute value has been stored in Vault.                 
    Please make note of the following:                                             
    ********************************************                                   
    Vault Block:mariadb                                                            
    Attribute Name:password                                                        
    Configuration should be done as follows:                                       
    VAULT::mariadb::password::1                                                    
    ********************************************                                   
    WFLYSEC0048: Vault Configuration in WildFly configuration file:                
    ********************************************                                   
    ...                                                                            
    </extensions>                                                                  
    <vault>                                                                        
      <vault-option name="KEYSTORE_URL" value="/opt/teiid/vault/vault.keystore"/>  
      <vault-option name="KEYSTORE_PASSWORD" value="MASK-5dOaAVafCSd"/>            
      <vault-option name="KEYSTORE_ALIAS" value="vault"/>                          
      <vault-option name="SALT" value="1234abcd"/>                                 
      <vault-option name="ITERATION_COUNT" value="120"/>                           
      <vault-option name="ENC_FILE_DIR" value="/opt/teiid/vault/"/>                
    </vault><management> ...                                                       
    ********************************************                                   

### Add datasource to standalone-teiid.xml

                <datasource jndi-name="java:jboss/MariaDBDS" pool-name="MariaDBDS" enabled="true" statistics-enabled="true">
                    <connection-url>jdbc:mariadb://192.168.33.50:3306/teiid</connection-url>
                    <driver>mariadb</driver>
                    <security>
                        <user-name>teiid</user-name>
                        <password>${VAULT::mariadb::password::1}</password>
                    </security>
                    <validation>
                        <valid-connection-checker class-name="org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLValidConnectionChecker"/>
                        <exception-sorter class-name="org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLExceptionSorter"/>
                    </validation>
                </datasource>
 
## Install as a service

    sudo mkdir -p /var/log/teiid
    sudo ln -s /opt/teiid/docs/contrib/scripts/init.d/wildfly-init-redhat.sh /etc/init.d/teiid.sh
    sudo cp /opt/teiid/docs/contrib/scripts/init.d/wildfly.conf /etc/default/wildfly.conf

    sudo useradd -r teiid
    sudo chown -R teiid:teiid /opt/teiid*
    sudo chmod -R 755 /opt/teiid*

    sudo chown -R teiid:teiid /var/log/teiid
    sudo chmod -R 755 /var/log/teiid


## wildfly.conf
    ## Location of WildFly
    JBOSS_HOME="/opt/teiid"
    ## The username who should own the process.
    JBOSS_USER=teiid
    ## The mode WildFly should start, standalone or domain
    JBOSS_MODE=standalone

    ## Configuration for standalone mode
    JBOSS_CONFIG=standalone-teiid.xml
    ## The amount of time to wait for startup
    STARTUP_WAIT=30
    ## The amount of time to wait for shutdown
    SHUTDOWN_WAIT=30
    ## Location to keep the console log
    #JBOSS_CONSOLE_LOG="/var/log/teiid/console.log"
    JBOSS_CONSOLE_LOG="/vagrant_data/teiid/log/teiid.log"
 
# Install Mod Cluster

## Download mod cluster
    sudo wget -P ~/ http://downloads.jboss.org/mod_cluster//1.3.1.Final/linux-x86_64/mod_cluster-1.3.1.Final-linux2-x64-ssl.tar.gz

## extract to installation
    sudo tar -xvf /home/vagrant/mod_cluster-1.3.1.Final-linux2-x64-ssl.tar.gz
    sudo cp -r /home/vagrant/opt/jboss /opt

## Modify /opt/jboss/httpd/httpd/conf/ httpd.conf

    ServerRoot "/opt/jboss/httpd/httpd"
    Listen 80
    <IfModule manager_module>
      Listen 8081
      <VirtualHost *:8081>
        ServerAdvertise on
        EnableMCPMReceive
        ManagerBalancerName teiidbalancer
        <Location /mod_cluster_manager>
          SetHandler mod_cluster-manager
          # add ip of clients allowed to access mod_cluster-manager
          Require ip 192.168.33.
       </Location>
        <Directory />
          # add ip of JBoss nodes to join this proxy here
          Require ip 192.168.33.
        </Directory>
      </VirtualHost>
    </IfModule>

## Add extension module to standalone-teiid.xml
    <extension module="org.jboss.as.modcluster"/>

## Add modcluster subsystem to standalone-teiid.xml

      <subsystem xmlns="urn:jboss:domain:modcluster:2.0">
         <mod-cluster-config advertise-socket="modcluster" proxies="proxy1 proxy2" connector="default" balancer="teiidbalancer" sticky-session="true">
            <dynamic-load-provider>
               <load-metric type="cpu"/>
            </dynamic-load-provider>
         </mod-cluster-config>
      </subsystem>

## Add binding proxy standalone-teiid.xml
    <socket-binding-group …..
    <socket-binding name="modcluster" port="0" multicast-address="224.0.0.1" multicast-port="23364"/>
        <outbound-socket-binding name="proxy1">
            <remote-destination host="192.168.33.21" port="8081"/>
        </outbound-socket-binding>
        <outbound-socket-binding name="proxy2">
            <remote-destination host="192.168.33.22" port="8081"/>
        </outbound-socket-binding>
    </socket-binding-group>

## Start Mod Cluster
sudo /opt/jboss/httpd/sbin/apachectl start
