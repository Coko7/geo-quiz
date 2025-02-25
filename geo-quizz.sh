#!/usr/bin/env bash

RESET="\e[0m"

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
GRAY="\e[37m"

ITALIC="\e[3m"

# External args
MAIN_REGION="$1"
DIFFICULTY="$2"

function get_all_countries() {
    jq '.' ./countries.json
}

function get_seen_country_names() {
    jq '.' ./seen.json
}

seen_countries=`get_seen_country_names`
seen_len=`echo -e "$seen_countries" | jq 'length'`

countries=`get_all_countries | jq --arg region $MAIN_REGION \
    '[.[] | select(.region == $region and .independent == true)]'`
countries_len=`echo -e "$countries" | jq 'length'`
if [ "$countries_len" = 0 ]; then
    exit 2
fi

game_status_header="[$seen_len/$countries_len]"

remain_countries=`echo -e "$countries" \
    | jq --argjson blacklist "$seen_countries" \
    'map(select(.name.common as $name | ($blacklist | index($name) | not)))'`

remain_country_names=`echo -e "$remain_countries" | jq -r '.[].name.common'`

pick=`echo -e "$remain_countries" | jq --argjson r $RANDOM '.[$r % length]'`
pick_country_name=`echo -e "$pick" | jq -r '.name.common'`

echo $seen_countries | jq ". += [\"$pick_country_name\"]" > ./seen.json

pick_capital=`echo -e "$pick" | jq -r '.capital[0]'`
pick_subregion=`echo -e "$pick" | jq -r '.subregion'`

case "$DIFFICULTY" in
    "Easy")
        COUNTRY_NAMES=`echo -e "$remain_countries" \
            | jq -r --arg subregion "$pick_subregion" '.[] | select(.subregion == $subregion) | "\(.flag) \(.name.common)"' \
            | sort`

        header="$pick_capital ($pick_subregion):"
        ;;
    # "Medium")
    # "Hard")
    *)
        COUNTRY_NAMES=`echo -e "$remain_countries" \
            | jq -r --arg region "$MAIN_REGION" '.[] | select(.region == $region) | "\(.flag) \(.name.common)"' \
            | sort`

        header="$pick_capital ($MAIN_REGION):"
        ;;
esac

answer=`echo -e "$COUNTRY_NAMES" \
    | gum filter --header="$game_status_header $header" \
    | cut -d' ' -f2-`

if [ -z "$answer" ]; then
    exit 2
fi

if [ "$answer" = "$pick_country_name" ]; then
    ((seen_len++))
    echo -e "[$((seen_len))/$countries_len] $answer is correct! ${GREEN}+1 point${RESET}"

    if [ "$seen_len" = "$countries_len" ]; then
        exit 3
    fi

    exit 0

else
    echo -e "${RED}LOSER! ${GRAY}${ITALIC}It was: $pick_country_name...${RESET}"
    exit 1
fi
