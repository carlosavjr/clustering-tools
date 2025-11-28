#!/bin/bash
echo ""
echo "########################################"
echo  "Instalar SLURM nos NODOS GTCMC "
echo "########################################"


echo ''
echo 'Atualizar SLURM config <CONTROLLER>:'
echo ''
echo ""


if [[ -z "$1" || -z "$2" ]] ; then
 echo 'uso: ./08_updateslurmconf.sh 0X Y (X,Y intervalo de 02 até N inteiro de 2 dígitos)'
 exit 1
fi


 echo "Intervalo de instalação selecionado"
 echo $1 'até' $2

 echo ''
 echo 'update slurm.conf :'
 echo ''
 echo ""

 #sn="02";
 #en="17";

 echo "Intervalo de instalação selecionado"
 echo $1 'até' $2

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

for i in `eval echo {$1..$2}`
#for i in `eval echo {$sn..$en}`

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

