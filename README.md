#BashGeoIP
#BashGeoIP permite Geolocalizar las distintas IP's existentes en el fichero pasado como parámetro.

USO:
geo_ip.sh <fichero>

OPCIONES:
-h --> Muestra ayuda del comando.

CARACTERÍSTICAS:
* Filtra las direcciones PRIVADAS o ESPECIALES (Loopback, 0.0.0.0)
* Evita IP's duplicadas.

DEPENDENCIAS:
* BashGeoIP necesita de jq como parser JSON para gestionar el JSON devuelto por http://ip-api.com/.
* Hace uso del servicio de Geolocalización de IP de http://ip-api.com/.

Cualquier comentario, error o mejora enviadlo a wllop@esat.es. 
Muchas gracias!!
@wllop