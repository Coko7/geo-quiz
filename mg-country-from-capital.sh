#!/usr/bin/env bash

source source_me.sh

# External args
MAIN_REGION=$1
DIFFICULTY=$2

seen=`get_seen_country_names`
seen_len=`echo $seen | jq 'length'`

countries=`get_countries $MAIN_REGION true`
countries_len=`echo $countries | jq 'length'`
if [ "$countries_len" = 0 ]; then
    exit 2
fi

game_status_header="[$seen_len/$countries_len]"

remain_countries=`filter_countries "$countries" "$seen"`
remain_country_names=`echo $remain_countries | jq -cr '.[].name.common'`

pick=`get_rand_entry "$remain_countries"`
pick_country_name=`echo $pick | jq -cr '.name.common'`

echo $seen | jq ". += [\"$pick_country_name\"]" > $SEEN_FILE

pick_capital=`echo $pick | jq -r '.capital[0]'`
pick_subregion=`echo $pick | jq -r '.subregion'`

case "$DIFFICULTY" in
    Easy)
        COUNTRY_NAMES=`echo -e $remain_countries \
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
    echo -e "${GRAY}[$((seen_len))/$countries_len] Correct! ${RESET}$pick_capital${GRAY} is the capital of: ${RESET}$answer${GRAY}! ${GREEN}+1 point${RESET}"

    if [ "$seen_len" = "$countries_len" ]; then
        exit 3
    fi

    exit 0

else
    echo -e "${RED}LOSER! ${GRAY}${ITALIC}$pick_capital is the capital of: $pick_country_name...${RESET}"
    exit 1
fi
