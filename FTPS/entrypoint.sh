#!/bin/bash
set -e

mkdir -p /etc/vsftpd/ssl

openssl req -x509 -nodes -days 1 -newkey rsa:2048 \
    -keyout /etc/vsftpd/ssl/vsftpd.pem \
    -out /etc/vsftpd/ssl/vsftpd.pem \
    -subj "/CN=ftps"

PUID="${PUID:-1000}"
PGID="${PGID:-1000}"

# Make sure PGID belongs to a group named $FTP_USER, even if the base image
# already ships a group with that GID (e.g. Ubuntu 24.04's default "ubuntu" group).
existing_group="$(getent group "${PGID}" | cut -d: -f1 || true)"
if [ -z "${existing_group}" ]; then
    groupadd -g "${PGID}" "${FTP_USER}"
elif [ "${existing_group}" != "${FTP_USER}" ]; then
    groupmod -n "${FTP_USER}" "${existing_group}"
fi

# Make sure PUID belongs to a user named $FTP_USER, even if the base image
# already ships a user with that UID (e.g. Ubuntu 24.04's default "ubuntu" user).
existing_user="$(getent passwd "${PUID}" | cut -d: -f1 || true)"
if [ -z "${existing_user}" ]; then
    useradd -d /ftp -u "${PUID}" -g "${PGID}" "${FTP_USER}"
elif [ "${existing_user}" != "${FTP_USER}" ]; then
    usermod -l "${FTP_USER}" -d /ftp -g "${PGID}" "${existing_user}"
else
    usermod -d /ftp -g "${PGID}" "${FTP_USER}"
fi

echo "${FTP_USER}:${FTP_PASS}" | chpasswd
echo "${FTP_USER}" > /etc/vsftpd.userlist

mkdir -p /ftp
chown -R "${FTP_USER}:${PGID}" /ftp
chmod -R 775 /ftp

touch /var/log/vsftpd.log
/usr/sbin/vsftpd /etc/vsftpd.conf &
exec tail -F /var/log/vsftpd.log
