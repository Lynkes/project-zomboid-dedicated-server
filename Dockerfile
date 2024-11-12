# Use a imagem base com SteamCMD já configurado
FROM cm2network/steamcmd:root

# Defina a variável de ambiente para o caminho dos dados do servidor
ENV ZOMBOID_DATA_PATH="/mnt/VDEV/Zomboid"
ENV STEAMAPPDIR="${ZOMBOID_DATA_PATH}/steamapps/common/Project Zomboid"
ENV STEAMCMDDIR="/home/steam/steamcmd"
ENV STEAMAPPID="380870" 
ENV HOMEDIR="/home/steam"
# Empty Strings are ignored or equivalent to false
ENV NOSTEAM=False
ENV CACHEDIR="${ZOMBOID_DATA_PATH}/data"
ENV DEBUG=False
ENV ADMINPASSWORD="1234"
ENV SERVERNAME=
ENV SERVERPRESET=
ENV IP=
ENV PORT=16261
ENV STEAMVAC=True
ENV STEAMPORT1=
ENV STEAMPORT2=
ENV MEMORY=2048m
ENV SOFTRESET=False
ENV MOD_IDS=
ENV WORKSHOP_IDS=
# Atualize o sistema e instale dependências adicionais
USER root
RUN dpkg --add-architecture i386 && \
    apt update && \
    apt install -y ufw dos2unix tmux

# Crie o diretório necessário e ajuste as permissões para o usuário steam
RUN mkdir -p "$ZOMBOID_DATA_PATH" && \
    chown steam:steam "$ZOMBOID_DATA_PATH"

# Defina o caminho do SteamCMD e mude para o usuário steam para execução do SteamCMD
USER steam
ENV PATH="$PATH:/home/steam/steamcmd"

# Crie o arquivo de script de instalação
RUN echo "\
@ShutdownOnFailedCommand 1 \n\
@NoPromptForPassword 1 \n\
force_install_dir $ZOMBOID_DATA_PATH \n\
login anonymous \n\
app_update 380870 validate \n\
quit" > /home/steam/install_server.scmd

# Execute o SteamCMD para instalar o servidor do Project Zomboid
RUN /home/steam/steamcmd/steamcmd.sh +runscript /home/steam/install_server.scmd

# Retorne ao usuário root para continuar com permissões de administração
USER root

# Copie o script de configuração para o container (agora ele deve ir para $ZOMBOID_DATA_PATH)
RUN mkdir -p "$ZOMBOID_DATA_PATH/data"
COPY setup.sh $ZOMBOID_DATA_PATH/setup.sh
RUN chmod +x $ZOMBOID_DATA_PATH/setup.sh

# Exponha as portas necessárias para o servidor
EXPOSE 16261/udp 16262/udp

# Abra as portas no firewall (UFW)
RUN ufw allow 16261/udp && \
    ufw allow 16262/udp && \
    ufw reload

# Defina o ponto de entrada do container
ENTRYPOINT ["sh", "-c", "$ZOMBOID_DATA_PATH/setup.sh"]
