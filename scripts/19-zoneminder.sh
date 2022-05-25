#!/bin/bash
# Autor: Jefferson Augusto
# Site: www.totustuuscomunicacao.com.br
# Facebook: facebook.com/totustuuscomunicacao
# 
# 
# Linkedin: https://www.linkedin.com/in/jefferson-augusto-5759b87b/
# Instagram: https://www.instagram.com/jeffersongontijo765/
# Github: https://github.com/totustuuscomunicacao
# Data de criação: 03/12/2021
# Data de atualização: 12/01/2022
# Versão: 0.09
# Testado e homologado para a versão do Ubuntu Server 20.04.x LTS x64x
# Testado e homologado para a versão do ZoneMinder 1.37.x
#
# ZoneMinder é um sistema de CFTV (Circuito Fechado de televisão) Open Source, desenvolvido 
# para sistemas operacionais Linux. Ele é liberado sob os termos da GNU General Public 
# License (GPL). Os usuários controlam o ZoneMinder através de uma interface baseada na Web; 
# também fornece LiveCD. O aplicativo pode usar câmeras padrão (por meio de uma placa de 
# captura, USB, Firewire etc.) ou dispositivos de câmera baseados em IP. O software permite 
# três modos de operação: monitoramento (sem gravação), gravação após movimento detectado e 
# gravação permanente.
#
# CCTV / CFTV = (Closed-Circuit Television - Circuito fechado de televisão);
# PTZ Pan/Tilt/Zoom (Uma câmera de rede PTZ oferece funcionalidade de vídeo em rede combinada 
# com o recurso de movimento horizontal, vertical e de zoom - Pan = Panorâmica Horizontal - 
# Tilt = Vertical | Zoom - Aproximar)
#
# Informações que serão solicitadas na configuração via Web do ZoneMinder
# Privacy: Accept: Apply
#
# Site Oficial do Projeto ZoneMinder: https://zoneminder.com/
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
# Verificando se as dependências do ZoneMinder estão instaladas
# opção do dpkg: -s (status), opção do echo: -e (interpretador de escapes de barra invertida), 
# -n (permite nova linha), || (operador lógico OU), 2> (redirecionar de saída de erro STDERR), 
# && = operador lógico AND, { } = agrupa comandos em blocos, [ ] = testa uma expressão, retornando 
# 0 ou 1, -ne = é diferente (NotEqual)
echo -n "Verificando as dependências do ZoneMinder, aguarde... "
	for name in $ZONEMINDERDEP
	do
  		[[ $(dpkg -s $name 2> /dev/null) ]] || { 
              echo -en "\n\nO software: $name precisa ser instalado. \nUse o comando 'apt install $name'\n";
              deps=1; 
              }
	done
		[[ $deps -ne 1 ]] && echo "Dependências.: OK" || { 
            echo -en "\nInstale as dependências acima e execute novamente este script\n";
			echo -en "Recomendo utilizar o script: 03-dns.sh para resolver as dependências."
			echo -en "Recomendo utilizar o script: 07-lamp.sh para resolver as dependências."
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
# Script de instalação do ZoneMinder no GNU/Linux Ubuntu Server 20.04.x
# opção do comando echo: -e (enable interpretation of backslash escapes), \n (new line)
# opção do comando hostname: -d (domain)
# opção do comando date: + (format), %d (day), %m (month), %Y (year 1970), %H (hour 24), %M (minute 60)
# opção do comando cut: -d (delimiter), -f (fields)
echo -e "Início do script $0 em: $(date +%d/%m/%Y-"("%H:%M")")\n" &>> $LOG
clear
echo
#
echo -e "Instalação do ZoneMinder no GNU/Linux Ubuntu Server 20.04.x\n"
echo -e "Após a instalação do ZoneMinder acessar a URL: https://zm.$(hostname -d | cut -d ' ' -f1)/\n"
echo -e "Aguarde, esse processo demora um pouco dependendo do seu Link de Internet..."
sleep 5
echo
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
	# opção do comando: &>> (redirecionar a saída padrão)
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
	apt -y autoclean &>> $LOG
echo -e "Software removidos com sucesso!!!, continuando com o script...\n"
sleep 5
#
echo -e "Iniciando a Instalação e Configuração do ZoneMinder, aguarde...\n"
sleep 5
#
echo -e "Adicionando o PPA do ZoneMinder, aguarde..."
	# opção do comando: &>> (redirecionar a saída padrão)
	# opção do comando echo |: (faz a função do Enter)
	echo | sudo add-apt-repository $ZONEMINDER &>> $LOG
echo -e "PPA adicionado com sucesso!!!, continuando com o script...\n"
sleep 5
#
echo -e "Atualizando novamente as listas do Apt com o novo PPA, aguarde..."
	# opção do comando: &>> (redirecionar a saída padrão)
	apt update &>> $LOG
echo -e "Listas atualizadas com sucesso!!!, continuando com o script...\n"
sleep 5
#
echo -e "Editando as configurações MySQL mysqld.cnf, pressione <Enter> para continuar"
	# opção do comando: &>> (redirecionar a saída padrão)
	# opção do comando read: -s (Do not echo keystrokes)
	read -s
	vim /etc/mysql/mysql.conf.d/mysqld.cnf 
	systemctl restart mysql &>> $LOG
echo -e "Arquivo do MySQL editado com sucesso!!!, continuando com o script...\n"
sleep 5
#
echo -e "Editando as configurações do PHP php.ini, pressione <Enter> para continuar"
	# opção do comando: &>> (redirecionar a saída padrão)
	# opção do comando read: -s (Do not echo keystrokes)
	read -s
	vim /etc/php/7.4/apache2/php.ini
	systemctl restart apache2 &>> $LOG
echo -e "Arquivo do PHP editado com sucesso!!!, continuando com o script...\n"
sleep 5
#
echo -e "Instalando o ZoneMinder, esse processo demora um pouco, aguarde..."
	# opção do comando: &>> (redirecionar a saída padrão)
	# opção do comando apt: -y (yes)
	apt -y install zoneminder &>> $LOG
echo -e "ZoneMinder instalado com sucesso!!!, continuando com o script...\n"
sleep 5
#
echo -e "Criando o Banco de Dados do ZoneMinder, aguarde..."
	# opção do comando: &>> (redirecionar a saída padrão)
	# opção do comando mysql: -u (user), -p (password), -e (execute), < (Redirecionador de Saída STDOUT)
	#mysql -u $USERMYSQL -p$SENHAMYSQL < $CREATE_DATABASE_ZONEMINDER &>> $LOG
	#mysql -u $USERMYSQL -p$SENHAMYSQL -e "$DROP_DATABASE_ZONEMINDER" mysql &>> $LOG
	mysql -u $USERMYSQL -p$SENHAMYSQL -e "$ALTER_USER_DATABASE_ZONEMINDER" mysql &>> $LOG
	mysql -u $USERMYSQL -p$SENHAMYSQL -e "$GRANT_DATABASE_ZONEMINDER" mysql &>> $LOG
	mysql -u $USERMYSQL -p$SENHAMYSQL -e "$GRANT_ALL_DATABASE_ZONEMINDER" mysql &>> $LOG
	mysql -u $USERMYSQL -p$SENHAMYSQL -e "$FLUSH_ZONEMINDER" mysql &>> $LOG
	#mysql -u $USERMYSQL -p$SENHAMYSQL < $CREATE_DATABASE_ZONEMINDER &>> $LOG
echo -e "Banco de Dados criado com sucesso!!!, continuando com o script...\n"
sleep 5
#
echo -e "Alterando as permissões dos arquivos e diretórios do ZoneMinder, aguarde..."
	# opção do comando: &>> (redirecionar a saída padrão)
	# opções do comando chmod: -v (verbose), 740 (dono=RWX,grupo=R,outro=)
	# opções do comando chown: -v (verbose), -R (recursive), root (dono), www-data (grupo)
	# opções do comando usermod: -a (append), -G (group), video (grupo), www-data (user)
	chmod -v 740 /etc/zm/zm.conf &>> $LOG
	chown -v root.www-data /etc/zm/zm.conf &>> $LOG
	chown -Rv www-data.www-data /usr/share/zoneminder/ &>> $LOG
	usermod -a -G video www-data &>> $LOG
echo -e "Permissões alteradas com sucesso com sucesso!!!, continuando com o script...\n"
sleep 5
#
echo -e "Habilitando os recursos do Apache2 para o ZoneMinder, aguarde..."
	# opção do comando: &>> (redirecionar a saída padrão)
	# a2enmod (Apache2 Enable Mode), a2enconf (Apache2 Enable Conf)
	a2enmod cgi &>> $LOG
	a2enmod rewrite &>> $LOG
	a2enmod headers &>> $LOG
	a2enmod expires &>> $LOG
	a2enconf zoneminder &>> $LOG
	systemctl restart apache2 &>> $LOG
echo -e "Recurso habilitado com sucesso!!!, continuando com o script...\n"
sleep 5
#
echo -e "Habilitando o Serviço do ZoneMinder, aguarde..."
	# opção do comando: &>> (redirecionar a saída padrão)
	systemctl enable zoneminder &>> $LOG
	systemctl restart zoneminder &>> $LOG
echo -e "Serviço habilitado com sucesso!!!, continuando com o script...\n"
sleep 5
#
echo -e "Verificando o serviço do ZoneMinder, aguarde..."
	echo -e "Zoneminder: $(systemctl status zoneminder | grep Active)"
echo -e "Serviço verificado com sucesso!!!, continuando com o script...\n"
sleep 5
#
echo -e "Instalação do ZoneMinder feita com Sucesso!!!"
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