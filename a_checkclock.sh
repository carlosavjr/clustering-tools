#!/bin/bash
echo ""
echo "########################################"
echo  "Instalar Openmpi nos NODOS GTCMC "
echo "########################################"


echo ''
echo 'Correct clocks:'
echo ''
echo ""

d=$(date +"%Y-%m-%d %H:%M")

#d=$(date)

echo "$d"

for i in {02..17}
do


if ping -c 1 nodo$i > /dev/null
then 
  echo "clock sync Nodo $i cpu:"
  echo ''

  ssh nodo$i "echo $(date +"%Y-%m-%d %H:%M")"

  echo ''
else
    # 100% failed
echo "Host : nodo$i is down at $(date)"
echo ''
fi
done

echo "END CLUSTER INSTALL." 

