Scripts de Gerenciamento de Cluster. 

O conjunto de scripts forma uma ferramenta para automatizar a configuração e manutenção do seu cluster no Ubuntu 20.04. As seguintes ferramentas são destacadas:

Descoberta de Hosts (01_ip_range_host_discovery.sh)
Este script é fundamental para identificar e configurar novos nós ou verificar o status de nós existentes. Ele faz uma varredura em uma faixa de IPs definida por você, identifica quais hosts estão ativos (respondendo a pings) e, em seguida, atualiza o arquivo /etc/hosts no seu nó principal (o servidor NFS) com os IPs e nomes de host descobertos. Além disso, ele configura automaticamente as entradas de exportação NFS no /etc/exports do servidor, garantindo que os novos nós ativos possam acessar os recursos compartilhados.

Configurar Acesso Admin (02_accessadmin.sh)
Pensado para facilitar o acesso administrativo, este script configura o acesso SSH sem senha do seu nó de controle para os nós do cluster. Ele instala a chave SSH pública do usuário administrador nos nós remotos, eliminando a necessidade de digitar senhas repetidamente para tarefas de gerenciamento e automação.

Atualizar Hostnames (03_hostname_update.sh)
A consistência nos nomes de host é crucial para a organização do cluster. Este script é responsável por atualizar os hostnames de cada nó para um padrão uniforme (ex: nodo02, nodo03, etc.), o que facilita a identificação e o gerenciamento dentro do ambiente de cluster.

Adicionar Usuários em Lote (04_user_batch_nodes.sh)
Essencial para a criação e manutenção de ambientes multiusuário. Este script permite adicionar múltiplos usuários em todos os nós do cluster em um processo de lote. Ele utiliza arquivos (new_users.txt e newpass.txt, disponíveis via NFS) para criar as contas e definir suas senhas. De forma inteligente, ele pula a criação de usuários que já existem e garante que as senhas sejam definidas apenas para contas válidas.

Configurar Acesso de Usuário (05_accessuser.sh)
Complementando o acesso administrativo, este script configura o acesso SSH sem senha para usuários comuns entre o nó de controle e os nós de computação. Isso é vital para que os usuários possam submeter e monitorar seus trabalhos nos nós sem a necessidade de autenticação por senha para cada conexão.

Instalar Munge (06_install_munge.sh)
Munge é um serviço de autenticação essencial para o Slurm. Este script se encarrega de instalar e configurar o serviço Munge nos nós do cluster. Ele garante que os componentes do Slurm possam se comunicar de forma segura e autenticada.

Instalar Slurm-WLM (07_install_slurm-wlm.sh)
Este script é o passo para transformar seus nós em parte de um cluster de computação de alto desempenho. Ele instala o Slurm Workload Manager (slurm-wlm), que é o sistema de gerenciamento de filas e recursos responsável por agendar e distribuir as tarefas de computação entre os nós.

O script "Master Script de Gerenciamento de Cluster" organiza as tarefas de instalação e manutenção do cluster em diversas categorias. Abaixo está uma classificação detalhada e reordenada de cada uma das 23 operações:

I. Configuração Inicial e Rede
Estas operações focam na configuração básica da rede e na identificação de hosts, essenciais para a comunicação dentro do cluster.

Descoberta de Hosts e NFS export (01_ip_range_host_discovery.sh): Identifica hosts na rede e configura exportações NFS.

Configurar Acesso Admin (02_accessadmin.sh): Estabelece acesso administrativo sem senha via SSH para facilitar a gestão.

Atualizar Hostnames (03_hostname_update.sh): Garante que os nomes dos hosts dos nós estejam corretos e atualizados.

Atualizar Montagem NFS nos nodos (d_nfsreload.sh): Assegura que as montagens do sistema de arquivos de rede (NFS) nos nós clientes estejam operacionais e atualizadas.

Mudar /etc/hosts no nodos (j_add_host_node_entry.sh): Modifica o arquivo /etc/hosts nos nós para garantir a resolução de nomes interna.

Pingar Localmente Nós (ping_local.sh): Verifica a conectividade de rede local entre os nós.

II. Gerenciamento de Acesso e Usuários
Esta seção abrange a configuração de acesso SSH e a gestão de contas de usuários para administradores e usuários comuns.

Adicionar Usuários em Lote (04_user_batch_nodes.sh): Permite a adição ou atualização de múltiplos usuários nos nós do cluster de forma automatizada.

Configurar Acesso de Usuário (05_accessuser.sh): Configura o acesso SSH para usuários comuns.

III. Instalação e Configuração do Slurm
Este grupo de operações é dedicado à instalação e configuração do sistema de gerenciamento de carga de trabalho Slurm.

Instalar Munge (06_install_munge.sh): Instala o serviço de autenticação Munge, uma dependência crucial do Slurm.

Instalar Slurm-WLM (07_install_slurm-wlm.sh): Instala o Slurm Workload Manager nos nós.

Recuperar informação de hardware dos nodos para uso no slurm.conf (g_slurmCspec.sh): Coleta dados de hardware necessários para otimizar a configuração do slurm.conf.

Atualizar Configuração Slurm (08_updateslurmconf.sh): Atualiza os arquivos de configuração do Slurm.

Verificar Status de Workers (workerstatus_batch.sh): Monitora o estado dos processos de worker do Slurm nos nós.

Reiniciar nodo slurm travado (hung_proc.sh): Ferramenta para lidar com nós Slurm que estão em estado travado.

Retomar Partição Slurm (resumepartition.sh): Altera o estado de uma partição Slurm para "RESUME", tornando-a ativa novamente.

IV. Otimização, Hardware (Drivers/Sensores) e Ferramentas Gerais
Estas operações são voltadas para a otimização do desempenho dos nós, incluindo drivers de hardware, ferramentas de monitoramento e utilitários gerais.

Verificar Relógio dos Nós (a_checkclock.sh): Garante que os relógios de todos os nós estejam sincronizados, o que é crucial para o Slurm e outras operações de cluster.

Desabilitar GUI (b_disablegui.sh): Desabilita a interface gráfica (GUI) para liberar recursos para tarefas computacionais.

Instalar Pacotes Adicionais (c_install_packages_nodes.sh): Permite a instalação de pacotes de software adicionais que podem ser necessários nos nós.

Varredura e instalação dos sensores de temperatura (e_installsensor.sh): Instala software para monitorar a temperatura dos componentes de hardware.

Instalar NVIDIA CUDA (h_nvidia_cuda_install.sh): Instala o kit de ferramentas CUDA da NVIDIA para computação em GPU.

Instalar Driver GPU NVIDIA (i_nvidia_gpu_driver.sh): Instala os drivers específicos para as GPUs NVIDIA.

Pingar IP Externo (ping_external.sh): Testa a conectividade de rede externa (internet) a partir dos nós.

V. Outros (Especial)
Esta é uma opção de controle para o script mestre.

Sair do script mestre: Encerra a execução do script principal.

Espero que esta apresentação detalhada ajude você a entender melhor a função de cada componente para implementação e gerenciamento do seu cluster!
