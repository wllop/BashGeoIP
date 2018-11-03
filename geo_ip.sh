#!/bin/bash
help()
{
 echo ""
 echo "GEOIP buscará IPs en el fichero pasado como parámetro y las Geolocalizarán gracias a ip-api.com"
 echo "Sintaxis:"
 echo "geo_ip.sh <fichero>"
 echo "Ejemplo:"
 echo "geo_ip /var/log/auth.log"
 exit
}

if ! type jq >/dev/null ;then
   echo "Error:"
   echo "Es necesario instalar el parser de JSON:  jq"
   echo "Pruebe: apt-get install jq"
   echo ""
   exit
fi

if [ "$1" == "-h" ]; then
  help
fi

if [ "$#" == "0" ]; then
  help
fi
if ! [ -f $1 ];then
   echo "Error:"
   echo "El fichero $1 NO EXISTE"
   exit
fi

IFS_old=$IFS
IFS=$'\n'
for linea in $(egrep -o "\b[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\b" $1|sort -n|uniq); do
IFS_TMP=$IFS
IFS=.
echo -n "-- $linea --"
ip=($linea)
if [ "${ip[0]}" == "10" -o "${ip[0]}" == "0" -o "${ip[0]}" == "127" ]; then
  echo PRIVADA  
  continue
elif [ "${ip[0]}" == "172" ] && [ ${ip[1]} -ge 16 -a ${ip[1]} -le 31 ]; then
  echo PRIVADA  
  continue
elif [ "${ip[0]}" == "169" -a "${ip[1]}" == "254" ]; then
  echo "PRIVADA"
  continue
elif [ "${ip[0]}" == "192" ] && "${ip[1]}" == "168" ] && [ ${ip[2]} -ge 0 -a ${ip[1]} -le 255 ]; then
  echo PRIVADA 
  continue
else
res=$(curl -sf "http://ip-api.com/json/$linea"|jq '.country')
echo "($res)"
fi
IFS=$IFS_TMP
done
IFS=$IFS_old
