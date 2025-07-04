#!/bin/bash

if [ ! -d "./ssl" ]; then
  rm -f ./ssl/*
fi

cd ssl

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -subj "/C=${COUNTRY}/ST=${STATE}/L=${CITY}/O=${ORG}/OU=${ORG_UNIT_NAME}/CN=${CMN_NAME}/emailAddress=${EMAIL}" \
    -keyout pure-ftpd.pem -out pure-ftpd.pem

chmod 600 pure-ftpd.pem
