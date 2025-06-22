#!/bin/bash
#
# master_gtcmc_manager.sh
# Script mestre abrangente para gerenciar as operações de configuração e manutenção dos nós do cluster GTCMC.
# Este script orquestra a execução de vários sub-scripts para diferentes tarefas.
#

echo "#################################################"
echo "### Master Script de Gerenciamento de Cluster ###"
echo "###                 Manager                   ###"
echo "#################################################"
echo ""
echo "##################################################################################"
echo "### AVISO: Pré-requisitos de Software                                          ###"
echo "### Para o funcionamento correto deste script e do cluster, certifique-se de que:"
echo "### - No SERVIDOR NFS: 'nfs-kernel-server' (ou equivalente) esteja instalado."
echo "### - Nos NODOS CLIENTES: 'nfs-common' esteja instalado."
echo "### - Em AMBOS (SERVIDOR e NODOS): 'openssh-client' e 'openssh-server' estejam instalados."
echo "##################################################################################"
echo ""

# --- Configuração Global ---
# O intervalo de nós (NODES_START e NODES_END) será solicitado APENAS quando um script
# que utiliza esses valores for selecionado para execução no menu.

# --- Funções Auxiliares ---

# Função para exibir mensagem de erro e sair
exit_on_error() {
    echo "ERRO: O script \"$1\" falhou com status de saída $2."
    echo "Verifique as mensagens de erro acima e tente novamente."
    exit 1
}

# Função para solicitar o intervalo de nós
prompt_node_range() {
    read -p "Insira o número do NODO inicial para esta operação (ex: 02): " NODES_START
    read -p "Insira o número do NODO final para esta operação (ex: 17): " NODES_END
    # Validate if NODES_START and NODES_END are provided and numeric, if desired.
    # For now, we rely on the sub-scripts' validation.
}

# --- Menu de Seleção de Operações ---
echo "#################################################"
echo "### Selecione as operações a serem executadas: ###"
echo "#################################################"
echo "### I. Configuração Inicial e Rede ###"
echo "1. Descoberta de Hosts e NFS export (01_ip_range_host_discovery.sh)"
echo "2. Configurar Acesso Admin (02_accessadmin.sh)"
echo "3. Atualizar Hostnames (03_hostname_update.sh)"
echo "4. Atualizar Montagem NFS nos nodos (d_nfsreload.sh)"
echo "5. Mudar /etc/hosts no nodos (j_add_host_node_entry.sh)"
echo "6. Pingar Localmente Nós (ping_local.sh)"
echo ""
echo "### II. Gerenciamento de Acesso e Usuários ###"
echo "7. Adicionar Usuários em Lote (04_user_batch_nodes.sh)"
echo "8. Configurar Acesso de Usuário (05_accessuser.sh)"
echo ""
echo "### III. Instalação e Configuração do Slurm ###"
echo "9. Instalar Munge (06_install_munge.sh)"
echo "10. Instalar Slurm-WLM (07_install_slurm-wlm.sh)"
echo "11. Recuperar informação de hardware dos nodos para uso no slurm.conf (g_slurmCspec.sh)"
echo "12. Atualizar Configuração Slurm (08_updateslurmconf.sh)"
echo "13. Verificar Status de Workers (workerstatus_batch.sh)"
echo "14. Reiniciar nodo slurm travado (hung_proc.sh)"
echo "15. Retomar Partição Slurm (resumepartition.sh)"
echo ""
echo "### IV. Otimização, Hardware (Drivers/Sensores) e Ferramentas Gerais ###"
echo "16. Verificar Relógio dos Nós (a_checkclock.sh)"
echo "17. Desabilitar GUI (b_disablegui.sh)"
echo "18. Pingar IP Externo (ping_external.sh)" # Movido para a posição 18
echo "19. Instalar Pacotes Adicionais (c_install_packages_nodes.sh)" # Renumerado de 17 para 19
echo "20. Varredura e instalação dos sensores de temperatura (e_installsensor.sh)" # Renumerado de 18 para 20
echo "21. Instalar NVIDIA CUDA (h_nvidia_cuda_install.sh)" # Renumerado de 19 para 21
echo "22. Instalar Driver GPU NVIDIA (i_nvidia_gpu_driver.sh)" # Renumerado de 20 para 22
echo ""
echo "### V. Outros (Especial) ###"
echo "23. Sair do script mestre"
echo ""
echo "Digite os números das operações desejadas, separados por espaço (ex: 1 3 8):"
read -p "Sua escolha: " SELECTED_OPTIONS
echo ""

# Se a opção Sair for escolhida, o script encerra aqui.
if [[ "$SELECTED_OPTIONS" == "23" ]]; then
    echo "Saindo do script mestre."
    exit 0
fi

# Converte a string de opções selecionadas em um array Bash para fácil verificação
declare -a SELECTED_OPTIONS_ARRAY
for opt in $SELECTED_OPTIONS; do
    SELECTED_OPTIONS_ARRAY+=("$opt")
done

# Função auxiliar para verificar se uma opção foi selecionada
is_option_selected() {
    local target_option="$1"
    for opt in "${SELECTED_OPTIONS_ARRAY[@]}"; do
        if [[ "$opt" == "$target_option" ]]; then
            return 0 # True (option found)
        fi
    done
    return 1 # False (option not found)
}

# --- Execução dos Sub-scripts ---

echo "Iniciando as operações de gerenciamento do cluster..."
echo ""

# -----------------------------------------------------------------------------
## 1. Descoberta de Hosts e NFS export (01_ip_range_host_discovery.sh)
# -----------------------------------------------------------------------------
if is_option_selected "1"; then
    echo "#################################################"
    echo "### Executando: Descoberta de Hosts e NFS export (01_ip_range_host_discovery.sh)"
    echo "#################################################"
    echo "Para a descoberta de hosts, por favor, insira os detalhes da rede:"

    read -p "Insira o IP inicial da faixa (ex: 1): " IP_RANGE_START
    read -p "Insira o IP final da faixa (ex: 100): " IP_RANGE_END

    echo "Verificando hosts na faixa de 10.1.1.${IP_RANGE_START} a 10.1.1.${IP_RANGE_END}..."
    ~/admin_mode.sh;
    sudo ./01_ip_range_host_discovery.sh "${IP_RANGE_START}" "${IP_RANGE_END}"
    if [ $? -ne 0 ]; then exit_on_error "01_ip_range_host_discovery.sh" $?; fi
    echo ""
fi


# -----------------------------------------------------------------------------
## 2. Configurar Acesso Admin sem Senha (02_accessadmin.sh)
# -----------------------------------------------------------------------------
if is_option_selected "2"; then
    echo "#################################################"
    echo "### Executando: Configurar Acesso Admin (02_accessadmin.sh)"
    echo "#################################################"
    prompt_node_range # Solicita o intervalo de nós
    echo "Configurando acesso SSH sem senha para nós de nodo${NODES_START} a nodo${NODES_END}..."
    ./02_accessadmin.sh "${NODES_START}" "${NODES_END}"
    if [ $? -ne 0 ]; then exit_on_error "02_accessadmin.sh" $?; fi
    echo ""
fi

# -----------------------------------------------------------------------------
## 3. Atualizar Hostnames dos Nós (03_hostname_update.sh)
# -----------------------------------------------------------------------------
if is_option_selected "3"; then
    echo "#################################################"
    echo "### Executando: Atualizar Hostnames (03_hostname_update.sh)"
    echo "#################################################"
    prompt_node_range # Solicita o intervalo de nós
    echo "Atualizando hostnames para nós de nodo${NODES_START} a nodo${NODES_END}..."
    ./03_hostname_update.sh "${NODES_START}" "${NODES_END}"
    if [ $? -ne 0 ]; then exit_on_error "03_hostname_update.sh" $?; fi
    echo ""
fi

# -----------------------------------------------------------------------------
## 4. Atualizar Montagem NFS nos nodos (d_nfsreload.sh)
# -----------------------------------------------------------------------------
if is_option_selected "4"; then
    echo "#################################################"
    echo "### Executando: Atualizar Montagem NFS nos nodos (d_nfsreload.sh)"
    echo "#################################################"
    prompt_node_range # Solicita o intervalo de nós
    echo "Atualizando montagens NFS nos nós de nodo${NODES_START} a nodo${NODES_END}..."
    ./d_nfsreload.sh "${NODES_START}" "${NODES_END}"
    if [ $? -ne 0 ]; then exit_on_error "d_nfsreload.sh" $?; fi
    echo ""
fi

# -----------------------------------------------------------------------------
## 5. Mudar /etc/hosts no nodos (j_add_host_node_entry.sh)
# -----------------------------------------------------------------------------
if is_option_selected "5"; then
    echo "#################################################"
    echo "### Executando: Mudar /etc/hosts no nodos (j_add_host_node_entry.sh)"
    echo "#################################################"
    prompt_node_range # Solicita o intervalo de nós
    echo "Adicionando entradas de host para nós de nodo${NODES_START} a nodo${NODES_END}..."
    sudo ./j_add_host_node_entry.sh "${NODES_START}" "${NODES_END}"
    if [ $? -ne 0 ]; then exit_on_error "j_add_host_node_entry.sh" $?; fi
    echo ""
fi

# -----------------------------------------------------------------------------
## 6. Pingar Localmente Nós (ping_local.sh)
# -----------------------------------------------------------------------------
if is_option_selected "6"; then
    echo "#################################################"
    echo "### Executando: Pingar Localmente Nós (ping_local.sh)"
    echo "#################################################"
    prompt_node_range # Solicita o intervalo de nós
    echo "Executando ping local nos nós de nodo${NODES_START} a nodo${NODES_END}..."
    ./ping_local.sh "${NODES_START}" "${NODES_END}"
    if [ $? -ne 0 ]; then exit_on_error "ping_local.sh" $?; fi
    echo ""
fi

# -----------------------------------------------------------------------------
## 7. Adicionar Usuários em Lote nos Nós (04_user_batch_nodes.sh)
# -----------------------------------------------------------------------------
if is_option_selected "7"; then
    echo "#################################################"
    echo "### Executando: Adicionar Usuários em Lote (04_user_batch_nodes.sh)"
    echo "#################################################"
    prompt_node_range # Solicita o intervalo de nós
    echo "Adicionando/atualizando usuários nos nós de nodo${NODES_START} a nodo${NODES_END}..."
    ./04_user_batch_nodes.sh "${NODES_START}" "${NODES_END}"
    if [ $? -ne 0 ]; then exit_on_error "04_user_batch_nodes.sh" $?; fi
    echo ""
fi

# -----------------------------------------------------------------------------
## 8. Configurar Acesso de Usuário (05_accessuser.sh)
# -----------------------------------------------------------------------------
if is_option_selected "8"; then
    echo "#################################################"
    echo "### Executando: Configurar Acesso de Usuário (05_accessuser.sh)"
    echo "#################################################"
    prompt_node_range # Solicita o intervalo de nós
    echo "Configurando acesso SSH sem senha para usuários nos nós de nodo${NODES_START} a nodo${NODES_END}..."
    ./05_accessuser.sh "${NODES_START}" "${NODES_END}"
    if [ $? -ne 0 ]; then exit_on_error "05_accessuser.sh" $?; fi
    echo ""
fi

# -----------------------------------------------------------------------------
## 9. Instalar Munge (dependência do Slurm) (06_install_munge.sh)
# -----------------------------------------------------------------------------
if is_option_selected "9"; then
    echo "#################################################"
    echo "### Executando: Instalar Munge (06_install_munge.sh)"
    echo "#################################################"
    prompt_node_range # Solicita o intervalo de nós
    echo "Instalando Munge nos nós de nodo${NODES_START} a nodo${NODES_END}..."
    ./06_install_munge.sh "${NODES_START}" "${NODES_END}"
    if [ $? -ne 0 ]; then exit_on_error "06_install_munge.sh" $?; fi
    echo ""
fi

# -----------------------------------------------------------------------------
## 10. Instalar Slurm Workload Manager (07_install_slurm-wlm.sh)
# -----------------------------------------------------------------------------
if is_option_selected "10"; then
    echo "#################################################"
    echo "### Executando: Instalar Slurm-WLM (07_install_slurm-wlm.sh)"
    echo "#################################################"
    prompt_node_range # Solicita o intervalo de nós
    echo "Instalando Slurm-WLM nos nós de nodo${NODES_START} a nodo${NODES_END}..."
    ./07_install_slurm-wlm.sh "${NODES_START}" "${NODES_END}"
    if [ $? -ne 0 ]; then exit_on_error "07_install_slurm-wlm.sh" $?; fi
    echo ""
fi

# -----------------------------------------------------------------------------
## 11. Recuperar informação de hardware dos nodos para uso no slurm.conf (g_slurmCspec.sh)
# -----------------------------------------------------------------------------
if is_option_selected "11"; then
    echo "#################################################"
    echo "### Executando: Recuperar informação de hardware dos nodos para uso no slurm.conf (g_slurmCspec.sh)"
    echo "#################################################"
    prompt_node_range # Solicita o intervalo de nós
    echo "Recuperando informações de hardware nos nodos de nodo${NODES_START} a nodo${NODES_END} para uso no slurm.conf..."
    ./g_slurmCspec.sh "${NODES_START}" "${NODES_END}"
    if [ $? -ne 0 ]; then exit_on_error "g_slurmCspec.sh" $?; fi
    echo ""
fi

# -----------------------------------------------------------------------------
## 12. Atualizar Configuração Slurm (08_updateslurmconf.sh)
# -----------------------------------------------------------------------------
if is_option_selected "12"; then
    echo "#################################################"
    echo "### Executando: Atualizar Configuração Slurm (08_updateslurmconf.sh)"
    echo "#################################################"
    prompt_node_range # Solicita o intervalo de nós
    echo "Atualizando a configuração do Slurm nos nós de nodo${NODES_START} a nodo${NODES_END}..."
    ./08_updateslurmconf.sh "${NODES_START}" "${NODES_END}"
    if [ $? -ne 0 ]; then exit_on_error "08_updateslurmconf.sh" $?; fi
    echo ""
fi

# -----------------------------------------------------------------------------
## 13. Verificar Status de Workers (workerstatus_batch.sh)
# -----------------------------------------------------------------------------
if is_option_selected "13"; then
    echo "#################################################"
    echo "### Executando: Verificar Status de Workers (workerstatus_batch.sh)"
    echo "#################################################"
    prompt_node_range # Solicita o intervalo de nós
    echo "Verificando o status dos workers nos nós de nodo${NODES_START} a nodo${NODES_END}..."
    ./workerstatus_batch.sh "${NODES_START}" "${NODES_END}"
    if [ $? -ne 0 ]; then exit_on_error "workerstatus_batch.sh" $?; fi
    echo ""
fi

# -----------------------------------------------------------------------------
## 14. Reiniciar nodo slurm travado (hung_proc.sh)
# -----------------------------------------------------------------------------
if is_option_selected "14"; then
    echo "#################################################"
    echo "### Executando: Reiniciar nodo slurm travado (hung_proc.sh)"
    echo "#################################################"
    prompt_node_range # Solicita o intervalo de nós
    echo "Verificando processos travados e reiniciando nós Slurm travados nos nós de nodo${NODES_START} a nodo${NODES_END}..."
    ./hung_proc.sh "${NODES_START}" "${NODES_END}"
    if [ $? -ne 0 ]; then exit_on_error "hung_proc.sh" $?; fi
    echo ""
fi

# -----------------------------------------------------------------------------
## 15. Retomar Partição Slurm (resumepartition.sh)
# -----------------------------------------------------------------------------
if is_option_selected "15"; then
    echo "#################################################"
    echo "### Executando: Retomar Partição Slurm (resumepartition.sh)"
    echo "#################################################"
    prompt_node_range # Solicita o intervalo de nós
    echo "Retomando a partição Slurm para os nós de nodo${NODES_START} a nodo${NODES_END}..."
    ./resumepartition.sh "${NODES_START}" "${NODES_END}"
    if [ $? -ne 0 ]; then exit_on_error "resumepartition.sh" $?; fi
    echo ""
fi

# -----------------------------------------------------------------------------
## 16. Verificar Relógio dos Nós (a_checkclock.sh)
# -----------------------------------------------------------------------------
if is_option_selected "16"; then
    echo "#################################################"
    echo "### Executando: Verificar e Sincronizar Relógio dos Nós (a_checkclock.sh)"
    echo "#################################################"
    # O script a_checkclock.sh é responsável por verificar e sincronizar o relógio em todos os nós ligados.
    echo "Verificando e sincronizando o relógio em todos os nós ligados..."
    ./a_checkclock.sh
    if [ $? -ne 0 ]; then exit_on_error "a_checkclock.sh" $?; fi
    echo ""
fi

# -----------------------------------------------------------------------------
## 17. Desabilitar GUI (b_disablegui.sh)
# -----------------------------------------------------------------------------
if is_option_selected "17"; then
    echo "#################################################"
    echo "### Executando: Desabilitar GUI (b_disablegui.sh)"
    echo "#################################################"
    prompt_node_range # Solicita o intervalo de nós
    echo "Desabilitando a interface gráfica (GUI) nos nós de nodo${NODES_START} a nodo${NODES_END}..."
    ./b_disablegui.sh "${NODES_START}" "${NODES_END}"
    if [ $? -ne 0 ]; then exit_on_error "b_disablegui.sh" $?; fi
    echo ""
fi

# -----------------------------------------------------------------------------
## 18. Pingar IP Externo (ping_external.sh)
# -----------------------------------------------------------------------------
if is_option_selected "18"; then
    echo "#################################################"
    echo "### Executando: Pingar IP Externo (ping_external.sh)"
    echo "#################################################"
    # Assume que o script ping_external.sh já tem a lógica interna para pingar www.google.com
    echo "Executando ping em www.google.com (configurado internamente pelo script ping_external.sh)..."
    ./ping_external.sh
    if [ $? -ne 0 ]; then exit_on_error "ping_external.sh" $?; fi
    echo ""
fi

# -----------------------------------------------------------------------------
## 19. Instalar Pacotes Adicionais nos Nós (c_install_packages_nodes.sh)
# -----------------------------------------------------------------------------
if is_option_selected "19"; then
    echo "#################################################"
    echo "### Executando: Instalar Pacotes (c_install_packages_nodes.sh)"
    echo "#################################################"
    prompt_node_range # Solicita o intervalo de nós
    echo "Para a instalação de pacotes, por favor, insira os nomes dos pacotes separados por espaço:"

    read -p "Insira os pacotes (ex: build-essential htop nmon): " PACKAGES_TO_INSTALL

    echo "Instalando pacotes nos nós de nodo${NODES_START} a nodo${NODES_END}..."
    echo "Pacotes: ${PACKAGES_TO_INSTALL}"
    ./c_install_packages_nodes.sh "${NODES_START}" "${NODES_END}" ${PACKAGES_TO_INSTALL}
    if [ $? -ne 0 ]; then exit_on_error "c_install_packages_nodes.sh" $?; fi
    echo ""
fi

# -----------------------------------------------------------------------------
## 20. Varredura e instalação dos sensores de temperatura (e_installsensor.sh)
# -----------------------------------------------------------------------------
if is_option_selected "20"; then
    echo "#################################################"
    echo "### Executando: Varredura e instalação dos sensores de temperatura (e_installsensor.sh)"
    echo "#################################################"
    prompt_node_range # Solicita o intervalo de nós
    echo "Instalando software de sensores nos nós de nodo${NODES_START} a nodo${NODES_END}..."
    ./e_installsensor.sh "${NODES_START}" "${NODES_END}"
    if [ $? -ne 0 ]; then exit_on_error "e_installsensor.sh" $?; fi
    echo ""
fi

# -----------------------------------------------------------------------------
## 21. Instalar NVIDIA CUDA (h_nvidia_cuda_install.sh)
# -----------------------------------------------------------------------------
if is_option_selected "21"; then
    echo "#################################################"
    echo "### Executando: Instalar NVIDIA CUDA (h_nvidia_cuda_install.sh)"
    echo "#################################################"
    prompt_node_range # Solicita o intervalo de nós
    echo "Iniciando a instalação completa da NVIDIA (drivers, CUDA, etc.) nos nós de nodo${NODES_START} a nodo${NODES_END}..."
    ./h_nvidia_cuda_install.sh "${NODES_START}" "${NODES_END}"
    if [ $? -ne 0 ]; then exit_on_error "h_nvidia_cuda_install.sh" $?; fi
    echo ""
fi

# -----------------------------------------------------------------------------
## 22. Instalar Driver GPU NVIDIA (i_nvidia_gpu_driver.sh)
# -----------------------------------------------------------------------------
if is_option_selected "22"; then
    echo "#################################################"
    echo "### Executando: Instalar Driver GPU NVIDIA (i_nvidia_gpu_driver.sh)"
    echo "#################################################"
    prompt_node_range # Solicita o intervalo de nós
    echo "Instalando apenas o driver GPU NVIDIA nos nós de nodo${NODES_START} a nodo${NODES_END}..."
    ./i_nvidia_gpu_driver.sh "${NODES_START}" "${NODES_END}"
    if [ $? -ne 0 ]; then exit_on_error "i_nvidia_gpu_driver.sh" $?; fi
    echo ""
fi


echo "#################################################"
echo "### Todas as operações do script mestre concluídas. ###"
echo "#################################################"
