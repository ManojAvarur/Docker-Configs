FROM ubuntu:24.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends vsftpd openssl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/vsftpd/empty

COPY vsftpd.conf /etc/vsftpd.conf

COPY entrypoint.sh /entrypoint.sh

RUN sed -i 's/\r$//'  /etc/vsftpd.conf /entrypoint.sh

RUN chmod +x /entrypoint.sh

# exposes 21 30000-30100

ENTRYPOINT [ "/entrypoint.sh" ]
