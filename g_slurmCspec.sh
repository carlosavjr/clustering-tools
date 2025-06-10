#!/bin/bash
echo ""
echo "########################################"
echo  "CHECAR SPECS NODOS "
echo "########################################"


echo ''
echo 'Atualizando list_specs:'
echo ''
echo ""

rm ~/list_specs

for i in {02..14}
do
if ping -c 1 nodo$i > /dev/null
then 
  echo "Spec Nodo $i cpu:"
  echo ''
   ssh nodo$i "slurmd -C >> list_specs"
  echo ''
else
    # 100% failed
echo "Host : nodo$i is down at $(date)"
echo ''
fi
done

echo "Verificar arquivo list_specs" 

