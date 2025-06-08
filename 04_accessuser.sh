#!/bin/bash
echo ""
echo "########################################"
echo  "ACESSAR NODOS GTCMC "
echo "########################################"


echo ''
echo 'Instalar sem senha:'
echo ''
echo ""

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

for i in {17..17}
do
if ping -c 1 nodo$i > /dev/null;
then 
  echo "Echo ssh-copy-id Nodo $i cpu:";
  echo 'user$n';
  echo '$n';

  sshpass -p pwd/pass_file$j ssh-copy-id -o StrictHostKeychecking=no user$n@nodo$i;

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

