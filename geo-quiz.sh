#!/usr/bin/env bash

RESET="\e[0m"

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
GRAY="\e[37m"

ITALIC="\e[3m"

SEEN_FILE=./data/seen.json
DATA_FILE=./data/countries.json

function reset() {
    echo "[]" > $SEEN_FILE
}

score=0
reset

if [ ! -f $DATA_FILE ]; then
    curl -o $DATA_FILE "https://raw.githubusercontent.com/mledoze/countries/refs/heads/master/countries.json"
fi

all_regions=`jq -r '.[].region' $DATA_FILE | sort | uniq`

if [ -n "$1" ]; then
    region=$1
else
    region=`echo -e "$all_regions" | gum filter --header="Choose a region:"`
fi

if [ -z "$region" ]; then
    exit 1
fi

function print_sep() {
    echo -e "${GRAY}******************${RESET}"
}

print_sep
echo "Region: $region"

if [ -n "$2" ]; then
    difficulty=$2
else
    difficulty=`echo -e "Easy\nMedium\nHard" | gum filter --header="Choose a difficulty:"`
fi

if [ -z "$difficulty" ]; then
    exit 1
fi

case $difficulty in
    "Easy")     echo -e "Difficulty: ${BLUE}Easy${RESET}" ;;
    "Medium")   echo -e "Difficulty: ${YELLOW}Medium${RESET}" ;;
    "Hard")     echo -e "Difficulty: ${RED}Hard${RESET}" ;;
esac

print_sep

while true
do
    ./mg-country-from-capital.sh $region $difficulty
    case $? in
        0) ((score++)) ;;
        1) break ;;
        2) 
            echo -e "❌ ${GRAY}${ITALIC}User abort${RESET}"
            break ;;
        3) 
            ((score++))
            echo "🎉 You guessed them all!"
            break ;;
        *) 
            echo "Unknown case: $?"
            exit 1
            ;;
    esac
done

print_sep
echo -e "${BLUE}Score: $score${RESET}"
print_sep

reset
