#!/bin/bash
if [[ -z "$1" || -z "$2" ]] ; then
 echo 'uso: ./resumepartition 0X Y'
 echo 'Exemplo: ./resumepartition 02 03'
 exit 1
fi


 echo "Retornando cpus"
 echo $1 'até' $2

./admin_mode.sh;
sudo scontrol update NodeName=nodo[$1-$2] State=down Reason=hung_proc


