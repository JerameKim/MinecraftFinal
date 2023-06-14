#!/bin/bash 
yum update -y 
sudo yum install -y java-17-amazon-corretto-devel.x86_64
sudo su 
mkdir /opt/minecraft
mkdir /opt/minecraft/server
cd /opt/minecraft/server
# TODO: Make sure this link is updated with the Minecraft Server download link
wget https://piston-data.mojang.com/v1/objects/84194a2f286ef7c14ed7ce0090dba59902951553/server.jar

cd /etc/systemd/system/

cat >minecraft.service<<EOF
[Unit]
Description=Minecraft Server
After=network.target

[Service]
WorkingDirectory=/opt/minecraft/server
ExecStart=/usr/bin/java -Xmx1024M -Xms1024M -jar server.jar nogui
Restart=always

[Install]
WantedBy=multi-user.target
EOF

chmod +xw /etc/systemd/system/minecraft.service
sudo systemctl enable minecraft 

cd /opt/minecraft/server

java -Xmx1024M -Xms1024M -jar server.jar nogui

cat >eula.txt<<EOF
#By changing the setting below to TRUE you are indicating your agreement to our EULA (https://aka.ms/MinecraftEULA).
#Tue Jun 13 00:06:29 UTC 2023
eula=true
EOF

sudo java -Xmx1024M -Xms1024M -jar server.jar nogui
