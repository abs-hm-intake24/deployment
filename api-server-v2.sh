#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Instance name required"
else
  ansible-playbook -i ./instances/$1/hosts -e @./instances/$1/api-server-v2/config.json --extra-vars="intake24_instance_name=$1" ansible/api-server-v2.yml
fi
