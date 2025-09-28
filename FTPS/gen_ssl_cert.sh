#!/usr/bin/env bash

if [ ! -d ssl ]; then
    mkdir ssl
fi

cd ssl

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout pure-ftpd.key \
  -out pure-ftpd.crt 

cat pure-ftpd.crt pure-ftpd.key > pure-ftpd.pem

chmod 777 pure-ftpd.pem