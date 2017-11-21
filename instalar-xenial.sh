#!/usr/bin/env bash
    timedatectl set-timezone America/El_Salvador;
    hostnamectl set-hostname sellado; 
    apt-get update;     
    apt-get -y install  openjdk-8-jre-headless ca-certificates-java;
    apt-get -y install openjdk-8-jdk ant ant-optional unzip ntp postgresql-9.5 postgresql-client-9.5 unzip;
  
    mkdir -p  /etc/jboss; cd /opt/;
    unzip -q /opt/signserver-ce-4.0.0-bin.zip;
    unzip -q /opt/jboss-eap-7.0.0.zip;
    mv /opt/jboss-eap-7.0 /opt/jboss;
    mv /opt/signserver-ce-4.0.0 /opt/signserver;

    cp *.properties /opt/signserver/conf/;
    mv servicios /opt/signserver/;

    mkdir /opt/jboss/standalone/configuration/keystore;
    mkdir /opt/signserver/certificados;
    cd /opt/signserver/certificados/;
    cp /opt/crearCertificados.sh .;   
    chmod +x crearCertificados.sh; ./crearCertificados.sh;
   
    cp /opt/configurar-jboss/jboss.conf /etc/jboss/;
    cp /opt/configurar-jboss/jboss.service /etc/systemd/system/;
    touch /etc/profile.d/signer.sh;
    echo "export APPSRV_HOME=/opt/jboss" >> /etc/profile.d/signer.sh;
    echo "export SIGNSERVER_NODEID=node1" >> /etc/profile.d/signer.sh;

    groupadd -r jboss;
    useradd -r -g jboss -d /opt/jboss -s /sbin/nologin jboss;
    useradd -r -g jboss -d /opt/signserver -s /bin/bash signer;
    echo 'signer:signer' | sudo chpasswd;
    chown -R jboss:jboss /opt/jboss;
    chown -R signer:jboss /opt/signserver;
    chmod 775 -R  /opt/jboss /opt/signserver;
    systemctl start jboss.service;
    systemctl enable jboss.service;

sudo -u postgres psql -U postgres <<OMG
 CREATE USER signserver WITH PASSWORD 'signserver';
 CREATE DATABASE signserver WITH OWNER signserver ENCODING 'UTF8' ;
OMG
