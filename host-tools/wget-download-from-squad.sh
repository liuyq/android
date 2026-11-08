#!/bin/bash -ex

url="${1}"
squad_token=""
#curl -fsSL --retry 20 --header "Authorization: token ${squad_token}"
wget -c --header "Authorization: token ${squad_token}" "${url}"
