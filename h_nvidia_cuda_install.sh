#!/bin/bash
echo ""
echo "########################################"
echo "ACESSAR NODOS GTCMC "
echo "########################################"

# Verifica se os argumentos foram fornecidos
if [[ -z "$1" || -z "$2" ]] ; then
    echo 'uso: ./g_nvidiainstall.sh 0X Y (X,Y intervalo de 02 até N inteiro de 2 dígitos)'
    exit 1
fi

echo "Intervalo de instalação selecionado"
echo "$1 até $2" # Aspas duplas para segurança, evita problemas com espaços

echo ''
echo 'Install Intel :' # Corrigi para "Intel"
echo ''
echo ""

# Loop através do intervalo de nós
for i in $(eval echo "{$1..$2}") # Uso de $(...) para substituição de comando, mais moderno que ` `
do
    # Verifica se o nó está acessível por ping
    if ping -c 1 nodo$i > /dev/null # Aspas duplas para segurança
    then
        echo "Echo INSTALL Nodo $i cpu:"
        echo ''

        # Executa comandos remotamente via SSH
        # Usamos um 'here-document' com 'EOF' entre aspas simples para evitar problemas de quoting locais
        # e permitir que o bash remoto interprete o script como está.
        ssh -t nodo$i '

#bash << 'EOF'
            # Verifica a presença de uma placa NVIDIA VGA usando o código de saída do grep -q (quiet)
            # Adicionado o segundo grep para filtrar especificamente por "VGA compatible controller"
            if lspci | grep -i nvidia | grep -i "VGA compatible controller"; then
                if [ -d /opt/nvidia ]; then
                    echo "nvidia instalado"
                else
                    # Verifica conectividade de rede no nó remoto
                    if ping -c 1 www.google.com > /dev/null; then
                        ./admin_mode.sh # Certifique-se que este script existe no nó remoto
                        echo "atualizando apt"
                        sudo apt update
                        sudo apt install -y gpg-agent wget environment-modules

                        # Descarrega a chave para o keyring do sistema usando curl
                        wget -O- https://developer.download.nvidia.com/hpc-sdk/ubuntu/DEB-GPG-KEY-NVIDIA-HPC-SDK | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/nvidia-hpcsdk-archive-keyring.gpg

                        # Adiciona a entrada assinada às fontes apt e configura o cliente APT para usar o repositório nvidia:
                        echo 'deb [signed-by=/usr/share/keyrings/nvidia-hpcsdk-archive-keyring.gpg] https://developer.download.nvidia.com/hpc-sdk/ubuntu/amd64 /' | sudo tee /etc/apt/sources.list.d/nvhpc.list
                        sudo apt-get update -y;

			if [ -e nvidia_deb/nvhpc-25-5_25.5-0_amd64.deb ]
			then
			    echo "copiando nvhpc local";
			    sudo cp nvidia_deb/nvhpc-25-5_25.5-0_amd64.deb /var/cache/apt/archives;
			else
			    echo "baixando nvhpc do apt";
			fi

                        sudo apt-get install -y nvhpc-25-5
                    else
                        echo "Nó remoto sem rede." # Não podemos usar $i aqui, pois é uma variável local do script principal
                        exit 1
                    fi
                fi
            else
                echo "Nó remoto sem placa NVIDIA VGA." # Mensagem atualizada para refletir a verificação VGA
            fi
#EOF

'
        echo ''
    else
        # 100% falha
        echo "Host : nodo$i está offline em $(date)"
        echo ''
    fi
done
echo "INSTALAÇÃO DO CLUSTER CONCLUÍDA."
