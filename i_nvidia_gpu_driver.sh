#!/bin/bash
echo ""
echo "########################################"
echo  "Instalar Openmpi nos NODOS GTCMC "
echo "########################################"


echo ''
echo 'Install Openmpi:'
echo ''
echo ""



if [[ -z "$1" || -z "$2" ]] ; then
 echo 'uso: ./i_nvidia_gpu_driver.sh 0X Y (X,Y intervalo de 02 até N inteiro de 2 dígitos)'
 exit 1
fi


 echo "Intervalo de instalação selecionado"
 echo $1 'até' $2



 echo ''
 echo 'Install nvidia driver:'
 echo ''
 echo ""
 
 #for i in {2..13}
for i in `eval echo {$1..$2}`

do
if ping -c 1 nodo$i > /dev/null
then 
  echo "Echo INSTALL Nodo $i cpu:"
  echo ''

  ssh -t nodo$i "


~/admin_mode.sh;
sudo apt-get remove --purge '^nvidia-.*' -y;
sudo apt install nvidia-driver-570-open -y;
sudo apt install nvidia-cuda-toolkit -y

"

  echo ''
else
    # 100% failed
echo "Host : nodo$i is down at $(date)"
echo ''
fi
done

echo "END CLUSTER INSTALL." 

