#!/bin/bash
#
# ping_local.sh
# Este script realiza um teste de ping local nos nós de um cluster,
# dentro de um intervalo especificado de nós. Ele coleta informações
# de tempo de resposta e perda de pacotes.
#

echo ""
echo "########################################"
echo "RELATÓRIO PING NODOS GTCMC "
echo "########################################"


echo ''
echo 'Teste ethernet nodos na data e hora:'
echo ''
date "+%H:%M:%S %d/%m/%y"
echo ""

echo "TR: tempo de resposta"
echo "Perda Pac: perda de pacotes"

echo ""

# Verifica se os argumentos NODES_START e NODES_END foram fornecidos
if [[ -z "$1" || -z "$2" ]] ; then
    echo 'Uso: ./ping_local.sh START_NODO END_NODO'
    echo 'Exemplo: ./ping_local.sh 02 17'
    exit 1
fi

NODES_START="$1"
NODES_END="$2"

# Função para coletar informações de um nó
get_node_info() {
    local node=$1
    # Usa aspas duplas em torno de $node para lidar com possíveis strings vazias ou espaços
    if ping -c 1 "$node" > /dev/null; then
        echo "=== $node ==="
        # Usa aspas duplas em torno de $node
        ping -c 1 "$node" | awk -F'[ =]' '/tempo=/{print "TR: "$11" ms";} /perda de pacote/{print "Perda Pac.: "$6;}'
    else
        echo "=== $node ==="
        echo "status: down "
        date "+%H:%M:%S %d/%m"
    fi
}

# Lista de nós (agora baseada nos argumentos de entrada)
nodes=($(seq -w "$NODES_START" "$NODES_END"))

# Loop para processar os nós em grupos de 3 para exibição lado a lado
for ((i = 0; i < ${#nodes[@]}; i += 3)); do
    # Sempre processa o primeiro nó do grupo
    node1="nodo${nodes[i]}"
    info1=$(get_node_info "$node1")

    # Inicializa info2 e info3 como strings vazias para evitar erros de 'variável não vinculada'
    info2=""
    info3=""

    # Verifica se o segundo nó do grupo existe
    if (( i + 1 < ${#nodes[@]} )); then
        node2="nodo${nodes[i+1]}"
        info2=$(get_node_info "$node2")
    fi

    # Verifica se o terceiro nó do grupo existe
    if (( i + 2 < ${#nodes[@]} )); then
        node3="nodo${nodes[i+2]}"
        info3=$(get_node_info "$node3")
    fi

    # Usa `paste` para imprimir as informações lado a lado
    # printf %s garante que strings vazias sejam tratadas corretamente por paste
    paste <(printf %s "$info1") <(printf %s "$info2") <(printf %s "$info3")
    echo ''
done

echo "END PING TEST."
