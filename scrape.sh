#!/bin/bash

#Installation of needed programs
if grep -qv 'ask_for_install\s*=\s*false' settings.txt; then
    echo "Run program installer (y)/n: "
    read install_requested
    if [[ install_requested != 'n' ]]; then
        bash ./ressources/install.sh
    fi
fi


#Scraping and parsing
node ./ressources/source_sundae.js #| grep "CLAP"