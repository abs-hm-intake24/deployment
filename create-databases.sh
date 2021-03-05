#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Instance name required"
else
  ansible-playbook -vvv -i ./instances/$1/hosts -e @./instances/$1/database/postgres-configuration.yml --extra-vars="intake24_instance_name=$1" ansible/create-databases.yml
fi

