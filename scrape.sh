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

#Get price data if asked
if [[ $(cat settings.txt | sed -n -e "s/get_price *= *//p") == 'true' ]]; then
    lite_asset_code=$(echo $code_to_parse | egrep -o "$asset_to_follow/ADA.{255}.{255}" | grep -o "<div class=\"sc-bdvvtL sc-1aj876m-6 dfkUWV biWbyS\">.*</div>")
    asset_decimal=$(echo $lite_asset_code | grep -o "<span class=\"sc-lbhJGD hfhuXO\">.*</span> ₳" | sed -n 's:.*huXO">\(.*\)</spa.*:\1:p')
    asset_main_val=$(echo $lite_asset_code | grep -o "<span><span>.*</span><span" | sed -n 's:.*<span>\(.*\)</spa.*:\1:p')
    asset_val=$asset_main_val$asset_decimal'₳'

    #Echo the value if asked into the settings
    if [[ $(cat settings.txt | sed -n -e "s/echo_data *= *//p") == 'true' ]]; then
        echo "asset_price="$asset_val
    fi

    #Displaying asset val with telegram bot
    bot_token=$(cat .env | sed -ne 's/bot_token *= *//p')
    chat_id=$(cat .env | sed -ne 's/chat_id *= *//p')
    message_url="https://api.telegram.org/bot"$bot_token"/sendMessage?chat_id="$chat_id"&text="$asset_to_follow"_price="$asset_val

    if [[ $(cat settings.txt | sed -n -e "s/get_24h_datas *= *//p") == 'true' ]]; then
        #Calcul the price variation
        #TODO

        #Echo the value if asked into the settings
        if [[ $(cat settings.txt | sed -n -e "s/echo_data *= *//p") == 'true' ]]; then
            #TODO
            echo "price_variation=\$the_price_variation"
        fi
    fi

fi

#24h datas
if [[ $(cat settings.txt | sed -n -e "s/get_24h_datas *= *//p") == 'true' ]]; then
    #We get more code because we gonna retrieve more datas
    full_asset_code=$(echo $code_to_parse | egrep -o "$asset_to_follow/ADA.{255}.{255}.{255}.{255}.{255}.{255}")

    #Getting the total locked $followed asset
    total_locked_asset_code=$(echo $full_asset_code | grep -o "Total Locked $asset_to_follow.*Total Locked ADA")
    total_locked_asset_main=$(echo $total_locked_asset_code | sed -n 's:.*WbyS"><span>\(.*\)</span><s.*:\1:p' | sed 's:,::g')
    total_locked_asset_decimal=$(echo $total_locked_asset_code | sed -n 's:.*uXO">\(.*\)</s.*:\1:p')
    total_locked_asset=$total_locked_asset_main$total_locked_asset_decimal' '$asset_to_follow
    #Echo the value if asked into the settings
    if [[ $(cat settings.txt | sed -n -e "s/echo_data *= *//p") == 'true' ]]; then
        echo "total_locked_$asset_to_follow="$total_locked_asset
    fi
    
    #Getting the total locked ada asset
    total_locked_ada_code=$(echo $full_asset_code | grep -o "Total Locked ADA.*Volu")
    total_locked_ada_main=$(echo $total_locked_ada_code | sed -n 's:.*WbyS"><span>\(.*\)</span><s.*:\1:p' | sed 's:,::g')
    total_locked_ada_decimal=$(echo $total_locked_ada_code | sed -n 's:.*uXO">\(.*\)</s.*:\1:p')
    total_locked_ada=$total_locked_ada_main$total_locked_ada_decimal' ₳'
    #Echo the value if asked into the settings
    if [[ $(cat settings.txt | sed -n -e "s/echo_data *= *//p") == 'true' ]]; then
        echo "total_locked_ADA="$total_locked_ada
    fi

    #Getting the 24h volume
    #Sometimes, there are no volume, the first if permits to detect that
    #Then, in order to be able to get the volume we need to decompose the multiples component values
    #For example, for the value 1 096 634,54 -> there are these components |1|, |096|, |634| and |54|
    #Of course there the integers parts, and the decimal one
    #So we count the integers parts and then we parse them
    volume=""
    if [[ $(echo $full_asset_code | grep -o "Volume 24H.*More") ]]; then
        volume="no_volume"
    else
        volume_main=""
        volume_code=$(echo $full_asset_code | grep -o "Volume 24H.*₳")
        for i in {1..$(echo $full_asset_code | grep -o "part__integer" | wc -l)}
        do
            volume_main=$(echo $volume_code | sed 's:.*part__integer">\([0-9]*\)</span><span cl.*:\1:g')$volume_main
            volume_code=$(echo $volume_code | grep -o "Volume 24H.*$volume_main")
        done
        volume_decimal=$(echo $full_asset_code | sed 's:.*_fraction">\([0-9]*\)</span><span.*:\1:g')
        volume=$volume_main'.'$volume_decimal' ₳'
    fi
    #Echo the value if asked into the settings
    if [[ $(cat settings.txt | sed -n -e "s/echo_data *= *//p") == 'true' ]]; then
        echo "24h_Volume="$volume
    fi
    
fi

if [[ $(cat settings.txt | sed -n -e "s/send_telegram *= *//p") == 'true' ]]; then

    #If we have got the price, let's send it
    if [[ $(cat settings.txt | sed -n -e "s/get_price *= *//p") == 'true' ]]; then
        #Send the message
        curl $message_url
    fi

    #If we want the 24 hour datas, let's send them
    if [[ $(cat settings.txt | sed -n -e "s/get_24h_datas *= *//p") == 'true' ]]; then

        #If we have got the price, let's send the evolution of it
        if [[ $(cat settings.txt | sed -n -e "s/get_price *= *//p") == 'true' ]]; then
            #Send the the price variation

            echo \#Send the the price variation
        fi
    fi
fi

#EXAMPLE OF CALCULATION ON IT
#add_one=$(echo "$asset_val + 1" | bc)
#echo $add