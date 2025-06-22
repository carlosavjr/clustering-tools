#!/bin/bash
echo ""
echo "########################################"
echo  "ACESSAR NODOS GTCMC "
echo "########################################"


echo ''
echo 'Teste ethernet nodos :'
echo ''
echo ""

for i in {03..17}
do
if ping -c 1 nodo$i > /dev/null
then 
  echo "Ping Nodo $i cpu:"
  echo ''
#  scp -r intel/ nodo$i:
  ssh nodo$i "ping -c 1 www.google.com"

  echo ''
else
    # 100% failed
echo "Host : nodo$i is down at $(date)"
echo ''
fi
done

echo "END CLUSTER INSTALL." 

