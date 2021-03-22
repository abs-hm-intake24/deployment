#!/bin/bash

## Declare an array variable of ports
declare -a ports=(9001 6400 8081 8082 8002 8003 6401 6403 5432)

## Now loop through the above array
for port in "${ports[@]}"
do 
   ## Try and add the ports
   sudo semanage port -a -t http_port_t -p tcp $port
   if [ $? -eq 1 ]; then
    ## If the ports are already defined then modify them
    sudo semanage port -m -t http_port_t -p tcp $port
   fi
done

sudo setsebool -P nis_enabled 1
