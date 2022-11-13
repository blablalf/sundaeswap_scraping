#!/bin/bash

#MacOS install
if [[ $OSTYPE == 'darwin'* ]]; then
    echo 'macOS_detected'
    which -s brew
    if [[ $? != 0 ]] ; then
        echo 'Installing brew'
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo 'brew_detected'
    fi
    echo 'Installing node & npm & screen with brew'
    brew install node

#Linux install
elif [[ $OSTYPE == 'linux'* ]]; then
    echo 'linux_detected'
    echo 'Installing node & npm with apt'
    sudo apt install nodejs npm -y
    curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
fi

#Node dependencies installation
echo 'Installing node dependencies'
cd ./ressources && npm i

#Getting Node path
echo 'Getting node path'
node_path=$(which node) #getting node path
cat .env | sed -e "/node_path/d" > ../.env #deleting eventual old line
echo "node_path=$node_path" >> ../.env #adding the new one
