#!/bin/bash
echo ""
echo "########################################"
echo  "HABILITAR LM-SENSORS CLUSTER"
echo "########################################"


echo ''
echo 'Instalando :'
echo ''
echo ""


if [[ -z "$1" || -z "$2" ]] ; then
 echo 'uso: ./e_installsensor.sh 0X Y'
 echo 'exemplo: ./e_installsensor.sh 09 17'
 exit 1
fi
 echo "Intervalo de instalação selecionado"
 echo $1 'até' $2

 echo ''
 echo 'Habilitar lm-sensors:'
 echo ''
 echo ""

for i in `eval echo {$1..$2}`

do
if ping -c 1 nodo$i > /dev/null
then 
  
  echo "setup lm-sensors in Nodo $i:"
  echo ''

  ssh -t nodo$i "

  ./admin_mode.sh;
  sudo sensors-detect --auto

  "
  echo ''

else
    # 100% failed
echo "Host : nodo$i is down at $(date)"
echo ''
fi
done

echo "END CLUSTER INSTALL." 

