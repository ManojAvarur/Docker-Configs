
# FTPS Docker Config

This repository provides the complete details of starting and running a FTPS server from docker

## Prerequisites
- Make sure [Docker](https://www.docker.com/) and [Docker Compose](https://docs.docker.com/compose/) is installed in your PC
    
- Clone the repository
   
- CD into the cloned repository

## Now Execute Following Commands
```bash
sudo chmod +x ./up.bash
```
```bash
./up.bash
```

## How to change the default configuration?
- The ports defined in the [Docker Compose](docker-compose-ftpd.yaml) file map to the default FTP port (21) and a range of ports from 30000 to 30100. You can adjust these ports as needed.
```yaml
ports:
- "21:21"
- "30000-30100:30000-30100"
```
- Rename the .env.sample to .env file
```bash
cp .env.sample .env
```
- Update .env values as needed 
```env
USER_NAME=USERNAME
USER_PASS=PASSWORD

COUNTRY=US
STATE=Arizona
CITY=TEMPE
ORG=Company
ORG_UNIT_NAME=IT
CMN_NAME=example.com
EMAIL=sample@example.com
```
