## Servidor de Firma y Sellado de Tiempo

Estas son las instrucciones para instalar [Signserver](https://www.signserver.org/), un servidor de firma desatendida y sellado de tiempo (RFC-3161). El servicio de firma desatendida permite aprovechar una API REST para firmar documentos de forma centralizada lo cual simplifica los procesos para los usuarios. Este servidor necesita usar certificados (P12, JKS) emitidos por una autoridad certificadora como [EJBCA](https://github.com/egobsv/certificadora). Las instrucciones de instalación pueden ejecutarse desde Ubuntu Xenial o Debian Jessie. 

## Requisitos

* OpenJDK 8
* [JBoss EAP 7.0/WildFly9](https://developers.redhat.com/download-manager/file/jboss-eap-7.0.0.zip) 
* [SignServer CE 4.0](https://sourceforge.net/projects/signserver/files/signserver/4.0/signserver-ce-4.0.0-bin.zip)


## Instalar SignServer

- Descargue este repositorio y guárdelo en su servidor dentro de la carpeta /opt. Asegurese de agregar y agregar el ZIP de JBoss y Signserver en esta misma carpeta.
 
- Edite el nombre de dominio de su servidor modificando el archivo crearCertificados.sh. Estos certificados se usaran para ofrecer HTTPS, no se usaran para firmar documentos.

- Prepare su servidor ejecutando los comandos desde la consola, seleccione el archivo que corresponda a su sistema operativo (instalar-jessie.sh o instalar-xenial.sh).  

- Ingrese a la carpeta 'configurar-jboss' y habra el archivo comandos-jboss.txt. Ejecute estos comandos uno a uno, debe asegurarse de que JBoss procesa cada comando con éxito uno a uno. 

- La interfaz pública estará disponible en https://[ip servidor]:8442/signserver 

- La misma página esta disponible por acceso privado usando autenticación TLS, solo para navegadores que tengan instalado el certificado cliente desde https://[ip servidor]:8443/signserver/. 

El sistema tiene varias páginas de prueba disponibles en:

https://localhost:8442/signserver/demo/

Antes de usar estos ejemplos es necesario configurar los servicios usando los certificados de una Autoridad Certificadora. Para este ejemplo se generaron dos certificados P12: sello.p12 de la SubCA Servicios para sellos de tiempo y  firmadorPDF.p12  de la SubCA Personas para firmar documentos PDF. Estos archivos están en la carpeta 'servicios'

```
 	 CA Raíz
     ------ | --------
     |               |

SubCA Personas     SubCA Servicios
```

## Configurar Servicio de Sellado de Tiempo

Para configurar el servicio de Sello de tiempo primero es necesario crear un Crypto Token que utilice el archivo sello.p12. Puede usar una archivo/almacén de certificado de sellado de tiempo distinto y configurarlo dentro de sello-crypto.properties. Luego debemos crear y activar un proceso TSA. Los comandos necesarios se listan a continuación. 

```
su signer;
cd /opt/signer;
bin/signserver getstatus brief all;
bin/signserver setproperties servicios/sello-crypto.properties
bin/signserver setproperties servicios/timestamp.properties
bin/signserver reload 1
bin/signserver reload 2
bin/signserver getstatus brief all
```

Con esto tenemos activado el servicio de sellado de tiempo y disponible para atender peticiones REST, para probarlo podemos usar OpenSSL como se muestra a continuación:

```
touch datos.txt;

echo "Probando el servicio de sellado de Teimpo" >> datos.txt;
openssl ts -query -data datos.txt -cert -sha256 -no_nonce -out solicitud.tsq;

cat solicitud.tsq | curl -s -S -H 'Content-Type: application/timestamp-query' \
 --data-binary @- http://localhost:8080/signserver/process?workerName=TimeStampSigner -o respuesta.tsr;

openssl ts -reply -in respuesta.tsr -text;
```


## Configurar Servicio de Firma de PDFs

Para configurar el servicio de firma de PDFs primero es necesario crear un Crypto Token que utilice el archivo firmadorPDF.p12 u otro almacén/certificado configurado dentro de pdf-crypto.properties.  Luego debemos crear y activar un proceso que atienda peticiones de firma usando el archivo pdfsigner.properties. La firma de archivos PDF incluye una imagen y un sello de tiempo, esto y otros valores se pueden configurar en las propiedades del servicio.

```
su signer;
cd /opt/signer;
bin/signserver getstatus brief all;
bin/signserver setproperties servicios/pdf-crypto.properties;
bin/signserver setproperties servicios/pdfsigner.properties;
bin/signserver reload 3;
bin/signserver reload 4;
bin/signserver getstatus brief all;
```  

En este punto ya puede probar el ejemplo de firma PDF desde https://localhost:8442/signserver/demo/pdfsign.jsp

Este servicio de firma está disponible ademas como un servicio Web a través de llamadas REST POST Puede encontrar más información en https://localhost:8442/signserver/doc/manual/integration.html#Web_Server_Interface 

Para configurar otros servicios puede revisar los ejemplos dentro de /opt/signserver/doc/sample-configs/.

## Licencia

Este trabajo esta cubierto dentro de la estrategia de desarrollo de servicios de Gobierno Electrónico del Gobierno de El Salvador y como tal es una obra de valor público sujeto a los lineamientos de la Política de Datos Abiertos y la licencia [CC-BY-SA](https://creativecommons.org/licenses/by-sa/3.0/deed.es).  
