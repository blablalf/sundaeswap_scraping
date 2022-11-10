echo "Run program installer (y)/n: "
read install_requested
if [[ install_requested != 'n' ]]; then
    bash ./ressources/install.sh
fi
node ./ressources/source_sundae.js | grep clap