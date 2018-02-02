#!/bin/bash

if [ -z $1 ]; then
  echo 'Usage: upload.sh <package.zip>'
  exit 1
fi

if [ -z "$FLIGHT_SSO_TOKEN" ]; then
  echo 'FLIGHT_SSO_TOKEN required but not set'
  exit 2
fi

curl --silent --show-error --fail \
	-H "Authorization: Bearer $FLIGHT_SSO_TOKEN" \
       	-F package=@"$1" \
        https://forge-api.alces-flight.com/v1/upload

if [ $? -eq 0 ]; then
  echo 'OK'
fi
