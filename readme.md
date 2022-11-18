This is a scraping project to warm up in bash. Since sundaeswap hasn't api to get updated prices, let's do something useful :)

## What you need in order to be able to use this program :
- You need a computer capable to run a web browser because the script use `puppeter` to source the page since it's a react webpage.

## Instructions :
- Before the first run of the program, it would be nice that you define some settings, first go into the `settings.txt`, and define these :
```
#You can't add any comment
ask_for_install = true -> true if you want to be asked to run the installtion script for set up the program (almost mandatory at the first )
asset_to_follow= CLAP -> the asset you want to follow (case sensitive)
get_price=true -> true if you want the price to be recovered at regular intervals
price_min_interval=2 -> define the interval of the previous parameter
echo_data  =true -> true if you want the program to have an output
send_telegram =true -> true if you want to receive the data on telegram (you must define a bot into the .env file)
Don't delete this line :) -> you should have a line return
```
- Define the .env file :
Base yourself on the .env.example file
```
node_path= -> used with puppeteer (and automatically set up with the installation script)
bot_token= -> telegram bot token (see @Botfather)
chat_id= -> telegram bot chat_id (see @Botfather)
```

place yourself into the root of the __project directory__, then start the program on `Linux` (you will need `apt`) or `MacOS` with the following command :
```
./scrape.sh
```
or
```
bash scrape.sh
```
You can also run this script with  `--daily` arg, this will send you additionnal daily data

