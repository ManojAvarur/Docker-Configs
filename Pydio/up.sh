export CWD=$(realpath "$(dirname "$0")")/Configs
export MYSQL_ROOT_PASSWORD=P@ssw0rd
export MYSQL_DATABASE=cells
export MYSQL_USER=pydio 
export MYSQL_PASSWORD=P@ssw0rd

echo "\nStarting Docker...\n";

docker-compose up --build -d

unset CWD
unset MYSQL_ROOT_PASSWORD
unset MYSQL_DATABASE
unset MYSQL_USER
unset MYSQL_PASSWORD