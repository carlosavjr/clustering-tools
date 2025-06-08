#!/bin/bash
echo ""
echo "########################################"
echo  "SEM SENHA ADMIN GTCMC "
echo "########################################"

echo ''
echo 'Configurar acesso sem senha (admin):'
echo 'criar chave:'
echo ""


if [[ -z "$1" || -z "$2" ]] ; then
 echo 'uso: ./02_accessadmin.sh 0X Y (X,Y intervalo de 02 até N inteiro de 2 dígitos)'
 echo 'exemplo: ./02_accessadmin.sh 02 17'
 exit 1
fi

 echo "Intervalo de instalação selecionado"
 echo $1 'até' $2

 echo ''
 echo 'Install package:'
 echo ''
 echo ""

ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa <<< y

for i in `eval echo {$1..$2}`
do

echo "administrador" 

if ping -c 1 nodo$i > /dev/null
then 
  echo "ssh-copy-id Nodo $i cpu:"
  sshpass -p $(cat pwd.txt) ssh-copy-id -o StrictHostKeychecking=no  administrador@nodo$i
  echo ''
else
    # 100% failed
echo "Host : nodo$i is down at $(date)"
echo ''
fi
done

echo "END ADMIN INSTALL." 
