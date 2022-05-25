#!/bin/bash
# Autor: Robson Vaamonde
# Site: www.procedimentosemti.com.br
# Facebook: facebook.com/ProcedimentosEmTI
# Facebook: facebook.com/BoraParaPratica
# YouTube: youtube.com/BoraParaPratica
# Linkedin: https://www.linkedin.com/in/robson-vaamonde-0b029028/
# Instagram: https://www.instagram.com/procedimentoem/?hl=pt-br
# Github: https://github.com/vaamonde
# Data de criação: 03/12/2021
# Data de atualização: 12/01/2022
# Versão: 0.06
# Testado e homologado para a versão do Ubuntu Server 20.04.x LTS x64x
# Testado e homologado para a versão do Apache Guacamole Server 1.3.x e Cliente 1.3.x
#
# O Apache Guacamole é um gateway de desktop remoto sem cliente, ele suporta protocolos 
# padrão como VNC, RDP e SSH., ele é chamado de Clientless porque nenhum plug-in ou 
# software cliente é necessário para o seu funcionamento isso e possível graças ao HTML5, 
# uma vez que o Apache Guacamole é instalado em um servidor, tudo que você precisa para 
# acessar seus desktops é um navegador da web.
#
# Informações que serão solicitadas na configuração via Web do Apache Guacamole
# Username: guacadmin
# Password: guacadmin
#
# Instalação do Vino VNC Server no Linux Mint 19.x e 20.x
# 	sudo apt update
#	sudo apt install vino
#	sudo gsettings set org.gnome.Vino prompt-enabled true
#	sudo gsettings set org.gnome.Vino require-encryption false
#	cd /usr/lib/vino/
#	./vino-server &
#	sudo netstat -pl | grep 5900
#	sudo nc -vz 127.0.0.1 5900
#
# Instalação do Telnet Server no Ubuntu Server 18.04.x
#	sudo apt update
#	sudo apt install telnetd
#
# Instalação do OpenSSH Sever no Ubuntu Server 18.04.x
#	sudo apt update
# 	sudo apt install openssh-server
#
# Site Oficial do Projeto Guacamole: https://guacamole.apache.org/
#
# Arquivo de configuração dos parâmetros utilizados nesse script
source 00-parametros.sh
#
# Configuração da variável de Log utilizado nesse script
LOG=$LOGSCRIPT
#
# Verificando se o usuário é Root e se a Distribuição é >= 20.04.x 
# [ ] = teste de expressão, && = operador lógico AND, == comparação de string, exit 1 = A maioria 
# dos erros comuns na execução
clear
if [ "$USUARIO" == "0" ] && [ "$UBUNTU" == "20.04" ]
	then
		echo -e "O usuário é Root, continuando com o script..."
		echo -e "Distribuição é >= 20.04.x, continuando com o script..."
		sleep 5
	else
		echo -e "Usuário não é Root ($USUARIO) ou a Distribuição não é >= 20.04.x ($UBUNTU)"
		echo -e "Caso você não tenha executado o script com o comando: sudo -i"
		echo -e "Execute novamente o script para verificar o ambiente."
		exit 1
fi
#
# Verificando o acesso a Internet do servidor Ubuntu Server
# [ ] = teste de expressão, exit 1 = A maioria dos erros comuns na execução
# $? código de retorno do último comando executado, ; execução de comando, 
# opção do comando nc: -z (scan for listening daemons), -w (timeouts), 1 (one timeout), 443 (port)
if [ "$(nc -zw1 google.com 443 &> /dev/null ; echo $?)" == "0" ]
	then
		echo -e "Você tem acesso a Internet, continuando com o script..."
		sleep 5
	else
		echo -e "Você NÃO tem acesso a Internet, verifique suas configurações de rede IPV4"
		echo -e "e execute novamente este script."
		sleep 5
		exit 1
fi
#
# Verificando se a porta 4822 está sendo utilizada no servidor Ubuntu Server
# [ ] = teste de expressão, == comparação de string, exit 1 = A maioria dos erros comuns na execução,
# $? código de retorno do último comando executado, ; execução de comando, 
# opção do comando nc: -v (verbose), -z (DCCP mode), &> redirecionador de saída de erro
if [ "$(nc -vz 127.0.0.1 $PORTGUACAMOLE &> /dev/null ; echo $?)" == "0" ]
	then
		echo -e "A porta: $PORTGUACAMOLE já está sendo utilizada nesse servidor."
		echo -e "Verifique o serviço associado a essa porta e execute novamente esse script.\n"
		sleep 5
		exit 1
	else
		echo -e "A porta: $PORTGUACAMOLE está disponível, continuando com o script..."
		sleep 5
fi
#
# Verificando se as dependências do Guacamole estão instaladas
# opção do dpkg: -s (status), opção do echo: -e (interpretador de escapes de barra invertida), 
# -n (permite nova linha), || (operador lógico OU), 2> (redirecionar de saída de erro STDERR), 
# && = operador lógico AND, { } = agrupa comandos em blocos, [ ] = testa uma expressão, retornando 
# 0 ou 1, -ne = é diferente (NotEqual)
echo -n "Verificando as dependências do Guacamole, aguarde... "
	for name in $GUACAMOLERDEP
	do
  		[[ $(dpkg -s $name 2> /dev/null) ]] || { 
              echo -en "\n\nO software: $name precisa ser instalado. \nUse o comando 'apt install $name'\n";
              deps=1; 
              }
	done
		[[ $deps -ne 1 ]] && echo "Dependências.: OK" || { 
            echo -en "\nInstale as dependências acima e execute novamente este script\n";
			echo -en "Recomendo utilizar o script: 03-dns.sh para resolver as dependências."
			echo -en "Recomendo utilizar o script: 10-tomcat.sh para resolver as dependências."
            exit 1; 
            }
		sleep 5
#
# Verificando se o script já foi executado mais de 1 (uma) vez nesse servidor
# OBSERVAÇÃO IMPORTANTE: OS SCRIPTS FORAM PROJETADOS PARA SEREM EXECUTADOS APENAS 1 (UMA) VEZ
if [ -f $LOG ]
	then
		echo -e "Script $0 já foi executado 1 (uma) vez nesse servidor..."
		echo -e "É recomendado analisar o arquivo de $LOG para informações de falhas ou erros"
		echo -e "na instalação e configuração do serviço de rede utilizando esse script..."
		echo -e "Todos os scripts foram projetados para serem executados apenas 1 (uma) vez."
		sleep 5
		exit 1
	else
		echo -e "Primeira vez que você está executando esse script, tudo OK, agora só aguardar..."
		sleep 5
fi
#
# Script de instalação do Apache Guacamole Server e Client no GNU/Linux Ubuntu Server 20.04.x
# opção do comando echo: -e (enable interpretation of backslash escapes), \n (new line)
# opção do comando hostname: -d (domain)
# opção do comando date: + (format), %d (day), %m (month), %Y (year 1970), %H (hour 24), %M (minute 60)
# opção do comando cut: -d (delimiter), -f (fields)
echo -e "Início do script $0 em: $(date +%d/%m/%Y-"("%H:%M")")\n" &>> $LOG
clear
echo
#
echo -e "Instalação do Apache Guacamole Server e Client no GNU/Linux Ubuntu Server 20.04.x\n"
echo -e "Porta padrão utilizada pelo Apache Tomcat9...: TCP 8080"
echo -e "Porta padrão utilizada pelo Guacamole Server.: TCP 4822\n"
echo -e "Após a instalação do Apache Guacamole acesse a URL: http://$(hostname -d | cut -d' ' -f1):8080/guacamole\n"
echo -e "Aguarde, esse processo demora um pouco dependendo do seu Link de Internet...\n"
sleep 5
#
echo -e "Adicionando o Repositório Universal do Apt, aguarde..."
	# Universe - Software de código aberto mantido pela comunidade:
	# opção do comando: &>> (redirecionar a saída padrão)
	add-apt-repository universe &>> $LOG
echo -e "Repositório adicionado com sucesso!!!, continuando com o script...\n"
sleep 5
#
echo -e "Adicionando o Repositório Multiversão do Apt, aguarde..."
	# Multiverse – Software não suportado, de código fechado e com patente: 
	# opção do comando: &>> (redirecionar a saída padrão)
	add-apt-repository multiverse &>> $LOG
echo -e "Repositório adicionado com sucesso!!!, continuando com o script...\n"
sleep 5
#
echo -e "Adicionando o Repositório Restrito do Apt, aguarde..."
	# Restricted - Software de código fechado oficialmente suportado:
	# opção do comando: &>> (redirecionar a saída padrão)
	add-apt-repository restricted &>> $LOG
echo -e "Repositório adicionado com sucesso!!!, continuando com o script...\n"
sleep 5
#
echo -e "Atualizando as listas do Apt, aguarde..."
	#opção do comando: &>> (redirecionar a saída padrão)
	apt update &>> $LOG
echo -e "Listas atualizadas com sucesso!!!, continuando com o script...\n"
sleep 5
#
echo -e "Atualizando todo o sistema operacional, aguarde..."
	# opção do comando: &>> (redirecionar a saída padrão)
	# opção do comando apt: -y (yes)
	apt -y upgrade &>> $LOG
	apt -y dist-upgrade &>> $LOG
	apt -y full-upgrade &>> $LOG
echo -e "Sistema atualizado com sucesso!!!, continuando com o script...\n"
sleep 5
#
echo -e "Removendo todos os software desnecessários, aguarde..."
	# opção do comando: &>> (redirecionar a saída padrão)
	# opção do comando apt: -y (yes)
	apt -y autoremove &>> $LOG
echo -e "Software removidos com sucesso!!!, continuando com o script...\n"
sleep 5
#
echo -e "Iniciando a Instalação e Configuração do Apache Guacamole Server e Client, aguarde...\n"
sleep 5
#
echo -e "Instalando as Dependências do Apache Guacamole Server, aguarde..."
	# opção do comando: &>> (redirecionar a saída padrão)
	# opção do comando apt: -y (yes)
	apt -y install $GUACAMOLEINSTALL &>> $LOG
echo -e "Dependências instaladas com sucesso!!!, continuando com o script...\n"
sleep 5
#
echo -e "Fazendo o download do Apache Guacamole Server do site Oficial, aguarde..."
	# opção do comando: &>> (redirecionar a saída padrão)
	# opção do comando rm: -v (verbose), -f (force), -R (recursive)
	# opção do comando wget: -O (output document file)
	rm -v guacamole.tar.gz &>> $LOG
	rm -Rfv guacamole-server-*/ &>> $LOG
	wget $GUACAMOLESERVER -O guacamole.tar.gz &>> $LOG
echo -e "Download do Apache Guacamole Server feito com sucesso!!!, continuando com o script...\n"
sleep 5
#
echo -e "Descompactando o Apache Guacamole Server, aguarde..."
	# opção do comando: &>> (redirecionar a saída padrão)
	# opção do comando tar: -z (gzip), -x (extract), -v (verbose), -f (file)
	tar -zxvf guacamole.tar.gz &>> $LOG
echo -e "Apache Guacamole Server descompactado com sucesso!!!, continuando com o script...\n"
sleep 5
#
echo -e "Instalando o Apache Guacamole Server, aguarde esse processo demora um pouco..."
	# opção do comando: &>> (redirecionar a saída padrão)
	# opção do comando autoreconf: -f (force), -i (install)
	cd guacamole-server-*/ &>> $LOG
		autoreconf -fi &>> $LOG
		./configure --with-init-dir=/etc/init.d &>> $LOG
		make &>> $LOG
		make install &>> $LOG
		ldconfig &>> $LOG
	cd .. &>> $LOG
echo -e "Apache Guacamole Server instalado com sucesso!!!, continuando com o script...\n"
sleep 5
#
echo -e "Iniciando o serviço do Apache Guacamole Server, aguarde..."
	# opção do comando: &>> (redirecionar a saída padrão)
	systemctl enable guacd &>> $LOG
	systemctl start guacd &>> $LOG
echo -e "Serviço do Apache Guacamole Server iniciado com sucesso!!!, continuando com o script...\n"
sleep 5
#
echo -e "Verificando o serviço do Apache Guacamole Server, aguarde..."
	systemctl status guacd | grep Active
echo -e "Serviço verificado com sucesso!!!, continuando com o script...\n"
sleep 5
#
echo -e "Criando os diretórios e baixando o Apache Guacamole Client, aguarde..."
	# opção do comando: &>> (redirecionar a saída padrão)
	# opção do comando mkdir: -v (verbose), {} (block command)
	# opção do comando {}: Agrupa comandos em um bloco
	# opção do comando wget: -O (output document file)
	# opção do comando ln: -s (symbolic), -v (verbose)
	mkdir -v /etc/guacamole &>> $LOG
	mkdir -v /etc/guacamole/{extensions,lib} &>> $LOG
	wget $GUACAMOLECLIENT -O /etc/guacamole/guacamole.war &>> $LOG
	ln -sv /etc/guacamole/guacamole.war $PATHWEBAPPS &>> $LOG
	ln -sv /etc/guacamole $PATHTOMCAT.guacamole &>> $LOG
echo -e "Download do Apache Guacamole Client feito com sucesso!!!, continuando com o script...\n"
sleep 5
#
echo -e "Atualizando os arquivos de configuração do Apache Guacamole Client, aguarde..."
	# opção do comando: &>> (redirecionar a saída padrão)
	# opção do comando mv: -v (verbose)
	# opção do comando cp: -v (verbose)
	# opção do bloco e agrupamentos {}: (Agrupa comandos em um bloco)
	mv -v /etc/default/tomcat9 /etc/default/tomcat9.old &>> $LOG
	cp -v conf/guacamole/{guacamole.properties,user-mapping.xml} /etc/guacamole/ &>> $LOG
	cp -v conf/guacamole/tomcat9 /etc/default/ &>> $LOG
echo -e "Arquivos atualizados com sucesso!!!, continuando com o script...\n"
sleep 5
#
echo -e "Editando o arquivo de configuração guacamole.properties, pressione <Enter> para continuar"
	# opção do comando read: -s (Do not echo keystrokes)
	read -s
	vim /etc/guacamole/guacamole.properties
echo -e "Arquivo editado com sucesso!!!, continuando com o script...\n"
sleep 5
#
echo -e "Editando o arquivo de configuração user-mapping.xml, pressione <Enter> para continuar"
	# opção do comando read: -s (Do not echo keystrokes)
	read -s
	vim /etc/guacamole/user-mapping.xml
echo -e "Arquivo editado com sucesso!!!, continuando com o script...\n"
sleep 5
#
echo -e "Editando o arquivo de configuração tomcat9, pressione <Enter> para continuar"
	# opção do comando read: -s (Do not echo keystrokes)
	read -s
	vim /etc/default/tomcat9
echo -e "Arquivo editado com sucesso!!!, continuando com o script...\n"
sleep 5
#
echo -e "Reiniciando os Serviços do Tomcat9 e do Apache Guacamole, aguarde..."
	# opção do comando: &>> (redirecionar a saída padrão)
	systemctl restart tomcat9 &>> $LOG
	systemctl restart guacd &>> $LOG
echo -e "Serviços reinicializados com sucesso!!!, continuando com o script...\n"
sleep 5
#
echo -e "Verificando os serviços do Tomcat9 e do Apache Guacamole, aguarde..."
	echo -e "Tomcat9..: $(systemctl status tomcat9 | grep Active)"
	echo -e "Guacamole: $(systemctl status guacd | grep Active)"
echo -e "Serviços verificado com sucesso!!!, continuando com o script...\n"
sleep 5
#
echo -e "Verificando as portas de conexões do Apache Tomcat9 e do Guacamole Server, aguarde..."
	# opção do comando lsof: -n (inhibits the conversion of network numbers to host names for 
	# network files), -P (inhibits the conversion of port numbers to port names for network files), 
	# -i (selects the listing of files any of whose Internet address matches the address specified 
	# in i), -s (alone directs lsof to display file size at all times)
	lsof -nP -iTCP:'8080,4822' -sTCP:LISTEN
echo -e "Portas verificadas com sucesso!!!, continuando com o script...\n"
sleep 5
#
echo -e "Instalação do Apache Guacamole Server e Client feita com Sucesso!!!."
	# script para calcular o tempo gasto (SCRIPT MELHORADO, CORRIGIDO FALHA DE HORA:MINUTO:SEGUNDOS)
	# opção do comando date: +%T (Time)
	HORAFINAL=$(date +%T)
	# opção do comando date: -u (utc), -d (date), +%s (second since 1970)
	HORAINICIAL01=$(date -u -d "$HORAINICIAL" +"%s")
	HORAFINAL01=$(date -u -d "$HORAFINAL" +"%s")
	# opção do comando date: -u (utc), -d (date), 0 (string command), sec (force second), +%H (hour), %M (minute), %S (second), 
	TEMPO=$(date -u -d "0 $HORAFINAL01 sec - $HORAINICIAL01 sec" +"%H:%M:%S")
	# $0 (variável de ambiente do nome do comando)
	echo -e "Tempo gasto para execução do script $0: $TEMPO"
echo -e "Pressione <Enter> para concluir o processo."
# opção do comando date: + (format), %d (day), %m (month), %Y (year 1970), %H (hour 24), %M (minute 60)
echo -e "Fim do script $0 em: $(date +%d/%m/%Y-"("%H:%M")")\n" &>> $LOG
read
exit 1
