
###
# Creación de los certificados que usara JBoss para servir HTTPS
# NOTA: Si modifica las contraseñas asegúrese de cambiar también scripts/conf-jboss04.cli 
###

rm -rf client.crt  cliente.jks  clienteSellado.p12  keystore.jks  truststore.jks;

#Llaves Servidor
keytool -genkey -v -validity 365 -alias llaveSellado -keyalg RSA \
-sigalg SHA256withRSA -keysize 2048 -keystore keystore.jks \
-storepass secreto -keypass secreto \
-dname 'CN=servidorTSA, OU=SETEPLAN, O=Gobierno de El Salvador, C=SV,email=servicio.tsa@tsa.gob.sv' \
-ext SAN=dns:tsa.minx.gob.sv;

# Llaves Cliente
keytool -genkey -keystore cliente.jks -storepass secreto -validity 365 \
-keyalg RSA -sigalg SHA256withRSA -keysize 2048 -storetype pkcs12 \
-dname 'CN=clienteTSA, OU=SETEPLAN, O=Gobierno de El Salvador, C=SV,email=cliente.tsa@tsa.gob.sv';

#Exportar llave publica del cliente
keytool -exportcert -keystore cliente.jks  -storetype pkcs12 -storepass secreto \
-keypass secreto -file client.crt;

#Agergar llave publica del cliente a almacen de confianza
keytool -import -file client.crt -trustcacerts -noprompt -storepass secreto -keystore truststore.jks;

#Crear fardo de identidad P12 de cliente
keytool -importkeystore -srckeystore cliente.jks -destkeystore cliente-tsa.p12 \
-srcstorepass secreto -srcstoretype PKCS12 -deststoretype PKCS12 -deststorepass secreto;

cp *jks /opt/jboss/standalone/configuration/keystore;
