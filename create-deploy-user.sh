#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Instance name required"
else
  ansible-playbook -i ./instances/$1/hosts --extra-vars="instance_base_dir=../instances/$1"  ./ansible/create-deploy-user.yml
fi
