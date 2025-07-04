#!/bin/bash

if [ ! -d "./ssl" ]; then
    mkdir ssl
    bash ./gen_ssl_cert.bash
else
    if [ -f "./ssl/pure-ftpd.pem" ]; then
        creation_date=$(stat --format=%W "./ssl/pure-ftpd.pem")
        current_date=$(date +%s)
        difference=$((current_date - creation_date))
        one_month_in_seconds=$((30 * 24 * 60 * 60))

        if [ "$difference" -gt "$one_month_in_seconds" ]; then
            bash ./gen_ssl_cert.bash
        fi
    fi
fi

echo -e "\nStarting up FTP server...\n";

docker compose -f docker-compose-ftpd.yaml up --build

echo -e "\n ----- FTPS Server Started -----\n"