# BashGeoIP

BashGeoIP permite Geolocalizar las distintas IP's existentes en el fichero pasado como parámetro. 
Permite además crear reglas en IPTABLES para "banear"  IPs que no pertenezcan a zonas geográficas permitidas.      

# IMPORTANTE
- Para el uso de la opción -b es necesario permisos de ROOT.
- El nombre de los países soportado, se basa en las características del servicio ip-api.com. Aunque no he encontrado en la documentación un listado de países, en un alto porcentaje hace uso del standard ISO3166, por lo que he subido dicho fichero, a modo ejemplo, en el repositorio. Dicho fichero se llama paises.txt.
 
# USO:
geo_ip.sh [-i] [-b listado_paises_permitidos] <fichero>

# OPCIONES:
-h --> Muestra ayuda del comando.
-i --> Ignoramos la opción de comprobación de IPs privadas.
-b <países.txt> -->  Añadimos una regla de filtrado IPTABLES a las IPs que NO pertenezcan al listado de países indicado en el fichero <países.txt>.

# CARACTERÍSTICAS:
* Filtra las direcciones PRIVADAS o ESPECIALES (Loopback, 0.0.0.0)
* Evita IP's duplicadas.

# DEPENDENCIAS
* BashGeoIP necesita de jq como parser JSON para gestionar el JSON devuelto por http://ip-api.com/.
* Hace uso del servicio de Geolocalización de IP de http://ip-api.com/.

# EJEMPLOS:
* geo_ip.sh ip.txt  --> Muestra una relación entre las direcciones IP existentes en el fichero "ip.txt" y el país al que pertenecen.
* geo_ip.sh -i -b paises.txt ip.txt -> Crea reglas de filtrado IPTABLES,  para impedir el acceso a las IPs existentes en el fichero 'ip.txt', que NO pertenezcan a los paises indicados en el archivo 'paises.txt'. Además, con la opción -i, hacemos que omita las IP's privadas.

# PRÓXIMAS MEJORAS:
- Lista blanca de IPs
- Lista blanca automática de Bots de posicionamiento con opción -s (SEO)


Cualquier comentario, error o mejora enviadlo a wllop@esat.es. 
Muchas gracias!!
@wllop