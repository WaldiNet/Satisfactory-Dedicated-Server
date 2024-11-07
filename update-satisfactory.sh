#!/bin/bash

sudo systemctl stop satisfactory
steamcmd +force_install_dir {GAME_SERVER_DIR}/{SATISFACTORY_SERVER_DIR_NAME} +login anonymous +app_update 1690800 validate +quit
sudo systemctl start satisfactory