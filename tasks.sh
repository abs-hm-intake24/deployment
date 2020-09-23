#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Instance name required"
else
  ansible-playbook -i ./instances/$1/hosts -e @./instances/$1/tasks/app.json --extra-vars="intake24_instance_name=$1" ansible/tasks.yml
fi
