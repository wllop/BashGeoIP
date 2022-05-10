#!/bin/bash
#set -x

function check_ip { #Devuelve 0 si la IP es válida y 1 si NO es válida
IFS_TMP=$IFS
IFS=.
ip=($1)
if [ "${ip[0]:=0}" -ge "1" -a "${ip[0]:=0}" -lt 223 ]; then
 if [ "${ip[1]:=300}" -ge "0" -a "${ip[1]:=300}" -le 255 ]; then
   if [ "${ip[2]:=300}" -ge "0" -a "${ip[2]:=300}" -le 255 ]; then
     if [ "${ip[3]:=300}" -ge "0" -a "${ip[3]:=300}" -le 255 ]; then
       if ! [ "${ip[1]:=0}" -eq "0" -a "${ip[2]:=0}" -eq 0 -a "${ip[3]:=0}" -eq 0 ]; then
         if [ "${ip[1]:=0}" -ne "255" -a "${ip[2]:=0}" -ne 255 -a "${ip[3]:=0}" -ne 255 ]; then
           echo 0
           exit
         else
           echo 1
           exit
         fi
        else
           echo 1
           exit
        fi
      else
           echo 1
           exit
         
      fi
    else
           echo 1
           exit
         
    fi
  else
           echo 1
           exit
         
  fi
else
           echo 1
           exit
         
fi
IFS=$IFS_TMP
}

function privada { #Devuelve 1 si la IP es privada
IFS_TMP=$IFS
IFS=.
ip=($1)
if [ "${ip[0]}" == "10" -o "${ip[0]}" == "0" -o "${ip[0]}" == "127" ]; then
  echo 1
elif [ "${ip[0]}" == "172" ] && [ "${ip[1]:=0}" -ge 16 -a "${ip[1]:=0}" -le 31 ]; then
  echo 1  
elif [ "${ip[0]}" == "169" -a "${ip[1]}" == "254" ]; then
  echo 1
elif [ "${ip[0]}" == "192" ] && "${ip[1]}" == "168" ] && [ "${ip[2]:=0}" -ge 0 -a "${ip[1]:=0}" -le 255 ]; then
  echo 1
fi
IFS=$IFS_TMP
}

function geoip { ##Dada una ip indica su país de origen
 res=$(curl -sf "http://ip-api.com/json/$1"|jq '.country'|tr -d "\""|tr [:upper:] [:lower:]) 
 echo $res   
}
function help  {
 echo "$1"
 echo "GEOIP buscará IPs en el fichero pasado como parámetro y las Geolocalizarán gracias a ip-api.com"
 echo "Sintaxis:"
 echo "geo_ip.sh [-i] [-b <listado_paises>] [-ip X.X.X.X] <fichero> "
 echo "[OPCIONAL] Con la opción -i --> Ignoramos la opción de comprobación de IP's PRIVADAS."
 echo "[OPCIONAL] Con la opción -b <listado_países> --> Añade una regla IPTABLES a las IP's que pertenezcan al listado de países indicado en el fichero <listado_países>"
 echo "[OPCIONAL] Con la opción -ip --> Mostramos el país de la IP pasada como parámetro. NO debe usarse junto con -i o -b"
 echo "Ejemplo:"
 echo "geo_ip /var/log/auth.log"
 echo "geo_ip -b /home/wllop/listado.txt /var/log/auth.log"
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
ignora_privadas=0
if [ "$1" == "-i" ]; then
   ignora_privadas=1
   shift
fi

if [ "$1" == "-ip" ]; then ## Nos pasan IP
   resp=$(check_ip $2)
   if [ "$resp" == "0" ];then #OK
    resp=$(privada $2)
    if [ "$resp" != "1" ];then #OK
      resp=$(geoip $2)
      echo "País: $resp"
      exit
    fi
   fi
      help "Compruebe dirección IP"   
fi

#Compruebo si hay que implementar las opciones de firewall!
if [ "$1" == "-b" ];then
  if [ $(id -u) -ne 0 ];then
     echo "Debe ser administrador para poder utilizar esta opción."
     exit
  fi
  if [ $# -le 2 ]; then #Compruebo parámetros
    help
  fi
  firewall=1
  shift  
  if ! [ -f $1 ];then
   echo "Error:"
   echo "El fichero $1 NO EXISTE"
   exit
  fi
  fich_pais=$1
  shift
else #Se realizan geolocalizaciones sin actualizar iptables.
  echo test>/tmp/geo
  fich_pais=/tmp/geo
fi

if [ "$1" == "-i" ]; then #Ignorar IPs privadas (Lo "normal" en servidores en Internet).
   ignora_privadas=1
   shift
fi

if [ "$1" == "" ];then
   help
fi
if ! [ -f $1 ];then
   echo "Error:"
   echo "El fichero $1 NO EXISTE"
   exit
fi

IFS_old=$IFS
IFS=$'\n'
for pais in $(cat $fich_pais|tr -d \"|tr [:upper:] [:lower:]); do
 for linea in $(egrep -o "\b[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\b" $1|sort -n|uniq); do
  if [ $ignora_privadas -eq 0 ]; then
   resp=$(privada $linea)
  fi
  if [ "$resp" != "1" ]; then
   while [ "$res" == "" ];do
     res=$(curl -sf "http://ip-api.com/json/$linea"|jq '.country'|tr -d "\""|tr [:upper:] [:lower:])
    sleep 1
   done
   if [ "$res" != "$pais" ] && [ "$pais" != "test" ]; then
     iptables -L INPUT -n|grep $linea >/dev/null ||  iptables -w 5 -A INPUT -s $linea -j DROP 2>/dev/null
   elif [ "$pais" == "test" ];then
    echo IP:$linea - Country:$res
   fi
  fi
 IFS=$IFS_TMP
 res=""
 done
done
IFS=$IFS_old
