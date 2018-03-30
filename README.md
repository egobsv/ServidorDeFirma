

## Servidor de Firma y Sellado de Tiempo

Estas son las instrucciones para instalar un servidor de firma electrónica de documentos y sellado de tiempo. El servidor utiliza el software libre Signserver y tiene [múltiples servicios disponibles](https://www.signserver.org/features.html) dentro de un servidor de firma desatendida y sellado de tiempo (RFC-3161). El servicio de firma desatendida permite aprovechar una API HTTP para firmar documentos de forma centralizada lo cual simplifica los procesos para los usuarios. Este servidor necesita usar certificados (P12, JKS) emitidos por una autoridad certificadora como [EJBCA](https://github.com/egobsv/certificadora). Las instrucciones de instalación pueden ejecutarse desde Ubuntu Xenial o Debian Jessie. 

### Requisitos

* OpenJDK 8
* [JBoss EAP 7.0/WildFly9](https://developers.redhat.com/download-manager/file/jboss-eap-7.0.0.zip) 
* [SignServer CE 4.0](https://sourceforge.net/projects/signserver/files/signserver/4.0/signserver-ce-4.0.0-bin.zip)


### Instalar SignServer

- Descargue este repositorio y guárdelo en su servidor dentro de la carpeta /opt. Asegúrese de descargar y agregar el ZIP de JBoss y Signserver en esta misma carpeta.
 
- Edite el nombre de dominio de su servidor modificando el archivo crearCertificados.sh. Estos certificados se usaran para ofrecer HTTPS, no se usaran para firmar documentos.

- Prepare su servidor ejecutando los comandos desde la consola, seleccione el archivo que corresponda a su sistema operativo (instalar-jessie.sh o instalar-xenial.sh).  

- Ingrese a la carpeta 'configurar-jboss' y abra el archivo comandos-jboss.txt. Ejecute estos comandos uno a uno, debe asegurarse de que JBoss procesa cada comando con éxito uno a uno. 

- La interfaz pública estará disponible en https://[ip servidor]:8442/signserver 

- La misma página esta disponible por acceso privado usando autenticación TLS, solo para navegadores que tengan instalado el certificado cliente desde https://[ip servidor]:8443/signserver/. 

Aun no hemos configurado ningún servicio, el servidor tiene varias páginas de prueba que pueden ser usadas una vez esten listos los servicios:

https://[ip servidor]:8442/signserver/demo/

El siguiente paso es configurar los servicios usando los certificados de una Autoridad Certificadora. Para este ejemplo se generaron dos certificados P12: 
* sello.p12: de la SubCA Servicios, es un certificado con las atributos necesarios para sellos de tiempo
*  firmadorPDF.p12  de la SubCA Personas, es un certificado con las atributos necesarios para  para firmar documentos PDF.

 Estos archivos están en la carpeta 'servicios' de este repositorio.

```
 	     CA Raíz
     ------ | --------
     |               |

SubCA Personas     SubCA Servicios
```

### Servicio de Sellado de Tiempo

Para configurar el servicio de Sello de tiempo primero es necesario crear un Crypto Token que utilice el archivo sello.p12. Puede usar una archivo/almacén de certificado de sellado de tiempo distinto y configurarlo dentro de sello-crypto.properties modificando los siguientes valores:

```
WORKERGENID1.NAME= NOMBRE-CRYPTO-TOKEN
WORKERGENID1.KEYSTORETYPE=PKCS12
WORKERGENID1.KEYSTOREPATH=/ruta/archivo/p12
WORKERGENID1.KEYSTOREPASSWORD=contraseña
```

Luego debemos crear y activar un proceso que atienda peticiones de Sello de Tiempo. Dentro del archivo timestamp.properties modifique estas variables según corresponda: 
```
WORKERGENID1.NAME= NOMBRE-PROCESO-SELLO
WORKERGENID1.CRYPTOTOKEN= NOMBRE-CRYPTO-TOKEN
WORKERGENID1.DEFAULTKEY=[usuario/CN del certificado]
WORKERGENID1.TSA=[DN de la Autoridad de Sello]
```

Luego debemos crear y activar un proceso TSA. A continuación ejecute los siguientes comandos, asegurese de usar el número de proceso que corresponda (en lugar de 1 y 2) de acuerdo a la imformación provista por el comando 'bin/signserver getstatus brief all':

```
su signer;
cd /opt/signserver;
bin/signserver getstatus brief all;
bin/signserver setproperties servicios/sello-crypto.properties
bin/signserver setproperties servicios/timestamp.properties
bin/signserver reload 1
bin/signserver reload 2
bin/signserver getstatus brief all
```

Con esto tenemos activado el servicio de sellado de tiempo y disponible para atender peticiones HTTP POST , para probarlo podemos usar OpenSSL como se muestra a continuación:

```
touch datos.txt;

echo "Probando el servicio de sellado de Teimpo" >> datos.txt;
openssl ts -query -data datos.txt -cert -sha256 -no_nonce -out solicitud.tsq;

cat solicitud.tsq | curl -s -S -H 'Content-Type: Application/timestamp-query' \
 --data-binary @- http://localhost:8080/signserver/process?workerName=TimeStampSigner -o respuesta.tsr;

##Leer Respuesta sellada
openssl ts -reply -in respuesta.tsr -text;
```


## Servicio de Firma de PDFs

Para configurar el servicio de firma de PDFs primero es necesario crear un Crypto Token que utilice el archivo firmadorPDF.p12 u otro almacén/certificado. Dentro del archivo pdf-crypto.properties modifique estas variables segun corresponda:
```
WORKERGENID1.NAME= NOMBRE-CRYPTO-TOKEN
WORKERGENID1.KEYSTORETYPE=PKCS12
WORKERGENID1.KEYSTOREPATH=/ruta/archivo/p12
WORKERGENID1.KEYSTOREPASSWORD=contraseña
```

Luego debemos crear y activar un proceso que atienda peticiones de firma. Dentro del archivo pdfsigner.properties modifique estas variables según corresponda: 
```
WORKERGENID1.NAME= NOMBRE-PROCESO-FIRMADOR
WORKERGENID1.CRYPTOTOKEN= NOMBRE-CRYPTO-TOKEN
WORKERGENID1.DEFAULTKEY=[usuario/CN del certificado]
WORKERGENID1.REASON= [Descripción de la firma]
WORKERGENID1.VISIBLE_SIGNATURE_CUSTOM_IMAGE_BASE64=[imagen/logo de firma]
WORKERGENID1.TSA_WORKER=[Nombre del Servicio de Sellado de Tiempo]
```

A continuación ejecute los siguientes comandos, asegurese de usar el número de proceso que corresponda (en lugar de 3 y 4) de acuerdo a la imformación provista por el comando 'bin/signserver getstatus brief all':

```
su signer;
cd /opt/signserver;
bin/signserver getstatus brief all;
bin/signserver setproperties servicios/pdf-crypto.properties;
bin/signserver setproperties servicios/pdfsigner.properties;
bin/signserver reload 3;
bin/signserver reload 4;
bin/signserver getstatus brief all;
```  
Este servicio de firma está disponible a través de llamadas HTTP POST como se describe en la [documentación de la API](https://www.signserver.org/doc/current/manual/integration.html#Web_Server_Interface). Por ejemplo:
```
curl -i -H 'Content-Type: Application/x-www-form-urlencoded' --data-binary @documento-para-firmar.pdf -X POST http://localhost:8080/signserver/process?workerName=PDFSigner -o documento-firmado.pdf
```
El servicio responde con el archivo 'documento-firmado.pdf', este es el PDF firmado, puede ver la firma usando Acrobat Reader. Para comprobar la firma, necesita [configurar la validación de firma digital en Acrobat Reader](https://help.adobe.com/es_ES/acrobat/standard/using/WS396794562021d52e-4a2d930c12b348f892b-8000.html).  La imagen y apariencia de la firma puede modificarse en la configuración del servicio en servicios/pdfsigner.properties.

En este punto ya puede probar el ejemplo de firma PDF desde https://[ip servidor]:8442/signserver/demo/pdfsign.jsp

Para configurar otros servicios puede revisar los ejemplos dentro de /opt/signserver/doc/sample-configs/.


### URL de servicios
A continuación crearemos URL de servicio más amigables. Para esto usaremos NGINX como proxy inverso.
```
apt-get install nginx-light
```
Editar la configuración dentro de  /etc/nginx/sites-enabled/default, y agregar los siguientes bloques:
```  
       location /sello {
          proxy_pass http://localhost:8080/signserver/process?workerName=TimeStampSigner;
          proxy_read_timeout 30s;
          #tamaño máximo de POST
          client_max_body_size 5M;
        }
       
       location /firmar-pdf {
          proxy_pass http://localhost:8080/signserver/process?workerName=PDFSigner;
          proxy_read_timeout 30s;
          #tamaño máximo de POST
          client_max_body_size 5M;
        }
```
Después de reiniciar el servicio de NGINX, podremos consumir servicios  usando el nuevo URL:
* http://[ip servidor]/sello
* http://[ip servidor]/firmar-pdf

### Licencia
Este trabajo esta cubierto dentro de la estrategia de desarrollo de servicios de Gobierno Electrónico del Gobierno de El Salvador y como tal es una obra de valor público sujeto a los lineamientos de la Política de Datos Abiertos y la licencia [CC-BY-SA](https://creativecommons.org/licenses/by-sa/3.0/deed.es).  
