#!/usr/bin/env bash

BASE_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

function _info() {
    echo -e "\e[96m[INFO]: $@\e[0m"
}
function _err() {
    echo -e "\e[91m[ERR]: $@\e[0m" 1>&2
}

function printHelp()
{
    me=`basename "$0"`
    printf "\n"
    echo "Usage: $me -h mysql-host -d database-name -u mysql-root-user-nane -p mysql-root-user-password"
    echo
    echo "This script will wait until the MySQL is online and, after that, it will check if create the database if it "
    echo "does not exists yet."
    echo
    echo "Options"
    echo " -h, --host           MySQL host to connect."
    echo " -d, --database       Name of the database that will be create if it does not exists yet."
    echo " -u, --username       MySQL root user name."
    echo " -p, --password       Mysql root user password."
    echo " --help               Print this help."
    printf "\n"
}

YW_MYSQL_HOST=
YW_DB_NAME=
YW_DB_USERNAME=
YW_DB_PASSWORD=

while test $# -gt 0; do
    case "$1" in
        --help)
            printHelp
            exit 0
            ;;
        -h|--host)
            shift
            YW_MYSQL_HOST=$1
            ;;
        -d|--database)
            shift
            YW_DB_NAME=$1
            ;;
        -u|--username)
            shift
            YW_DB_USERNAME=$1
            ;;
        -p|--password)
            shift
            YW_DB_PASSWORD=$1
            ;;
        *)
            printf "Unknown parameter \"$1\"\n"
            printHelp
            exit 10
            ;;
    esac
    shift
done

if [ "$YW_MYSQL_HOST" == "" ]; then
    echo "Parameter '--host' is required."
    printHelp
    exit 20
elif [ "$YW_DB_NAME" == "" ]; then
    echo "Parameter '--database' is required."
    printHelp
    exit 21
elif [ "$YW_DB_USERNAME" == "" ]; then
    echo "Parameter '--username' is required."
    printHelp
    exit 22
elif [ "$YW_DB_PASSWORD" == "" ]; then
    echo "Parameter '--password' is required."
    printHelp
    exit 23
fi

_info Database Paramenters:
_info "    Host........: $YW_MYSQL_HOST"
_info "    Database....: $YW_DB_NAME"
_info "    User........: $YW_DB_USERNAME"
_info "    Use password: Yes"

YW_PHP_PDO_CONNECT="\$pdo = new PDO('mysql:host=$YW_MYSQL_HOST', '$YW_DB_USERNAME', '$YW_DB_PASSWORD', [PDO::ATTR_TIMEOUT => 5, PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);"

while ! php -r "$YW_PHP_PDO_CONNECT" &> /dev/null; do
    _info Waitting MySQL server...
    [ "$_EXITING" == 1 ] && exit
    sleep 2
done
_info MySQL server is online!

YW_SELECT_DATABASE="
    $YW_PHP_PDO_CONNECT
    echo \$pdo->query('SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = \"$YW_DB_NAME\"')->fetchColumn(0);"
YW_DOES_DATABASE_EXISTS=0
YW_SELECT_DATABASE_OUTPUT=$(php -r "$YW_SELECT_DATABASE")
if [[ $? -eq 0 && "$YW_SELECT_DATABASE_OUTPUT" != "" ]]; then
    YW_DOES_DATABASE_EXISTS=1
fi

if [ $YW_DOES_DATABASE_EXISTS -eq 1 ]; then
    _info "Database '$YW_DB_NAME' already exists."
else
    _info "Database '$YW_DB_NAME' does not exists yet. Trying to create it."

    YW_PHP_CREATE_DB_IF_NOT_EXISTS="
        $YW_PHP_PDO_CONNECT
        \$pdo->exec('CREATE DATABASE IF NOT EXISTS \`$YW_DB_NAME\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci');"

    YW_PHP_CREATE_DB_OUTPUT=$(php -r "$YW_PHP_CREATE_DB_IF_NOT_EXISTS")
    if [ $? -gt 0 ]; then
        YW_ERROR_MSG="Failed to create database! We got an error while executing the following PHP code:"
        _err "$YW_ERROR_MSG${YW_PHP_CREATE_DB_IF_NOT_EXISTS/$YW_DB_PASSWORD\');/***\');}$YW_PHP_CREATE_DB_OUTPUT"
        exit 30
    fi

    _info "Database '$YW_DB_NAME' created."
fi

YW_SELECT_TABLES="
    $YW_PHP_PDO_CONNECT
    echo count(\$pdo->query('SHOW TABLES FROM \`$YW_DB_NAME\`')->fetchAll());"
YW_SELECT_TABLES_OUTPUT=$(php -r "$YW_SELECT_TABLES")
if [[ $? -eq 0 && "$YW_SELECT_TABLES_OUTPUT" -eq 0 ]]; then
    _info "Database exists, but it is empty. Calling Pimcore install script."
    $BASE_DIR/../vendor/bin/pimcore-install \
        --no-interaction \
        --ignore-existing-config \
        --mysql-host-socket="$YW_MYSQL_HOST" \
        --mysql-database="$YW_DB_NAME" \
        --mysql-username="$YW_DB_USERNAME" \
        --mysql-password="$YW_DB_PASSWORD" \
        --admin-username="admin" \
        --admin-password="admin"
else
    _info "Database exists and has '$YW_SELECT_TABLES_OUTPUT' tables."
fi
