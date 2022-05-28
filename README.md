# BashGeoIP      

BashGeoIP permite Geolocalizar las distintas IP's existentes en el fichero pasado como parámetro. 
Permite además crear reglas en IPTABLES para "banear"  IPs que no pertenezcan a zonas geográficas permitidas. Además, permite la exclusión tanto de IPs como de dominios para evitar su "restricción" geográfica.
Además, cacheará las ubicaciones de las IPs buscadas para aumentar rendimiento y reducir peticiones al servicio ip-api.
      

# IMPORTANTE
- Para el uso de la opción -b es necesario permisos de ROOT.
- El nombre de los países soportado, se basa en las características del servicio ip-api.com. Aunque no he encontrado en la documentación un listado de países, en un alto porcentaje hace uso del standard ISO3166, por lo que he subido dicho fichero, a modo ejemplo, en el repositorio. Dicho fichero se llama paises.txt.
 
# USO:
geo_ip.sh [-i] [-b listado_paises_permitidos] [-ip X.X.X.X] [-ei fichero] [-ed fichero] [-cache fichero] fichero_a_monitorizar 

# OPCIONES:
-h --> Muestra ayuda del comando.

-i --> Ignoramos la opción de comprobación de IPs privadas.

-b <países.txt> -->  Añadimos una regla de filtrado IPTABLES a las IPs que NO pertenezcan al listado de países indicado en el fichero <países.txt>.
-ip <ip> --> Indica el país de la IP pasada como parámetro.
      
-ei <fichero> --> Excluimos del filtrado a las IPs que aparecen en el fichero pasado como parámetro. Sólo aplica con la opción -b.
      
-ed <fichero> --> Excluimos los dominios/FQDN que aparecen en el fichero pasado como parámetro. Sólo aplica con opción -b.
      
-cache <fichero> --> Podemos indicar en qué fichero se almacenarán la relación IP:País. En el caso de no indicar la opción -cache, se creará automáticamente un fichero llamado "cache.txt" en el mismo directorio donde está ubicado geo_ip.sh.

      

# CARACTERÍSTICAS:
* Filtra las direcciones PRIVADAS o ESPECIALES (Loopback, 0.0.0.0)
* Evita IP's duplicadas.
* Permite excluir del geobloqueo tanto IPs (-ei) como Dominios (-ed).
* No duplica entradas en IPTables.
* Uso de cache para almacenar la relación IP:País. Así reducimos las peticiones al servidor ip-api.com, puesto que iremos guardando en este fichero las distintas consultas realizadas.


# DEPENDENCIAS
* BashGeoIP necesita de jq como parser JSON para gestionar el JSON devuelto por http://ip-api.com/.
* Hace uso del servicio de Geolocalización de IP de http://ip-api.com/.

# EJEMPLOS:
* geo_ip.sh ip.txt  --> Muestra una relación entre las direcciones IP existentes en el fichero "ip.txt" y el país al que pertenecen.
* geo_ip.sh -i -b paises.txt ip.txt -> Crea reglas de filtrado IPTABLES,  para impedir el acceso a las IPs existentes en el fichero 'ip.txt', que NO pertenezcan a los paises indicados en el archivo 'paises.txt'. Además, con la opción -i, hacemos que omita las IP's privadas.
* geo_ip.sh --ip 8.8.8.8 --> Mostrará el país de la IP 8.8.8.8
* geo_ip.sh -b pais.txt -ed edns.txt -ei eip.txt -cache /esat/cache.txt nginx.log --> Bloqueará todas las IPs existentes en el fichero nginx.log que no sean de "España" y que no estén en el fichero de IPs excluidas (eip.txt) ni asociadas a los dominios existentes en edns.txt. Además, para la geolocalización hará uso del fichero /esat/cache.txt, guardando ahí cualquier geolocalización de una IP no existente previamente.

# PRÓXIMAS MEJORAS:
* Permitir añadir script a /etc/crontab para la automatización de tareas.
* Detectar posibles servicios en el host para autodetectar qué ficheros de registros monitorizar.
* Añadir la exclusión de IP'S basada en comportamientos (User-Agent, Method, Strings,...)

Cualquier comentario, error o mejora enviadlo a wllop@esat.es. 
Muchas gracias!!
@wllop
