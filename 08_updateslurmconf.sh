#!/bin/bash
echo ""
echo "########################################"
echo  "Instalar SLURM nos NODOS GTCMC "
echo "########################################"


echo ''
echo 'Atualizar SLURM config <CONTROLLER>:'
echo ''
echo ""

 sn="02";
 en="14";

 echo "Intervalo de instalação selecionado"
 echo $sn 'até' $en

# exit 1;


~/admin_mode.sh;
cd slurm.config/;
sudo cp /etc/slurm-llnl/slurm.conf /etc/slurm-llnl/slurm.conf.bak;
sudo cp slurm.conf /etc/slurm-llnl/
./slurm-controller;

 echo ''
 echo 'Configurando SLURM:'
 echo ''
 echo ""

for i in `eval echo {$sn..$en}`
do
if ping -c 1 nodo$i > /dev/null
then 
  echo "Atualizar SLURM config <WORKER> Nodo $i cpu:"
  echo ''
  ssh -t nodo$i "

~/admin_mode.sh;

cd slurm.config/; 
sudo cp slurm.conf /etc/slurm-llnl/;

./slurm-worker

"
  echo 'finalizando'

pwd

else
    # 100% failed
echo "Host : nodo$i is down at $(date)"
echo ''
fi
done

echo "END update slurm.conf" 

