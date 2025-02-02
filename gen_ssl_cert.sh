mkdir ssl

cd ssl

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout pure-ftpd.pem -out pure-ftpd.pem

chmod 600 pure-ftpd.pem
