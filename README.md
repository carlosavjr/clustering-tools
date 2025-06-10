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

Instalar Pacotes Adicionais (c_install_packages_nodes.sh)
Para garantir que seus nós tenham todas as ferramentas e bibliotecas necessárias para as cargas de trabalho do cluster, este script permite instalar pacotes de software adicionais em lote. Você pode especificar quais pacotes deseja instalar, e o script cuidará da distribuição e instalação em todos os nós selecionados.

Espero que esta apresentação detalhada ajude você a entender melhor a função de cada componente para implementação e gerenciamento do seu cluster!
