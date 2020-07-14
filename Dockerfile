FROM php:7.4.1-apache-buster AS base

ENV PIMCORE_INSTALL_ADMIN_USERNAME=admin \
    PIMCORE_INSTALL_ADMIN_PASSWORD=admin \
    PIMCORE_INSTALL_MYSQL_USERNAME=root \
    PIMCORE_INSTALL_MYSQL_PASSWORD=root \
    PIMCORE_INSTALL_MYSQL_DATABASE=yw_pimcore_skeleton \
    PIMCORE_INSTALL_MYSQL_HOST_SOCKET="MySQL host name. Ex: 10.0.0.2"

ARG YW_TEMPORARY_PACKAGES_TO_INSTALL=unzip
ARG YW_APACHE_CONF_FILE_NAME=apache.conf
ARG YW_PAGESPEED_DEB_FILENAME=mod-pagespeed-beta_current_amd64.deb
ARG YW_PAGESPEED_URL=https://dl-ssl.google.com/dl/linux/direct/$YW_PAGESPEED_DEB_FILENAME
ARG YW_PAGESPEED_DEB_LOCAL_PATH=/tmp/$YW_PAGESPEED_DEB_FILENAME

WORKDIR "/var/www/html"

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        zlib1g-dev libpng-dev libzip-dev libicu-dev $YW_TEMPORARY_PACKAGES_TO_INSTALL && \
    docker-php-ext-install -j$(nproc) opcache gd exif zip intl mysqli pdo_mysql && \
    rm -rfv "/var/www/html/*" && \
    curl -sS -o "/var/www/html/composer.phar" https://getcomposer.org/download/1.9.2/composer.phar && \
    curl -sS -o "$YW_PAGESPEED_DEB_LOCAL_PATH" "$YW_PAGESPEED_URL" && \
    dpkg -i "$YW_PAGESPEED_DEB_LOCAL_PATH" && \
    apt-get -f install && \
    a2enmod rewrite negotiation headers deflate setenvif filter expires pagespeed && \
    a2dissite 000-default

# The `composer install` command always take a long time to finish because every time we change something on the source
# code, Docker losts the Composer cache, thus the `composer install` needs to download and install all the packages
# again. To avoid this behavior we split the `composer install` in two steps:
#   1. Run `composer install` before copying the project source code.
#   1. Copy the project source code and then run `composer install` again.
# This allows us to use the Docker Cache in our favor, making this Dockerfile builds faster.
# The technique works has follows:
#   - First we copy the old version of composer.json and composer.lock (we do not copy anything else).
#   - Run `composer install`.
#   - Docker caches the result of its command.
#   - Copy all the others files from the project.
#   - Docker lost the cache, since we copied new and updated files
#   - Run `composer install` again to install. I will install only the packages that weren't installed on the first
#     step (if there are any). Besides, the full "Composer Cache" will be there if necessary.
COPY docker/composer.for-cache-purpose.json "/var/www/html/composer.json"
COPY docker/composer.for-cache-purpose.lock "/var/www/html/composer.lock"

# Unfortunately, we can't install the dependencies with `--no-dev` because Pimcore needs all the "dev" dependencies to
# work, even in production :(
RUN php composer.phar install --no-progress --no-autoloader --no-scripts

COPY composer.* "/var/www/html/"
COPY ./app "/var/www/html/app/"
COPY ./bin "/var/www/html/bin/"
COPY "./docker/$YW_APACHE_CONF_FILE_NAME" "/var/www/html/docker/"
COPY ./docker/php.ini $PHP_INI_DIR/conf.d/

RUN mkdir -p "/var/www/html/var/logs" && \
    chmod -R 777 "/var/www/html/var/logs" && \
    php composer.phar install --no-progress --optimize-autoloader && \
    mv "/var/www/html/vendor" "/tmp/vendor" && \
    mv "/var/www/html/composer.phar" "/tmp/composer.phar" && \
    DEBIAN_FRONTEND=noninteractive apt-get purge $YW_TEMPORARY_PACKAGES_TO_INSTALL -y && \
    DEBIAN_FRONTEND=noninteractive apt-get autoremove -y && \
    DEBIAN_FRONTEND=noninteractive apt-get autoclean -y && \
    DEBIAN_FRONTEND=noninteractive apt-get clean -y && \
    mv "/var/www/html/docker/$YW_APACHE_CONF_FILE_NAME" "$APACHE_CONFDIR/sites-available" && \
    a2ensite $YW_APACHE_CONF_FILE_NAME

ENTRYPOINT ["yw-entrypoint.sh"]

CMD ["apache2-foreground"]


FROM base AS production

COPY ./  "/var/www/html/"
COPY ./docker/yw-entrypoint.sh /usr/local/bin/yw-entrypoint.sh


FROM base AS development

ENV YW_SKIP_PIMCORE_INSTALL=0
ENV YW_DEVELOPMENT=1
ENV YW_PHPSTORM_SERVER_NAME="DockerContainer"
ENV PHP_IDE_CONFIG="serverName=$YW_PHPSTORM_SERVER_NAME"

RUN pecl install xdebug-2.9.1 && \
    docker-php-ext-enable xdebug && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y net-tools nano

COPY ./docker/yw-entrypoint.sh /usr/local/bin/yw-entrypoint.sh
