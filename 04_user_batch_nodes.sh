#!/bin/bash
echo ""
echo "########################################"
echo  "Adicionar usuários nos NODOS CLUSTER "
echo "########################################"

echo ''
echo 'Adição usuários:'
echo ''
echo ""

if [[ -z "$1" || -z "$2" ]] ; then
 echo 'uso: ./04_user_batch_nodes.sh 0X Y (X,Y intervalo de 02 até N inteiro de 2 dígitos)'
 exit 1
fi

 echo "Intervalo de instalação selecionado"
 echo $1 'até' $2


# --- FIX START ---
# Check if new_users.txt exists and is readable
if [ ! -f "new_users.txt" ]; then
  echo "Error: new_users.txt not found in the current directory."
  echo "Please create new_users.txt with user:password entries."
  exit 1
fi

echo "reconfigurando senhas do servidor";

sudo newusers new_users.txt;
sudo chpasswd < newpass.txt;

 
for i in `eval echo {$1..$2}`

do
if ping -c 1 nodo$i > /dev/null
then 
  echo "Echo update Nodo $i cpu:"
  echo ''

  ssh -t nodo$i "

  ./admin_mode.sh;


        sudo newusers new_users.txt;
        sudo chpasswd < newpass.txt
 
"
  echo ''

else
    # 100% failed
echo "Host : nodo$i is down at $(date)"
echo ''
fi
done

echo "END CLUSTER UPDATE."
