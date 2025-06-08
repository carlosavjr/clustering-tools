#!/bin/bash
echo ""
echo "########################################"
echo  "ACESSAR NODOS GTCMC "
echo "########################################"


echo ''
echo 'Disable gui:'
echo ''
echo ""


if [[ -z "$1" || -z "$2" ]] ; then
 echo 'uso: ./b_disable_gui.sh 0X Y'
 echo 'exemplo: ./b_disable_gui.sh 14 17'
 exit 1
fi


 echo "Intervalo de instalação selecionado"
 echo $1 'até' $2



 echo ''
 echo 'Disable gui:'
 echo ''
 echo ""

#for i in {2..13}
for i in `eval echo {$1..$2}`
 do
  if ping -c 1 nodo$i > /dev/null
  then 
  echo "Echo INSTALL Nodo $i cpu:"
  echo ''

  ssh -t nodo$i "

  ./admin_mode.sh;
  sudo systemctl set-default multi-user

  echo 'modo multi-user ativado'

"

  echo ''
else
    # 100% failed
echo "Host : nodo$i is down at $(date)"
echo ''
fi
done

echo "END CLUSTER CONFIG." 

