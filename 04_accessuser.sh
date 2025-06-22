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

#sshpass -p "pwd@gtcmc$j" ssh user$j@cluster '

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
  echo 'pwd@gtcmc$n';
  echo '$n';

  sshpass -p "pwd@gtcmc$n" ssh-copy-id -o StrictHostKeychecking=no user$n@nodo$i;

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

