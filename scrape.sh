#!/bin/bash

cd $(dirname $0) #just to be sure that we would be in the correct dir

#Installation of needed programs
if [[ $(cat settings.txt | sed -n -e "s/ask_for_install *= *//p") == 'true' ]]; then
    echo "Run program installer (y)/n: "
    read install_requested
    if [ $install_requested != 'n' ]; then
        bash ./ressources/install.sh
    fi
fi

#Cronjob setting
#"* * * * * $(dirname $0)/scrape.sh"
#* * * * * screen -dmS scrape bash "$(dirname $0)/scrape.sh"
#echo "* * * * * screen -dmS scrape bash \"$(dirname $0)/scrape.sh\"" > ressources/cron_scrape

#Get the asset to follow inside the settings file
asset_to_follow=$(cat settings.txt | sed -ne 's/asset_to_follow *= *//p')

#Scraping and parsing
node_path=$(cat .env | sed -ne 's/node_path *= *//p') #crontab doesn't know node full path
code_to_parse=$($node_path ./ressources/source_sundae.js)
lite_asset_code=$(echo $code_to_parse | egrep -o "$asset_to_follow/ADA.{255}.{255}" | grep -o "<div class=\"sc-bdvvtL sc-1aj876m-6 dfkUWV biWbyS\">.*</div>")
asset_decimal=$(echo $asset_code | grep -o "<span class=\"sc-lbhJGD hfhuXO\">.*</span> ₳" | sed -n 's:.*huXO">\(.*\)</spa.*:\1:p')
asset_main_val=$(echo $asset_code | grep -o "<span><span>.*</span><span" | sed -n 's:.*<span>\(.*\)</spa.*:\1:p')
asset_val=$asset_main_val$asset_decimal'₳'

#Displaying asset val with telegram bot
bot_token=$(cat .env | sed -ne 's/bot_token *= *//p')
chat_id=$(cat .env | sed -ne 's/chat_id *= *//p')
message_url="https://api.telegram.org/bot"$bot_token"/sendMessage?chat_id="$chat_id"&text="$asset_to_follow"_price="$asset_val

#Send the message
#curl $message_url

#24h datas
if [[ $(cat settings.txt | sed -n -e "s/get_24h_datas *= *//p") == 'true' ]]; then
    #We get more code because we gonna retrieve more datas
    full_asset_code=$(echo $code_to_parse | egrep -o "$asset_to_follow/ADA.{255}.{255}.{255}.{255}.{255}.{255}")

    #Getting the total locked $followed asset
    total_locked_asset_code=$(echo $full_asset_code | grep -o "Total Locked $asset_to_follow.*Total Locked ADA")
    total_locked_asset_main=$(echo $total_locked_asset_code | sed -n 's:.*WbyS"><span>\(.*\)</span><s.*:\1:p' | sed 's:,::g')
    total_locked_asset_decimal=$(echo $total_locked_asset_code | sed -n 's:.*uXO">\(.*\)</s.*:\1:p')
    total_locked_asset=$total_locked_asset_main$total_locked_asset_decimal
    
    #Getting the total locked ada asset
    total_locked_ada_code=$(echo $full_asset_code | grep -o "Total Locked ADA.*Volu")
    total_locked_ada_main=$(echo $total_locked_ada_code | sed -n 's:.*WbyS"><span>\(.*\)</span><s.*:\1:p' | sed 's:,::g')
    total_locked_ada_decimal=$(echo $total_locked_ada_code | sed -n 's:.*uXO">\(.*\)</s.*:\1:p')
    total_locked_ada=$total_locked_ada_main$total_locked_ada_decimal

    #Getting the 24h volume
    volume_code=$(echo $full_asset_code | grep -o "Volume 24H.*₳")

    #on doit boucler nb de fois qu'il y a un match avec "part__integer" et executer :
    volume_main=$(echo $volume_code | sed 's:.*part__integer">\([0-9]*\)</span><span cl.*:\1:g') #ensuite on reprends entre volume_code et la sortie de cette ligne et on la reexecute
    #si la sortie c 095 alors on reprend avec volume_code=$(echo $full_asset_code | grep -o "Volume 24H.*095")


    #total_locked_ada_decimal=$(echo $total_locked_ada_code | sed -n 's:.*uXO">\(.*\)</s.*:\1:p')
    #total_locked_ada=$total_locked_ada_main$total_locked_ada_decimal
    
    echo $volume_main
fi

#EXAMPLE OF CALCULATION ON IT
#add_one=$(echo "$asset_val + 1" | bc)
#echo $add