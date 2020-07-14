#!/usr/bin/env bash

function _info() {
    echo -e "\e[96m[INFO]: $@\e[0m"
}
function _err() {
    echo -e "\e[91m[ERR]: $@\e[0m" 1>&2
}

_EXITING=0
function _wait() {
    wait $!
    local EXIT_CODE=$?
    [ "$_EXITING" == 1 ] && exit
    echo $EXIT_CODE
}
function _waitAll() {
    for job in $(jobs -p); do
        _info "Waitting $job..."
        wait $job
        _info "Job done: $job"
    done
}

function _sigint() {
    _EXITING=1
}

function _exit() {
    _info "Exiting..."

    _info "Asking Apache to gracefully stop..."
    apachectl -k graceful-stop

    _EXITING=1

    for job in $(jobs -p); do
        echo "   Sending SIGTERM to job $job..."
        kill -SIGTERM $job 2>/dev/null
    done
}

trap _sigint SIGINT SIGTERM SIGQUIT
trap _exit EXIT

if [[ ! -d "/var/www/html/vendor" && -d "/tmp/vendor" ]]; then
    mv "/tmp/vendor" "/var/www/html/vendor"
fi
if [ ! -f "/var/www/html/composer.phar" ]; then
    mv "/tmp/composer.phar" "/var/www/html/composer.phar"
fi

if [ "$YW_DEVELOPMENT" == 1 ]; then
    cd "/var/www/html"
    php composer.phar install --no-progress --optimize-autoloader
    YW_XDEBUG_CONFIG_VALUE="\"idekey=PHPSTORM remote_host=$(route | awk '/default/ { print $2 }') profiler_enable=1 remote_enable=1\""
    export XDEBUG_CONFIG=$YW_XDEBUG_CONFIG_VALUE
    printf "\nexport XDEBUG_CONFIG=$YW_XDEBUG_CONFIG_VALUE\n" >> /root/.bashrc
fi

if [[ ! "$YW_SKIP_PIMCORE_INSTALL" || "$YW_SKIP_PIMCORE_INSTALL" == 0 ]]; then
    YW_MYSQL_HOST=$PIMCORE_INSTALL_MYSQL_HOST_SOCKET
    YW_DB_NAME=$PIMCORE_INSTALL_MYSQL_DATABASE
    YW_DB_USERNAME=$PIMCORE_INSTALL_MYSQL_USERNAME
    YW_DB_PASSWORD=$PIMCORE_INSTALL_MYSQL_PASSWORD

    XDEBUG_CONFIG="remote_enable=0" /var/www/html/docker/create-db-if-not-exists.sh -h "$PIMCORE_INSTALL_MYSQL_HOST_SOCKET" -d "$PIMCORE_INSTALL_MYSQL_DATABASE" -u "$PIMCORE_INSTALL_MYSQL_USERNAME" -p "$PIMCORE_INSTALL_MYSQL_PASSWORD"
fi

_info "Executing migrations"
XDEBUG_CONFIG="remote_enable=0" /var/www/html/bin/console pimcore:migrations:migrate --set carpetright --no-interaction

/var/www/html/docker/fix-filesystem-permissions.sh > /dev/null

# first arg is not `-f` or `--some-option`
if [ "${1#-}" == "$1" ]; then
    exec "$@"
else
    docker-php-entrypoint "$@" &
    _waitAll
fi
