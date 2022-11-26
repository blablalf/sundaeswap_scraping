#!/bin/bash

cd $(dirname $0) #just to be sure that we would be in the correct dir

#Installation of needed programs
if [[ $(cat settings.txt | sed -n -e "s/ask_for_install *= *//p") == 'true' ]]; then
    echo "Run program installer (y)/n: "
    read response
    if [[ $response != 'n' ]]; then
        bash ./ressources/install.sh
    fi

    #Cronjob setting
    echo "Run the cronjob install (y)/n: "
    read response
    if [[ $response != 'n' ]]; then
        echo "Enter scrape.sh directory path to be able to automatically launch the script (without \" or ' characters): "
        read response
        echo "response"$response
        if [[ $(cat settings.txt | sed -n -e "s/price_min_interval *= *//p") != 1 ]]; then
            price_min_interval=$(cat settings.txt | sed -ne 's/price_min_interval *= *//p')
            echo "*/$price_min_interval * * * * $response/scrape.sh" > ./ressources/.cronjobs
        else
            echo "* * * * * $response/scrape.sh" > ./ressources/.cronjobs
        fi
        echo "@daily bash $response/scrape.sh --daily" >> ./ressources/.cronjobs
        echo ""
        echo "Do you want to add the following cronjobs to crontab :"
        cat ./ressources/.cronjobs
        echo ""
        echo "(y)/n: "
        read response
        if [[ $response != 'n' ]]; then
            (crontab -l && cat ./ressources/.cronjobs) | crontab -
        fi
        echo ""
    fi
fi

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
    asset_val=$asset_main_val$asset_decimal
    full_asset_val=$asset_val'₳'

    #Echo the value if asked into the settings
    if [[ $(cat settings.txt | sed -n -e "s/echo_data *= *//p") == 'true' ]]; then
        echo "asset_price="$full_asset_val
    fi

    #Displaying asset val with telegram bot
    bot_token=$(cat .env | sed -ne 's/bot_token *= *//p')
    chat_id=$(cat .env | sed -ne 's/chat_id *= *//p')

    if [[ $1 == '--daily' ]]; then
        #Calcul the price variation
        price_var="0%" #default value in case there is no "yesterday" value

        touch .last_asset_prices #We creates the file if it doesn't exist
        old_promised_value=$(cat .last_asset_prices | sed -n -e "s/$asset_to_follow *= *//p")
        if [[ $old_promised_value =~ [0-9]*\.[0-9]* ]]; then #So if there is an old value for our asset then...
            if [[ $(echo "$asset_val >= $old_promised_value" | bc) == 1 ]]; then
                sign='﹢'
            else
                sign='' #negative sign is added anyway by bc
            fi
            price_var=$(echo "scale=4; (($asset_val/$old_promised_value)-1)*100" | bc | sed 's/..$//')'%'
            full_price_var=$sign$price_var
        fi
        
        #Updating the price into the appropried file
        cat .last_asset_prices | sed -e "/$asset_to_follow/d" > .last_asset_prices #deleting eventual old line
        echo "$asset_to_follow=$asset_val" >> .last_asset_prices #adding the new one

        #Echo the value if asked into the settings
        if [[ $(cat settings.txt | sed -n -e "s/echo_data *= *//p") == 'true' ]]; then
            echo "last_price_variation=$full_price_var"
        fi
    fi

fi

#24h datas
if [[ $1 == '--daily' ]]; then
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
    total_locked_ada=$total_locked_ada_main$total_locked_ada_decimal
    #Echo the value if asked into the settings
    if [[ $(cat settings.txt | sed -n -e "s/echo_data *= *//p") == 'true' ]]; then
        echo "total_locked_ADA="$total_locked_ada' ₳'
    fi

    #Getting the 24h volume
    #Sometimes, there are no volume, the first if permits to detect that
    #Then, in order to be able to get the volume we need to decompose the multiples component values
    #For example, for the value 1 096 634,54 -> there are these components |1|, |096|, |634| and |54|
    #Of course there the integers parts, and the decimal one
    #So we count the integers parts and then we parse them
    if [[ $(echo $full_asset_code | grep -o "Volume 24H.*More") || $(echo $full_asset_code | grep -o "N/A") ]]; then
        volume="no_volume"
    else
        volume_code=$(echo $full_asset_code | grep -o "Volume 24H.*₳")
        for i in {1..$(($(echo $full_asset_code | grep -o "part__integer" | wc -l)))}
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

    #Base URL
    message_url="https://api.telegram.org/bot"$bot_token"/sendMessage?chat_id="$chat_id"&text="

    #If we have got the price, let's send it
    if [[ $(cat settings.txt | sed -n -e "s/get_price *= *//p") == 'true' ]]; then
        #Send the message
        message_url=$message_url$asset_to_follow"+price+=+"$full_asset_val
    fi

    #If we want the 24 hour datas, let's send them
    if [[ $1 == '--daily' ]]; then
        #If we have got the price, let's send the evolution of it
        if [[ $(cat settings.txt | sed -n -e "s/get_price *= *//p") == 'true' ]]; then
            #Send the the price variation
            message_url=$message_url"%0Alast+price+variation+=$sign$price_var"
        fi

        #Add total locked asset into the message
        message_url=$message_url"%0Atotal+locked+$asset_to_follow+=+"$total_locked_asset_main$total_locked_asset_decimal"+"$asset_to_follow

        #Add total locked ADA into the message
        message_url=$message_url"%0Atotal+locked+ADA+=+"$total_locked_ada"+₳"

        #Add 24h total volume into the message
        message_url=$message_url"%0A24h+Volume+=+"$volume_main'.'$volume_decimal"+₳"
    fi

    #Finally, thend the message
    curl -s $message_url > /dev/null
fi
