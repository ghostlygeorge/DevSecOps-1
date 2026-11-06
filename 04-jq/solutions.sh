#!/usr/bin/env bash
cd "$(dirname "$0")"
run() { echo; echo "\$ jq '$1' learnjq.json"; jq "$1" learnjq.json; }
run '.[] | .details'
run '.[] | {name: .details.name, url:.details.url}'
run '.[1] | {name: .details.name, url: .details.url}'
run '[.[] | {name: .details.name, url: .details.url}]'
run '.[] | {name: .details.name, url: .details.url, services: .services[]}'
run '.[] | {name: .details.name, url: .details.url, services: [.services[]]}'
run '.[] | {name: .details.name, servicecount: (.services | length)}'
run '.[] | select(.details.name=="AWS")'
echo; echo "### Challenge answers"
run '.[] | select(.services[].type=="CI-CD") | .details.name'
run '.[].services[] | select(.type=="CI-CD")'
run '.[].services[] | select(.type=="CI-CD") | .name'
run '.[] | select(any(.services[]; .type=="CI-CD")) | .details.name'
