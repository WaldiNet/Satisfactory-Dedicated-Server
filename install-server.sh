#!/bin/bash

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

gameServerDir="/opt/GameServer"
satisfactoryServerDirName="SatisfactoryDedicatedServer"

serverQueryPort=15777
serverBeaconPort=15000
serverPort=7777

serviceDir="/etc/systemd/system"

# Read inputs
##################################
read -p "Game-Server directory [${green}${gameServerDir}${reset}]: " input
gameServerDir="${input:-$gameServerDir}"
echo ""

read -p "Satisfactory-Server directory name [${green}${satisfactoryServerDirName}${reset}]: " input
satisfactoryServerDirName="${input:-$satisfactoryServerDirName}"
echo ""

read -p "Server query port [${green}${serverQueryPort}${reset}]: " input
serverQueryPort="${input:-$serverQueryPort}"
echo ""

read -p "Server beacon port [${green}${serverBeaconPort}${reset}]: " input
serverBeaconPort="${input:-$serverBeaconPort}"
echo ""

read -p "Server port [${green}${serverPort}${reset}]: " input
serverPort="${input:-$serverPort}"
echo ""

until read -r -p "Server IP: " serverIp && test "$serverIp" != ""; do
  continue
done
echo ""

read -p "Servce owner user [${green}$USER${reset}]: " input
serviceUser="${input:-$USER}"
echo ""

read -p "Servce owner group [${green}$USER${reset}]: " input
serviceGroup="${input:-$USER}"
echo ""

sudo apt update -y
sudo apt upgrade -y

# Configure firewall
##################################
echo ""
echo "${green}Configuring firewall...${reset}"
echo""
sudo apt install ufw -y
sudo ufw disable

sudo ufw default allow outgoing
sudo ufw default deny incoming

sudo ufw allow ssh comment "SSH"
sudo ufw allow 22/tcp comment "SSH"

sudo ufw allow $serverQueryPort/udp comment "Satisfactory Query"
sudo ufw allow $serverBeaconPort/udp comment "Satisfactory Beacon"
sudo ufw allow $serverPort/tcp comment "Satisfactory Server"
sudo ufw allow $serverPort/udp comment "Satisfactory Server"

#sudo ufw enable

echo ""
echo "${green}Firewall configured! Enable at your own risk after the server setup${reset}"
echo""

# Configure fail2ban
##################################
echo ""
echo "${green}Configuring fail2ban...${reset}"
echo""
sudo apt install fail2ban -y

sudo systemctl restart fail2ban
sudo systemctl enable fail2ban
#sudo systemctl status fail2ban

echo ""
echo "${green}fail2ban configured!${reset}"
echo""

# Prepare  SteamCMD
##################################
echo ""
echo "${green}Preparing SteamCMD...${reset}"
echo""
sudo add-apt-repository multiverse
sudo dpkg --add-architecture i386
sudo apt update -y

sudo apt install steamcmd -y

sudo mkdir $gameServerDir
sudo chown -R "${serviceUser}:${serviceGroup}" $gameServerDir

echo ""
echo "${green}SteamCMD ready!${reset}"
echo""

# Install Satisfactory
##################################
echo ""
echo "${green}Downloading and installing Satisfactory...${reset}"
echo""
steamcmd +force_install_dir "${gameServerDir}/${satisfactoryServerDirName}" +login anonymous +app_update 1690800 validate +quit
echo ""
echo "${green}Satisfactory installed!${reset}"
echo""

# Prepare update script
##################################
echo ""
echo "${green}Prepare server update script...${reset}"
echo""

updateScriptName=update-satisfactory.sh
tmpUpdateScriptName=update-satisfactory.sh.tmp

cp ./$updateScriptName ./$tmpUpdateScriptName

sed -i -e "s/{GAME_SERVER_DIR}/${gameServerDir}/g" ./$tmpUpdateScriptName
sed -i -e "s/{SATISFACTORY_SERVER_DIR_NAME}/${satisfactoryServerDirName}/g" ./$tmpUpdateScriptName

mv ./$tmpUpdateScriptName ~/$updateScriptName

echo ""
echo "${green}Server update script ready!${reset}"
echo""

# Prepare dedicated server service
##################################
echo ""
echo "${green}Prepare server service...${reset}"
echo""

serviceName=satisfactory.service
tmpServiceName=satisfactory.service.tmp

cp ./$serviceName ./$tmpServiceName

sed -i -e "s/{GAME_SERVER_DIR}/${gameServerDir}/g" ./$tmpServiceName
sed -i -e "s/{SATISFACTORY_SERVER_DIR_NAME}/${satisfactoryServerDirName}/g" ./$tmpServiceName
sed -i -e "s/{QUERY_PORT}/${serverQueryPort}/g" ./$tmpServiceName
sed -i -e "s/{BEACON_PORT}/${serverBeaconPort}/g" ./$tmpServiceName
sed -i -e "s/{SERVER_PORT}/${serverPort}/g" ./$tmpServiceName
sed -i -e "s/{SERVER_IP}/${serverIP}/g" ./$tmpServiceName
sed -i -e "s/{USER}/${serviceUser}/g" ./$tmpServiceName
sed -i -e "s/{GROUP}/${serviceGroup}/g" ./$tmpServiceName

sudo mv ./$tmpServiceName $serviceDir/$serviceName 

sudo systemctl daemon-reload
sudo systemctl enable satisfactory

echo ""
echo "${green}Server service ready!${reset}"
echo ""
echo "${green}Use following commands to handle your Satisfactory service:${reset}"
echo ""
echo "${green}systemctl {start | stop | restart | status} satisfactory${reset}"
echo ""
