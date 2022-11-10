if [[ $OSTYPE == 'darwin'* ]]; then
    echo 'macOS_detected'
    which -s brew
    if [[ $? != 0 ]] ; then
        echo 'Installing brew'
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo 'brew_detected'
    fi
    echo 'Installing node & npm with brew'
    brew install node
elif [[ $OSTYPE == 'linux'* ]]; then
    echo 'linux_detected'
    echo 'Installing node & npm with apt'
    sudo apt install nodejs npm -y
fi
echo 'Installing node dependencies'
cd ./ressources && npm i