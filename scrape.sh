#!/bin/bash

#Installation of needed programs
if [[ $(cat settings.txt | sed -n -e "s/ask_for_install *= *//p") == 'true' ]]; then
    echo "Run program installer (y)/n: "
    read install_requested
    if [ $install_requested != 'n' ]; then
        bash ./ressources/install.sh
    fi
fi

#Get the asset to follow inside the settings file
asset_to_follow=$(cat settings.txt | sed -n -e 's/asset_to_follow *= *//p')

#Scraping and parsing
node ./ressources/source_sundae.js | egrep -o "$asset_to_follow/ADA.{255}.{255}"