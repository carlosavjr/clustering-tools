#!/bin/bash
echo ""
echo "########################################"
echo  "ACESSAR NODOS GTCMC "
echo "########################################"


echo ''
echo 'Instalar sem senha:'
echo ''
echo ""

if [[ -z "$1" || -z "$2" ]] ; then
 echo 'uso: ./05_accessuser.sh 0X Y (X,Y intervalo de 02 até N inteiro de 2 dígitos)'
 exit 1
fi


echo "Intervalo de instalação selecionado"
echo $1 'até' $2

for j in {01..30}
do

echo "user$j"

sshpass -f pwd/pass_file$j ssh user$j@cluster '

echo 'criar chave';
echo "";

hostname;

ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa <<< y;

echo '$j'

n='$j'

for i in `eval echo {$1..$2}`
do
if ping -c 1 nodo$i > /dev/null;
then 
  echo "Echo ssh-copy-id Nodo $i cpu:";
  echo 'user$n';
  
  sshpass -p "XXXXXXXX" ssh-copy-id -o StrictHostKeychecking=no user$n@nodo$i;

  echo '';
else
#    # 100% failed
echo 'Host : nodo$i is down at $(date)';
echo '';
fi
done

'

done

echo "END CLUSTER INSTALL." 

