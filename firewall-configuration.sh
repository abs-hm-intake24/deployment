#!/bin/bash

## Declare the array
declare -a public_ports=(8081 8082 9001)

distribution=`sudo lsb_release -a | grep "Distribution ID"`

if [[ $distribution == "Ubuntu" ]]; then
for port in "${public_ports[@]}"
do
 sudo ufw allow from any to any port $port proto tcp
done

## If distribution is not Ubuntu
else
## Loop through the above array and set firewall
for port in "${public_ports[@]}"
do
  ## Try and add the ports to the firewall
 sudo firewall-cmd --zone=public --add-port="$port"/tcp --permanent
done

## Reload the firewall
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
fi

