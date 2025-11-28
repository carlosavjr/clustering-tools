#!/bin/bash
echo ""
echo "########################################"
echo  "Instalar SLURM nos NODOS GTCMC "
echo "########################################"


echo ''
echo 'Install SLURM:'
echo ''
echo ""



if [[ -z "$1" || -z "$2" ]] ; then
 echo 'uso: ./07_install_slurm-wlm.sh 0X Y'
 echo 'exemplo: ./07_install_slurm-wlm.sh 14 17'
 exit 1
fi

 echo "Intervalo de instalação selecionado"
 echo $1 'até' $2

 echo ''
 echo 'Configurando SLURM:'
 echo ''
 echo ""

echo "instalandos slurm no servidor"

sudo apt update -y;
sudo apt install slurm-wlm -y;

for i in `eval echo {$1..$2}`
do
if ping -c 1 nodo$i > /dev/null
then 
  echo "INSTALL SLURM-WLM Nodo $i cpu:"
  echo ''

  ssh -t nodo$i "

~/admin_mode.sh;
cd slurm-wlm/; 

pwd;

   echo "Checando conectividade da internet..."
   if ping -c 1 www.google.com > /dev/null; then
    echo "Conexao detectada. Continuando"

    sudo apt update -y;
    sudo apt install slurm-wlm -y;

   else
    echo "Sem internet. Instalando deb local na pasta slurm-wlm.";
    sudo dpkg -i *.deb;
  fi

sudo cp cgroup.conf /etc/slurm-llnl/;

./slurm-worker;


"
  echo ''

else
    # 100% failed
echo "Host : nodo$i is down at $(date)"
echo ''
fi
done

echo "END CLUSTER INSTALL." 

