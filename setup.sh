#!/usr/bin/env bash
ARGS=""

# Define a memória do servidor. As unidades são aceitas (1024m=1Gig, 2048m=2Gig, 4096m=4Gig)
# Exemplo: 1024m
if [ -n "${MEMORY}" ]; then
  ARGS="${ARGS} -Xmx${MEMORY} -Xms${MEMORY}"
fi

# Opção para realizar um Soft Reset
if [ "${SOFTRESET}" == "1" ] || [ "${SOFTRESET,,}" == "true" ]; then
  ARGS="${ARGS} -Dsoftreset"
fi

# Fim dos argumentos Java
ARGS="${ARGS} -- "

# Desativa a integração com o Steam no servidor
# - Padrão: Habilitado
if [ "${NOSTEAM}" == "1" ] || [ "${NOSTEAM,,}" == "true" ]; then
  ARGS="${ARGS} -nosteam"
fi

# Define o caminho para o diretório de cache de dados do jogo
# - Padrão: ~/Zomboid
# - Exemplo: /server/Zomboid/data
if [ -n "${CACHEDIR}" ]; then
  ARGS="${ARGS} -cachedir=${CACHEDIR}"
fi

# Opção para controlar onde os mods são carregados e a ordem. Qualquer um dos 3 pode ser deixado de fora e podem aparecer em qualquer ordem.
# - Padrão: workshop,steam,mods
# - Exemplo: mods,steam
if [ -n "${MODFOLDERS}" ]; then
  ARGS="${ARGS} -modfolders ${MODFOLDERS}"
fi

# Lança o jogo em modo de depuração.
# - Padrão: Desativado
if [ "${DEBUG}" == "1" ] || [ "${DEBUG,,}" == "true" ]; then
  ARGS="${ARGS} -debug"
fi

# Opção para pular o prompt de senha ao criar o servidor.
# Esta opção é obrigatória no primeiro início, ou será perguntada no console e a inicialização falhará.
if [ -n "${ADMINPASSWORD}" ]; then
  ARGS="${ARGS} -adminpassword ${ADMINPASSWORD}"
fi

# Senha do servidor
if [ -n "${PASSWORD}" ]; then
  ARGS="${ARGS} -password ${PASSWORD}"
fi

# Nome do servidor
if [ -n "${SERVERNAME}" ]; then
  ARGS="${ARGS} -servername ${SERVERNAME}"
else
  SERVERNAME="servertest"
  ARGS="${ARGS} -servername ${SERVERNAME}"
fi

# Opção para lidar com múltiplas interfaces de rede. Exemplo: 127.0.0.1
if [ -n "${IP}" ]; then
  ARGS="${ARGS} -ip ${IP}"
fi

# Define a porta padrão para o servidor. Exemplo: 16261
if [ -n "${PORT}" ]; then
  ARGS="${ARGS} -port ${PORT}"
fi

# Opção para habilitar/desabilitar VAC nos servidores Steam
if [ -n "${STEAMVAC}" ]; then
  ARGS="${ARGS} -steamvac ${STEAMVAC,,}"
fi

# Define as portas Steam adicionais
if [ -n "${STEAMPORT1}" ]; then
  ARGS="${ARGS} -steamport1 ${STEAMPORT1}"
fi
if [ -n "${STEAMPORT2}" ]; then
  ARGS="${ARGS} -steamport2 ${STEAMPORT2}"
fi

# Modifica o arquivo de configuração do servidor com a senha
if [ -n "${PASSWORD}" ]; then
  sed -i "s/Password=.*/Password=${PASSWORD}/" "${HOMEDIR}/Zomboid/Server/${SERVERNAME}.ini"
fi

# Modifica o arquivo de configuração do servidor com os mods
if [ -n "${MOD_IDS}" ]; then
  echo "*** INFO: Found Mods including ${MOD_IDS} ***"
  sed -i "s/Mods=.*/Mods=${MOD_IDS}/" "${HOMEDIR}/Zomboid/Server/${SERVERNAME}.ini"
fi

# Modifica o arquivo de configuração do servidor com os IDs do Workshop
if [ -n "${WORKSHOP_IDS}" ]; then
  echo "*** INFO: Found Workshop IDs including ${WORKSHOP_IDS} ***"
  sed -i "s/WorkshopItems=.*/WorkshopItems=${WORKSHOP_IDS}/" "${HOMEDIR}/Zomboid/Server/${SERVERNAME}.ini"
fi

# Atualiza o servidor
update_server() {
    echo -e "\n### Atualizando servidor Project Zomboid...\n"
    
    # Executa o SteamCMD para atualizar o servidor
    steamcmd +runscript /home/pzuser/install_server.scmd
    
    echo -e "\n### Servidor Project Zomboid atualizado.\n"
}

# Define o diretório de instalação e de dados
INSTDIR="$(dirname "$0")"
cd "${INSTDIR}" || exit 1  # Verifica se conseguiu mudar o diretório
INSTDIR="$(pwd)"
SERVER_PATH="${INSTDIR}"

# Intervalos para o monitoramento e reinício
CHECK_INTERVAL=10     # Intervalo entre verificações (em segundos)
RESTART_WAIT_TIME=5   # Tempo de espera após parar o servidor

# Função para iniciar o servidor
iniciar_servidor() {
    echo "Iniciando servidor..."
    ./start-server.sh ${ARGS}  # Passa os argumentos para o servidor
}

# Função para monitorar o servidor e reiniciar caso pare
monitorar_servidor() {
    while true; do
        iniciar_servidor  # Inicia o servidor

        # Monitorar se o servidor está rodando
        while pgrep -f "ProjectZomboid64" > /dev/null; do
            sleep "$CHECK_INTERVAL"  # Checa o servidor a cada intervalo
        done

        echo "[$(date)] O servidor foi parado. Reiniciando..."

        # Espera um tempo antes de reiniciar o servidor
        sleep "$RESTART_WAIT_TIME"
    done
}

## Main
update_server  # Atualiza o servidor
monitorar_servidor  # Monitora e reinicia o servidor caso pare
exit 0
