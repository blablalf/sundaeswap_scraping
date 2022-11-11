#!/bin/bash

cd $(dirname $0)

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
#* * * * * /Users/blabla/sundaeswap_scraping/scrape.sh

#Get the asset to follow inside the settings file
asset_to_follow=$(cat settings.txt | sed -ne 's/asset_to_follow *= *//p')

#Scraping and parsing
code_to_parse=$(node ./ressources/source_sundae.js)
asset_code=$(echo $code_to_parse | egrep -o "$asset_to_follow/ADA.{255}.{255}" | grep -o "<div class=\"sc-bdvvtL sc-1aj876m-6 dfkUWV biWbyS\">.*</div>")
asset_decimal=$(echo $asset_code | grep -o "<span class=\"sc-lbhJGD hfhuXO\">.*</span> ₳" | sed -n 's:.*huXO">\(.*\)</spa.*:\1:p')
asset_main_val=$(echo $asset_code | grep -o "<span><span>.*</span><span" | sed -n 's:.*<span>\(.*\)</spa.*:\1:p')
asset_val=$asset_main_val$asset_decimal'₳'

#Displaying asset val
message_url="https://api.telegram.org/bot<token>/sendMessage?chat_id=<chatid>&text="$asset_to_follow"_price="$asset_val

#Send the message
curl $message_url

#EXAMPLE OF CALCULATION ON IT
#add_one=$(echo "$asset_val + 1" | bc)
#echo $add