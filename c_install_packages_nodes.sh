#!/bin/bash

echo ""
echo "########################################"
echo "Instalar pacotes nos NODOS GTCMC"
echo "########################################"
echo ""

# Check for minimum arguments
if [[ $# -lt 3 ]]; then
    echo "Uso: ./c_install_package.sh <inicio_intervalo> <fim_intervalo> <pacote1> [pacote2] [pacote3] ..."
    echo "Exemplo: ./c_install_package.sh 02 15 build-essential htop nmon"
    exit 1
fi

# Extract arguments
start_node=$1
end_node=$2
shift 2  # Remove the first two arguments
packages=("$@")  # Remaining arguments are packages

echo "Intervalo de instalação selecionado: nodo$start_node até nodo$end_node"
echo "Pacotes selecionados: ${packages[@]}"
echo ""

# Verify node range format
if ! [[ $start_node =~ ^[0-9]+$ ]] || ! [[ $end_node =~ ^[0-9]+$ ]]; then
    echo "Erro: O intervalo deve conter apenas números"
    echo "Exemplo correto: ./c_install_package.sh 02 15 pacote1 pacote2"
    exit 1
fi

if [ $start_node -gt $end_node ]; then
    echo "Erro: O primeiro número deve ser menor ou igual ao segundo"
    exit 1
fi

echo "Iniciando instalação..."
echo ""

success_count=0
fail_count=0
failed_nodes=()

for i in $(seq -w $start_node $end_node); do
    node="nodo$i"
    
    if ping -c 1 -W 1 $node > /dev/null 2>&1; then
        echo "========================================"
        echo "Instalando em $node..."
        echo "========================================"
        
        # Join packages with spaces for the install command
        package_list="${packages[@]}"
        
        # SSH command with all package installations
        if ssh -t $node "
            ./admin_mode.sh;
            sudo apt-get update;
            sudo apt --fix-broken install -y;
            sudo apt-get install -y $package_list;
            echo '';
            echo 'Pacotes instalados com sucesso em $node';
            " 2>&1; then
            
            ((success_count++))
            echo "SUCESSO: $node"
        else
            ((fail_count++))
            failed_nodes+=("$node")
            echo "FALHA: $node"
        fi
    else
        ((fail_count++))
        failed_nodes+=("$node")
        echo "Host $node está offline - $(date)"
    fi
    
    echo ""
done

echo "========================================"
echo "RESUMO DA INSTALAÇÃO"
echo "========================================"
echo "Nós com sucesso: $success_count"
echo "Nós com falha: $fail_count"

if [ $fail_count -gt 0 ]; then
    echo ""
    echo "Nós que falharam:"
    printf '%s\n' "${failed_nodes[@]}"
fi

echo ""
echo "INSTALAÇÃO NO CLUSTER CONCLUÍDA."
