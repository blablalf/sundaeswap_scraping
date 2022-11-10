#Installation of needed programs
echo "Run program installer (y)/n: "
read install_requested
if [[ install_requested == 'n' ]]; then
    bash ./ressources/install.sh
fi

#Scraping and parsing
node ./ressources/source_sundae.js #| grep "CLAP"