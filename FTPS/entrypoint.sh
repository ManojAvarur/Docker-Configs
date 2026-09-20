#!/bin/bash
set -e

mkdir -p /etc/vsftpd/ssl

openssl req -x509 -nodes -days 1 -newkey rsa:2048 \
    -keyout /etc/vsftpd/ssl/vsftpd.pem \
    -out /etc/vsftpd/ssl/vsftpd.pem \
    -subj "/CN=ftps"

if ! id "${FTP_USER}" >/dev/null 2>&1; then
    useradd -d /ftp "${FTP_USER}"
fi
echo "${FTP_USER}:${FTP_PASS}" | chpasswd
echo "${FTP_USER}" > /etc/vsftpd.userlist

mkdir -p /ftp
chown "${FTP_USER}:${FTP_USER}" /ftp

touch /var/log/vsftpd.log
/usr/sbin/vsftpd /etc/vsftpd.conf &
exec tail -F /var/log/vsftpd.log
