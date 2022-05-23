#!/bin/bash
#set -x
function check_param { #Devuelve 0 si el paso de parámetros al script es correcto.
if [ "$#" == "0" ]; then
  help
fi
for param in $*;do
 case $param in
  "-h") help
  ;;
  "-i") ignora_privadas=1
  ;;
  "-b") firewall=1
        if [ $ip -eq 1 ];then
         help
        fi
        fpais=1
        continue
  ;;
  "-ei") excludeip=1
         fiperm=1
         continue
  ;;
  "-ed") excludedom=1
         fdperm=1
         continue
  ;;
  "-ip") ip=1
         if [ $firewall -eq 1 ];then
            help
         fi
         continue
  ;;
    "-cache") cache=1
         fcache=1
         continue
  ;;
  *) #Fichero
     if [ -f $param ];then #Es un fichero
       if [ "$fpais" == "1" ]; then
          fpais=$param
       elif [ "$fiperm" == "1" ]; then
          fiperm=$param
       elif [ "$fdperm" == "1" ]; then
          fdperm=$param
       elif [ "$fcache" == "1" ]; then
          fcache=$param
       else
          fichero=$param
       fi
     elif [ "$ip" == "1" ]; then
          res=$(check_ip "$param")
          if [ $res -eq 0 ];then 
           ip=$param;
          else
           echo "Compruebe dirección IP"
           exit
          fi
     else
      help
     fi
 esac
done
}

function excluir_ip { #Recibe una IP y el pais y comprueba si debe ser EXCLUIDA del análisis en función de su DNS Inverso
#Variables
#fdperm -->Fichero con dominios a excluir
if [ "$fdperm" != "0" ];then ##Tengo fichero de exclusión de dominios
  dns=$(dig +noall +answer -x $1|tail -1|awk '{print $5}') ##Compruebo el dominio asociado a esa ip.
  #Puesto que quiero buscar como subdominio, lo mejor es buscar del fichero dominios al dominio obtenido así es más fácil--> NO grep www.esat.es esat.es (Daría null) sino grep esat.es www.esat.es (devolvería esat.es)
  if [ "$dns" != "" ];then
    for dominio in $(cat $fdperm);do
      if echo ${dns%.}| grep $dominio;then  ###Comprobar el tema de subdominios, etc... #con ${dns%.} quito el punto final (root) de la consulta dns de dig
        echo 0
      fi
    done
  fi
fi
echo 1
}
function check_ip { #Devuelve 0 si la IP es válida y 1 si NO es válida
IFS_TMP=$IFS
IFS=.
ip_tmp=($1)
if [ "${ip_tmp[0]:=0}" -ge "1" -a "${ip_tmp[0]:=0}" -lt 223 ]; then
 if [ "${ip_tmp[1]:=300}" -ge "0" -a "${ip_tmp[1]:=300}" -le 255 ]; then
   if [ "${ip_tmp[2]:=300}" -ge "0" -a "${ip_tmp[2]:=300}" -le 255 ]; then
     if [ "${ip_tmp[3]:=300}" -ge "0" -a "${ip_tmp[3]:=300}" -le 255 ]; then
       if ! [ "${ip_tmp[1]:=0}" -eq "0" -a "${ip_tmp[2]:=0}" -eq 0 -a "${ip_tmp[3]:=0}" -eq 0 ]; then
         if [ "${ip_tmp[1]:=0}" -ne "255" -a "${ip_tmp[2]:=0}" -ne 255 -a "${ip_tmp[3]:=0}" -ne 255 ]; then
           echo 0
         else
           echo 1
         fi
        else
           echo 1
        fi
      else
           echo 1
      fi
    else
           echo 1
    fi
  else
           echo 1
  fi
else
           echo 1
  fi
  IFS=$IFS_TMP
}

function privada { #Devuelve 1 si la IP es privada
IFS_TMP=$IFS
IFS=.
ip_tmp=($1)
if [ "${ip_tmp[0]}" == "10" -o "${ip_tmp[0]}" == "0" -o "${ip_tmp[0]}" == "127" ]; then
  echo 1
elif [ "${ip_tmp[0]}" == "172" ] && [ "${ip_tmp[1]:=0}" -ge 16 -a "${ip_tmp[1]:=0}" -le 31 ]; then
  echo 1  
elif [ "${ip_tmp[0]}" == "169" -a "${ip_tmp[1]}" == "254" ]; then
  echo 1
elif [ "${ip_tmp[0]}" == "192" ] && "${ip_tmp[1]}" == "168" ] && [ "${ip_tmp[2]:=0}" -ge 0 -a "${ip_tmp[1]:=0}" -le 255 ]; then
  echo 1
else
  echo 0
fi
IFS=$IFS_TMP
}

function geoip { ##Dada una ip indica su país de origen
 if [ "$cache" == "1" ]; then
   $res=$(grep -w "$1" $fcache|cut -d: -f2|tr [:upper:] [:lower:])
   if [ "$res" != "" ];then
      echo $res
   else
      res=$(curl -sf "http://ip-api.com/json/$1"|jq '.country'|tr -d "\""|tr [:upper:] [:lower:])
      echo "$1:$res">>$fcache
      echo $res
   fi
 else
    res=$(curl -sf "http://ip-api.com/json/$1"|jq '.country'|tr -d "\""|tr [:upper:] [:lower:])
    if [ "$cache" == "1" ]; then
      echo "$1:$res">>$fcache  
    fi
    echo $res
 fi
}
function help  {
 echo "$1"
 echo "GEOIP buscará IPs en el fichero pasado como parámetro y las Geolocalizará gracias a ip-api.com"
 echo "-----------------------------------------------------------------------------------------------"
 echo ""
 echo "Sintaxis:"
 echo "geo_ip.sh [-i] [-b <listado_paises>] [-ip X.X.X.X] [-ei <fichero>] [-ed <fichero>]  <fichero_log> "
 echo ""
 echo "[OPCIONAL] Con la opción -i --> Ignoramos la opción de comprobación de IP's PRIVADAS."
 echo "[OPCIONAL] Con la opción -b <listado_países> --> Añadimos una regla de filtrado IPTABLES a las IPs que NO pertenezcan al listado de países indicado en el fichero <países.txt>."
 echo "[OPCIONAL] Con la opción -ip --> Mostramos el país de la IP pasada como parámetro. Debe usarse como parámtro único."
 echo "[OPCIONAL] Con la opción -ei <fichero> --> Excluimos del filtrado a las IPs que aparecen en el fichero pasado como parámetro. Sólo aplica con opción -b"
 echo "[OPCIONAL] Con la opción -ed <fichero> --> Excluimos los dominios/FQDN que aparecen en el fichero pasado como parámetro. Sólo aplica con opción -b"
 echo "[OPCIONAL] Con la opcion -cache <fichero> --> Cachearemos las consultas de IP - País para reducir peticiones a IP-API"
 echo "Ejemplo:"
 echo "--------"
 echo "geo_ip /var/log/auth.log"
 echo "geo_ip -b /home/wllop/listado.txt /var/log/auth.log"
 exit
}

#MAIN()

if ! type jq >/dev/null ;then
   echo "Error:"
   echo "Es necesario instalar el parser de JSON:  jq"
   echo "Pruebe: apt-get install jq"
   echo ""
   exit
fi
##Variables
fpais=0 #Fichero de paises permitidos
fiperm=0 #Fichero de IPs permitidas
fdperm=0 #Fichero de Dominios/FQDN permitidos
ip=0 #Dirección IP a geolocalizar.
cache=0 #Para saber si cacheamos resultados
fcache=0 #Fichero caché
excludedom=0 #Flag parámetro -ed. 
excludeip=0 #Flag parámetro -ei.
firewall=0 #Flag parámetro Firewall.
ignora_privadas=0 #Flag parámetro -i.
fichero=0 #Fichero donde buscar IPs a geolocalizar.
check_param $*

if [ "$ip" != "0" ]; then ## Nos pasan IP
    resp=$(privada $ip)
    if [ "$resp" != "1" ];then #OK
      resp=$(geoip $ip)
      echo "País: $resp"
      exit
    fi
fi

##Exclusión mutua para evitar problemas de concurrencia! http://mywiki.wooledge.org/BashFAQ/045
lockdir=/tmp/$(echo ${fichero}|tr -d /)_tmp.lock
if ! mkdir "$lockdir" 2>/dev/null; then
  exit 0
fi
trap 'rm -rf "$lockdir" 2>/dev/null;rm -rf "$lockiptabledir" 2>/dev/null;rm -fr /tmp/fw$(echo "${fichero}"|tr -d /)_ip 2 >/dev/null' 0

if [ "$fiperm" != "0" ];then ##Tengo fichero de exclusión de IP
  grep -oP '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' $fichero|grep -v -E "0.0.0.0|127.0.0.1" |grep -v -f $fiperm|sort -u >/tmp/fw$(echo ${fichero}|tr -d /)_ip
else
  grep -oP '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' $fichero|grep -v -E "0.0.0.0|127.0.0.1"|sort -u >/tmp/fw$(echo ${fichero}|tr -d /)_ip
fi

#Obtengo IPS en /tmp/fw$(echo ${fichero}|tr -d /)_ip

#Compruebo si hay que implementar las opciones de firewall!
if [ "$fpais" != "0" -a -f $fichero ];then
  ##Para evitar repetir el procesamiento de IPs ya existentes en iptables, hago un fichero de exclusión
  iptables -L -n|grep  -oP "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"| grep -v -E "0.0.0.0|127.0.0.1" |sort -u>/tmp/fw$(echo ${fichero}|tr -d /)_tmp #Obtenemos IPs y volcamos a fichero /tmp/fw$(echo ${fichero}|tr -d /)_tmp
  #Excluyo del fichero de IPs las que ya están en IPTables
  grep -v -f /tmp/fw$(echo ${fichero}|tr -d /)_tmp /tmp/fw$(echo ${fichero}|tr -d /)_ip >/tmp/fw$(echo ${fichero}|tr -d /)_ip2 && mv /tmp/fw$(echo ${fichero}|tr -d /)_ip2 /tmp/fw$(echo ${fichero}|tr -d /)_ip || exit
  rm -fr /tmp/fw$(echo ${fichero}|tr -d /)_tmp
  if [ $(id -u) -ne 0 ];then
     echo "Debe ser administrador para poder utilizar esta opción."
     exit
  fi
  ## Implemento firewall!!
  IFS_old=$IFS
  IFS=$'\n'
  for pais in $(grep -v "#"  $fpais|tr -d \"|tr [:upper:] [:lower:]); do
    for linea in $(cat /tmp/fw$(echo ${fichero}|tr -d /)_ip|tr -d " "); do
      #Comprobamos si la IP debe ser IGNORADA
	resp=$(excluir_ip $linea $pais)
	if [ "$resp" != "1" ];then # Si devuelve 0 pasamos a otra IP
        continue
      fi
      resp=""
      res=""
      if [ $ignora_privadas -eq 1 ]; then
       resp=$(privada $linea)
      fi
      if [ "$resp" != "1" ]; then
        while [ "$res" == "" ];do
	res=$(geoip $linea)
	sleep 1
        done
        if [ "$res" != "$pais" ] && [ "$pais" != "test" ]; then
        ##Exclusión mutua para evitar xtables lock...la opción -w no funciona del todo bien
          lockiptabledir=/tmp/iptables.lock
          while ! mkdir "$lockiptabledir" 2>/dev/null; do
           sleep ${RANDOM:0:1}
          done
          iptables -L INPUT -n|grep $linea >/dev/null ||  iptables -w 1 -A INPUT -s $linea -j DROP 2>/dev/null
          rm -rf "$lockiptabledir"
        fi
      fi
    done
  done
elif [ -f $fichero ]; then ##SIn firewall!! Sólo informativo
    for linea in $(cat /tmp/fw$(echo ${fichero}|tr -d /)_ip); do
      if [ "$ignora_privadas" == "0" ]; then
       resp=$(privada $linea)
      fi
      if [ "$resp" != "1" ]; then
        while [ "$res" == "" ];do
          res=$(geoip $linea)
          sleep 1
        done
      echo "IP:$linea - Country:$res"
      if [ -f $fcache ]; then #Cacheamos resultado para más tarde.
        echo "$linea:$res">>$fcache
      fi
      res=""
      fi
    done
fi
IFS=$IFS_old
exit
