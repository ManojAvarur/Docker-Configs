
# FTPS Docker Config

This repository provides the complete details of starting and running a FTPS server from docker

## Prerequisites
- Make sure [Docker](https://www.docker.com/) and [Docker Compose](https://docs.docker.com/compose/) is installed in your PC
    
- Clone the repository
   
- CD into the cloned repository

## Now Execute Following Commands
```bash
sudo chmod +x ./gen_ssl_cert.sh
```
```bash
./gen_ssl_cert.sh
```
```bash
docker-compose -f docker-compose-ftpd.yaml up -d --build
```

## How to change the default configuration?
- The ports defined in the [Docker Compose](docker-compose-ftpd.yaml) file map to the default FTP port (21) and a range of ports from 30000 to 30009. You can adjust these ports as needed, but please ensure that only the values before the colon are modified, not the values after it.
```yaml
ports:
- "21:21"
- "30000-30009:30000-30009"
```
- Update **username** and **password** as needed
```yaml
environment:
  - FTP_USER_NAME=username
  - FTP_USER_PASS=password
```
