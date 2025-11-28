#!/bin/bash
echo ""
echo "########################################"
echo  "ACESSAR NODOS GTCMC "
echo "########################################"

if [[ -z "$1" || -z "$2" ]] ; then
 echo 'uso: ./installintel.sh 0X Y (X,Y intervalo de 02 até N inteiro de 2 dígitos)'
 exit 1
fi


 echo "Intervalo de instalação selecionado"
 echo $1 'até' $2



 echo ''
 echo 'Install intel :'
 echo ''
 echo ""


  if [ -d /opt/intel/oneapi/oneapi-hpc-toolkit ]
  then

        echo "intel instalado no servidor"

  else

    sudo apt update;
    sudo apt install -y gpg-agent wget;

   # download the key to system keyring
   wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | gpg --dearmor | sudo tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null;
#   wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | gpg --dearmor | sudo tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null

   # add signed entry to apt sources and configure the APT client to use Intel repository:
   echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" | sudo tee /etc/apt/sources.list.d/oneAPI.list;
#   echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" | sudo tee /etc/apt/sources.list.d/oneAPI.list
    sudo apt-get update -y;
    sudo apt-get install intel-oneapi-hpc-toolkit -y;

  fi



 for i in `eval echo {$1..$2}`
 do
  if ping -c 1 nodo$i > /dev/null
  then 
  echo "Echo INSTALL Nodo $i cpu:"
  echo ''

  ssh -t nodo$i "

 if [ -d /opt/intel/oneapi/oneapi-hpc-toolkit ]
  then

    echo "intel instalado"

  else

   if ping -c 1 www.google.com > /dev/null
   then
    ./admin_mode.sh
    echo 'atualizando apt'

    sudo apt update;
    sudo apt install -y gpg-agent wget;

   # download the key to system keyring
   wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | gpg --dearmor | sudo tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null

   # add signed entry to apt sources and configure the APT client to use Intel repository:
   echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" | sudo tee /etc/apt/sources.list.d/oneAPI.list
    sudo apt-get update -y;
    sudo apt-get install intel-oneapi-hpc-toolkit -y;

   else

     echo 'sem internet no nodo';

   fi
 fi
"

  echo ''
 else
    # 100% failed
  echo "Host : nodo$i is down at $(date)"
  echo ''
 fi
done

echo "END CLUSTER INSTALL."
