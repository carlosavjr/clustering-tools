#!/bin/bash
#
# master_gtcmc_manager.sh
# Script mestre abrangente para gerenciar as operações de configuração e manutenção dos nós do cluster GTCMC.
# Este script orquestra a execução de vários sub-scripts para diferentes tarefas.
#

# --- Configuração Global ---
# O intervalo de nós (NODES_START e NODES_END) será solicitado APENAS quando um script
# que utiliza esses valores for selecionado para execução no menu.

# --- Funções Auxiliares ---

# Função para exibir mensagem de erro e sair
exit_on_error() {
    echo "ERRO: O script \"$1\" falhou com status de saída $2."
    echo "Verifique as mensagens de erro acima e tente novamente."
    # Não sai do script mestre, apenas da execução da sub-opção
}

# Função para solicitar o intervalo de nós
prompt_node_range() {
    read -p "Insira o número do NODO inicial para esta operação (ex: 02): " NODES_START
    read -p "Insira o número do NODO final para esta operação (ex: 17): " NODES_END
    # Valida se NODES_START e NODES_END são fornecidos e numéricos, se desejado.
    # Por enquanto, confiamos na validação dos sub-scripts.
}

# Função para exibir o menu principal
display_menu() {
    clear # Limpa a tela para um menu mais limpo
    echo "#################################################"
    echo "### Master Script de Gerenciamento de Cluster ###"
    echo "###         Manager                           ###"
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
    echo "11. Recuperar info de HW dos nodos para slurm.conf em list_specs (full_slurm_config_update.sh)"
    echo "12. Atualizar Configuração Slurm (08_updateslurmconf.sh)"
    echo "13. Verificar Status de Workers (workerstatus_batch.sh)"
    echo "14. Reiniciar nodo slurm travado (hung_proc.sh)"
    echo "15. Retomar Partição Slurm (resumepartition.sh)"
    echo "16. Reiniciar Controlador Slurm e Nodos Slurm (reload_slurm.sh)"
    echo ""
    echo "### IV. Otimização, Hardware (Drivers/Sensores) e Ferramentas Gerais ###"
    echo "17. Verificar Relógio dos Nós (a_checkclock.sh)"
    echo "18. Desabilitar GUI (b_disablegui.sh)"
    echo "19. Pingar IP Externo (ping_external.sh)"
    echo "20. Instalar Pacotes Adicionais (c_install_packages_nodes.sh)"
    echo "21. Varredura e instalação dos sensores de temperatura (e_installsensor.sh)"
    echo "22. Instalar NVIDIA CUDA (h_nvidia_cuda_install.sh)"
    echo "23. Instalar Driver GPU NVIDIA (i_nvidia_gpu_driver.sh)"
    echo "24. Instalar intel-oneapi-hpc-toolkit (f_installintel.sh)"
    echo ""
    echo "### V. Outros (Especial) ###"
    echo "25. Sair do script mestre"
    echo ""
}

# Loop principal do menu
while true; do
    display_menu
    read -p "Sua escolha: " CHOICE
    echo ""

    case "$CHOICE" in
        1)
            echo "#################################################"
            echo "### Executando: Descoberta de Hosts e NFS export (01_ip_range_host_discovery.sh)"
            echo "#################################################"
            echo "Para a descoberta de hosts, por favor, insira os detalhes da rede:"
            read -p "Insira o IP inicial da faixa (ex: 1): " IP_RANGE_START
            read -p "Insira o IP final da faixa (ex: 100): " IP_RANGE_END
            echo "Verificando hosts na faixa de 10.1.1.${IP_RANGE_START} a 10.1.1.${IP_RANGE_END}..."
            ~/admin_mode.sh
            sudo ./01_ip_range_host_discovery.sh "${IP_RANGE_START}" "${IP_RANGE_END}"
            if [ $? -ne 0 ]; then exit_on_error "01_ip_range_host_discovery.sh" $?; fi
            ;;
        2)
            echo "#################################################"
            echo "### Executando: Configurar Acesso Admin (02_accessadmin.sh)"
            echo "#################################################"
            prompt_node_range
            echo "Configurando acesso SSH sem senha para nós de nodo${NODES_START} a nodo${NODES_END}..."
            ./02_accessadmin.sh "${NODES_START}" "${NODES_END}"
            if [ $? -ne 0 ]; then exit_on_error "02_accessadmin.sh" $?; fi
            ;;
        3)
            echo "#################################################"
            echo "### Executando: Atualizar Hostnames (03_hostname_update.sh)"
            echo "#################################################"
            prompt_node_range
            echo "Atualizando hostnames para nós de nodo${NODES_START} a nodo${NODES_END}..."
            ./03_hostname_update.sh "${NODES_START}" "${NODES_END}"
            if [ $? -ne 0 ]; then exit_on_error "03_hostname_update.sh" $?; fi
            ;;
        4)
            echo "#################################################"
            echo "### Executando: Atualizar Montagem NFS nos nodos (d_nfsreload.sh)"
            echo "#################################################"
            prompt_node_range
            echo "Atualizando montagens NFS nos nós de nodo${NODES_START} a nodo${NODES_END}..."
            ./d_nfsreload.sh "${NODES_START}" "${NODES_END}"
            if [ $? -ne 0 ]; then exit_on_error "d_nfsreload.sh" $?; fi
            ;;
        5)
            echo "#################################################"
            echo "### Executando: Mudar /etc/hosts no nodos (j_add_host_node_entry.sh)"
            echo "#################################################"
            prompt_node_range
            echo "Adicionando entradas de host para nós de nodo${NODES_START} a nodo${NODES_END}..."
            sudo ./j_add_host_node_entry.sh "${NODES_START}" "${NODES_END}"
            if [ $? -ne 0 ]; then exit_on_error "j_add_host_node_entry.sh" $?; fi
            ;;
        6)
            echo "#################################################"
            echo "### Executando: Pingar Localmente Nós (ping_local.sh)"
            echo "#################################################"
            prompt_node_range
            echo "Executando ping local nos nós de nodo${NODES_START} a nodo${NODES_END}..."
            ./ping_local.sh "${NODES_START}" "${NODES_END}"
            if [ $? -ne 0 ]; then exit_on_error "ping_local.sh" $?; fi
            ;;
        7)
            echo "#################################################"
            echo "### Executando: Adicionar Usuários em Lote (04_user_batch_nodes.sh)"
            echo "#################################################"
            prompt_node_range
            echo "Adicionando/atualizando usuários nos nós de nodo${NODES_START} a nodo${NODES_END}..."
            ./04_user_batch_nodes.sh "${NODES_START}" "${NODES_END}"
            if [ $? -ne 0 ]; then exit_on_error "04_user_batch_nodes.sh" $?; fi
            ;;
        8)
            echo "#################################################"
            echo "### Executando: Configurar Acesso de Usuário (05_accessuser.sh)"
            echo "#################################################"
            prompt_node_range
            echo "Configurando acesso SSH sem senha para usuários nos nós de nodo${NODES_START} a nodo${NODES_END}..."
            ./05_accessuser.sh "${NODES_START}" "${NODES_END}"
            if [ $? -ne 0 ]; then exit_on_error "05_accessuser.sh" $?; fi
            ;;
        9)
            echo "#################################################"
            echo "### Executando: Instalar Munge (06_install_munge.sh)"
            echo "#################################################"
            prompt_node_range
            echo "Instalando Munge nos nós de nodo${NODES_START} a nodo${NODES_END}..."
            ./06_install_munge.sh "${NODES_START}" "${NODES_END}"
            if [ $? -ne 0 ]; then exit_on_error "06_install_munge.sh" $?; fi
            ;;
        10)
            echo "#################################################"
            echo "### Executando: Instalar Slurm-WLM (07_install_slurm-wlm.sh)"
            echo "#################################################"
            prompt_node_range
            echo "Instalando Slurm-WLM nos nós de nodo${NODES_START} a nodo${NODES_END}..."
            ./07_install_slurm-wlm.sh "${NODES_START}" "${NODES_END}"
            if [ $? -ne 0 ]; then exit_on_error "07_install_slurm-wlm.sh" $?; fi
            ;;
        11)
            echo "#################################################"
            echo "### Executando: Recuperar informação de hardware dos nodos para uso no slurm.conf (g_slurmCspec.sh)"
            echo "#################################################"
            prompt_node_range
            echo "Recuperando informações de hardware nos nodos de nodo${NODES_START} a nodo${NODES_END} para uso no slurm.conf..."
            ./g_slurmCspec.sh "${NODES_START}" "${NODES_END}"
            if [ $? -ne 0 ]; then exit_on_error "g_slurmCspec.sh" $?; fi
            ;;
        12)
            echo "#################################################"
            echo "### Executando: Atualizar Configuração Slurm (08_updateslurmconf.sh)"
            echo "#################################################"
            prompt_node_range
            echo "Atualizando a configuração do Slurm nos nós de nodo${NODES_START} a nodo${NODES_END}..."
            ./08_updateslurmconf.sh "${NODES_START}" "${NODES_END}"
            if [ $? -ne 0 ]; then exit_on_error "08_updateslurmconf.sh" $?; fi
            ;;
        13)
            echo "#################################################"
            echo "### Executando: Verificar Status de Workers (workerstatus_batch.sh)"
            echo "#################################################"
            prompt_node_range
            echo "Verificando o status dos workers nos nós de nodo${NODES_START} a nodo${NODES_END}..."
            ./workerstatus_batch.sh "${NODES_START}" "${NODES_END}"
            if [ $? -ne 0 ]; then exit_on_error "workerstatus_batch.sh" $?; fi
            ;;
        14)
            echo "#################################################"
            echo "### Executando: Reiniciar nodo slurm travado (hung_proc.sh)"
            echo "#################################################"
            prompt_node_range
            echo "Verificando processos travados e reiniciando nós Slurm travados nos nós de nodo${NODES_START} a nodo${NODES_END}..."
            ./hung_proc.sh "${NODES_START}" "${NODES_END}"
            if [ $? -ne 0 ]; then exit_on_error "hung_proc.sh" $?; fi
            ;;
       15)
            echo "#################################################"
            echo "### Executando: Retomar Partição Slurm (resumepartition.sh)"
            echo "#################################################"
            prompt_node_range
            echo "Retomando a partição Slurm para os nós de nodo${NODES_START} a nodo${NODES_END}..."
            ./resumepartition.sh "${NODES_START}" "${NODES_END}"
            if [ $? -ne 0 ]; then exit_on_error "resumepartition.sh" $?; fi
            ;;
        16)
            echo "#################################################"
            echo "### Executando: Retomar Partição Slurm (resumepartition.sh)"
            echo "#################################################"
            prompt_node_range
            echo "Recarregando Slurm para os nós de nodo${NODES_START} a nodo${NODES_END}..."
            ./reload_slurm.sh "${NODES_START}" "${NODES_END}"
            if [ $? -ne 0 ]; then exit_on_error "reload_slurm.sh" $?; fi
            ;;
        17)
            echo "#################################################"
            echo "### Executando: Verificar e Sincronizar Relógio dos Nós (a_checkclock.sh)"
            echo "#################################################"
            echo "Verificando e sincronizando o relógio em todos os nós ligados..."
            ./a_checkclock.sh
            if [ $? -ne 0 ]; then exit_on_error "a_checkclock.sh" $?; fi
            ;;
        18)
            echo "#################################################"
            echo "### Executando: Desabilitar GUI (b_disablegui.sh)"
            echo "#################################################"
            prompt_node_range
            echo "Desabilitando a interface gráfica (GUI) nos nós de nodo${NODES_START} a nodo${NODES_END}..."
            ./b_disablegui.sh "${NODES_START}" "${NODES_END}"
            if [ $? -ne 0 ]; then exit_on_error "b_disablegui.sh" $?; fi
            ;;
        19)
            echo "#################################################"
            echo "### Executando: Pingar IP Externo (ping_external.sh)"
            echo "#################################################"
            echo "Executando ping em www.google.com (configurado internamente pelo script ping_external.sh)..."
            ./ping_external.sh
            if [ $? -ne 0 ]; then exit_on_error "ping_external.sh" $?; fi
            ;;
        20)
            echo "#################################################"
            echo "### Executando: Instalar Pacotes (c_install_packages_nodes.sh)"
            echo "#################################################"
            prompt_node_range
            echo "Para a instalação de pacotes, por favor, insira os nomes dos pacotes separados por espaço:"
            read -p "Insira os pacotes (ex: build-essential htop nmon): " PACKAGES_TO_INSTALL
            echo "Instalando pacotes nos nós de nodo${NODES_START} a nodo${NODES_END}..."
            echo "Pacotes: ${PACKAGES_TO_INSTALL}"
            ./c_install_packages_nodes.sh "${NODES_START}" "${NODES_END}" ${PACKAGES_TO_INSTALL}
            if [ $? -ne 0 ]; then exit_on_error "c_install_packages_nodes.sh" $?; fi
            ;;
        21)
            echo "#################################################"
            echo "### Executando: Varredura e instalação dos sensores de temperatura (e_installsensor.sh)"
            echo "#################################################"
            prompt_node_range
            echo "Instalando software de sensores nos nós de nodo${NODES_START} a nodo${NODES_END}..."
            ./e_installsensor.sh "${NODES_START}" "${NODES_END}"
            if [ $? -ne 0 ]; then exit_on_error "e_installsensor.sh" $?; fi
            ;;
        22)
            echo "#################################################"
            echo "### Executando: Instalar NVIDIA CUDA (h_nvidia_cuda_install.sh)"
            echo "#################################################"
            prompt_node_range
            echo "Iniciando a instalação completa da NVIDIA (drivers, CUDA, etc.) nos nós de nodo${NODES_START} a nodo${NODES_END}..."
            ./h_nvidia_cuda_install.sh "${NODES_START}" "${NODES_END}"
            if [ $? -ne 0 ]; then exit_on_error "h_nvidia_cuda_install.sh" $?; fi
            ;;
        23)
            echo "#################################################"
            echo "### Executando: Instalar Driver GPU NVIDIA (i_nvidia_gpu_driver.sh)"
            echo "#################################################"
            prompt_node_range
            echo "Instalando apenas o driver GPU NVIDIA nos nós de nodo${NODES_START} a nodo${NODES_END}..."
            ./i_nvidia_gpu_driver.sh "${NODES_START}" "${NODES_END}"
            if [ $? -ne 0 ]; then exit_on_error "i_nvidia_gpu_driver.sh" $?; fi
            ;;


        24)
            echo "#################################################"
            echo "### Executando: Instalar Intel HPC (f_installintel.sh)"
            echo "#################################################"
            prompt_node_range
            echo "Instalando o intel-oneapi-hpc-toolkit nos nós de nodo${NODES_START} a nodo${NODES_END}..."
            ./f_installintel.sh "${NODES_START}" "${NODES_END}"
            if [ $? -ne 0 ]; then exit_on_error "f_installintel.sh" $?; fi
            ;;

        25)
            echo "Saindo do script mestre."
            exit 0
            ;;
        *)
            echo "Opção inválida. Por favor, digite um número entre 1 e 23."
            ;;
    esac

    echo ""
    read -p "Pressione Enter para retornar ao menu..."
done

echo "#################################################"
echo "### Todas as operações do script mestre concluídas. ###"
echo "#################################################"
