#!/bin/bash
echo ""
echo "########################################"
echo  "Instalar SLURM nos NODOS "
echo "########################################"


echo ''
echo 'Install Munge SLURM:'
echo ''
echo ""


if [[ -z "$1" || -z "$2" ]] ; then
 echo 'uso: ./06_install_munge.sh 0X Y'
 echo 'exemplo: ./06_install_munge.sh 14 17'
 exit 1
fi

 echo "Intervalo de instalação selecionado"
 echo $1 'até' $2

 echo ''
 echo 'Configurando MUNGE:'
 echo ''
 echo ""

for i in `eval echo {$1..$2}`
do
if ping -c 1 nodo$i > /dev/null
then 
  echo "INSTALL munge Nodo $i cpu:"
  echo ''

  ssh -t nodo$i "

  ./admin_mode.sh;

   cd slurm/; 

   pwd;

   echo "Checando conectividade da internet..."
   if ping -c 1 www.google.com > /dev/null; then
    echo "Conexao detectada. Continuando"

    sudo apt update;
    sudo apt install munge libmunge2 libmunge-dev;

   else
    echo "Sem internet. Instalando deb local na pasta slurm.";
    sudo dpkg -i *.deb;
#  exit 1 # Exit the script with an error code
  fi

  munge -n | unmunge | grep STATUS;

  sudo cp /etc/munge/munge.key /etc/munge/munge.key.bak;

  sudo cp munge.key /etc/munge/;

  sudo ./permissions;
 
  sudo systemctl enable munge

  sudo systemctl restart munge

"
else
    # 100% failed
echo "Host : nodo$i is down at $(date)"
echo ''
fi
done
