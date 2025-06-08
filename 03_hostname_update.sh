#!/bin/bash
echo ""
echo "########################################"
echo  "Atualizar hostname nos NODOS GTCMC "
echo "########################################"

echo ''
echo 'Atualizar hostname:'
echo ''
echo ""

if [[ -z "$1" || -z "$2" ]] ; then
 echo 'uso: ./03_hostname_update.sh 0X Y (X,Y intervalo de 02 até N inteiro de 2 dígitos)'
 exit 1
fi

 echo "Intervalo de instalação selecionado"
 echo $1 'até' $2
 
for i in `eval echo {$1..$2}`

do
if ping -c 1 nodo$i > /dev/null
then 
  echo "Echo update Nodo $i cpu:"
  echo ''

  ssh -t nodo$i "

  ./admin_mode.sh

  sudo hostnamectl set-hostname nodo$i
  hostname

"
  echo ''

else
    # 100% failed
echo "Host : nodo$i is down at $(date)"
echo ''
fi
done

echo "END CLUSTER UPDATE."
