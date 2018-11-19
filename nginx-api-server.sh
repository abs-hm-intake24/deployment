#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Instance name required"
else
  ansible-playbook -i ./instances/$1/hosts -e @./instances/$1/api-server/nginx-site.json ansible/nginx-site-api-server.yml
fi
