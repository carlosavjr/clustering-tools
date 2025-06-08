#!/bin/bash
echo ""
echo "########################################"
echo  "ACESSAR NODOS GTCMC "
echo "########################################"


echo ''
echo 'Install :'
echo ''
echo ""


if [[ -z "$1" || -z "$2" ]] ; then
 echo 'uso: ./d_nfsreload.sh 0X Y'
 echo 'exemplo: ./d_nfsreload.sh 02 17'
 exit 1
fi

 echo "Intervalo de instalacao selecionado"
 echo $1 'até' $2

 echo ''
 echo 'Update nfs:'
 echo ''
 echo ""


for i in `eval echo {$1..$2}`


do
if ping -c 1 nodo$i > /dev/null
then 
  echo "Echo INSTALL Nodo $i cpu:"
  echo ''
   
  ssh nodo$i "

  ./admin_mode.sh
  sudo mount -a

  "

  echo ''
else
    # 100% failed
echo "Host : nodo$i is down at $(date)"
echo ''
fi
done

echo "END CLUSTER INSTALL." 

