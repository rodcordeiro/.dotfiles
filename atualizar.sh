#!/usr/bin/env bash

# Place it on /usr/local/bin/

apt-get update -y
apt-get upgrade -y
apt-get --fix-broken install -y
apt-get --fix-missing install -y
apt-get update -y
apt-get upgrade -y
apt-get check -y
apt-get dist-upgrade -y
apt-get update -y
apt-get upgrade -y
apt-get autoremove -y
apt-get autoclean -y

# Lista as dependencias com sugestoes e recomendacoes
dependencies=$(apt-cache depends gedit)

# Instala as recomendacoes
recomendacoes=$(echo $dependencies | grep "Recomenda" | cut -d":" -f2)
for dado in $recomendacoes; do
  if [ $dado != "Recomenda:" ]; then
    apt-get install $dado -y
  fi
done;

# Instala as sugestoes
sugestoes=$(echo $dependencies | grep "Sugere" | cut -d":" -f2)
for dado in $sugestoes; do
  if [ $dado != "Sugere:" ]; then
    apt-get install $dado -y
  fi
done;


#wget -c https://github.com/danielmiessler/SecLists/archive/master.zip -O /usr/share/wordlists/SecList.zip 
#unzip -o /usr/share/wordlists/SecList.zip -d /usr/share/wordlists/SecList
#folder=$(ls /usr/share/wordlists/SecList)
#mv -fu /usr/share/wordlists/SecList/$folder/* /usr/share/wordlists/
#rm -f /usr/share/wordlists/SecList.zip /usr/share/wordlists/*.md /usr/shares/wordlists/LICENSE






apt-get update -y
apt-get autoremove -y
apt-get autoclean -y
