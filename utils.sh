#!/usr/bin/env bash

SEEN_FILE='data/seen.json'
DATA_FILE='data/countries.json'

#######################################
# Reads the full list of countries from the data file
# Globals:
#   DATA_FILE - The path of the JSON file with the full list of countries
# Arguments:
#   $1 - Region filter to apply (optional)
#   $2 - Independency filter to apply (optional)
# Outputs:
#   Prints the list of countries
# Returns:
#   0 if successful, non-zero on error
#######################################
function get_countries() {
    local region=$1
    local independent=$2
    
    local countries
    countries=$(jq -c '.' $DATA_FILE)
    if [ -n "$region" ]; then
        countries=$(echo "$countries" \
            | jq -c --arg region "$region" '[.[] | select(.region == $region)]')
    fi

    if [ -n "$independent" ]; then
        countries=$(echo "$countries" \
            | jq -c --argjson indep "$independent" '[.[] | select(.independent == $indep)]')
    fi

    echo "$countries"
}

#######################################
# Gets the entire list of regions (or subregions)
# Globals:
#   DATA_FILE - The path of the JSON file with the full list of countries
# Arguments:
#   $1 - Bool to get subregions instead (optional)
# Outputs:
#   Prints the list of regions
# Returns:
#   0 if successful, non-zero on error
#######################################
function get_regions() {
    local subregions=$1 

    if [ "$subregions" = "true" ]; then
        jq -c -r '.[].subregion' $DATA_FILE | sort | uniq
    else
        jq -c -r '.[].region' $DATA_FILE | sort | uniq
    fi
}

function get_seen_country_names() {
    jq -c '.' $SEEN_FILE
}

#######################################
# Filters the given list of countries to only retain the ones
# not in the given blacklist
# Arguments:
#   $1 - List of countries
#   $2 - List of blacklisted country names
# Outputs:
#   Prints the list of countries without those that are blacklisted
# Returns:
#   0 if successful, non-zero on error
#######################################
function filter_countries() {
    local countries=$1
    local blacklist=$2

    local filtered
    filtered=$(echo "$countries" \
        | jq -c --argjson blacklist "$blacklist" \
        'map(select(.name.common as $name | ($blacklist | index($name) | not)))')

    echo "$filtered"
}

function get_rand_entry() {
    local countries=$1
    echo "$countries" | jq -c --argjson r $RANDOM '.[$r % length]'
}
