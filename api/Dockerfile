# 
ARG PHP_VERSION=8.1.8-alpine

##
## "php" stage
##
FROM php:${PHP_VERSION} as php_stage

# persistent / runtime deps
RUN apk add --no-cache \
    acl \
    fcgi \
    file \
    gettext \
    git \
    gnu-libiconv \
    ;

# install gnu-libiconv and set LD_PRELOAD env to make iconv work fully on Alpine image.
# see https://github.com/docker-library/php/issues/240#issuecomment-763112749
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so

# install des dependences de l'application symfony 'api'
RUN set -eux; \
    apk add --no-cache --virtual .build-deps \
    $PHPIZE_DEPS \
    icu-dev \
    libzip-dev \
    zlib-dev \
    rabbitmq-c-dev \
    ;

# configuration et installation des modules PHP
RUN docker-php-ext-configure zip;
RUN docker-php-ext-install -j$(nproc) \
    intl \
    zip \
    ;

# install via PECL (quoi ?? prrrt)
RUN pecl install \
    amqp \
    apcu-${APCU_VERSION} \
    ;

RUN pecl clear-cache;

# activation des dépendances php
RUN docker-php-ext-enable \
    amqp \
    apcu \
    opcache \
    ; 

# liste les dépendances
RUN runDeps="$( \
    scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
    | tr ',' '\n' \
    | sort -u \
    | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )";

# utilise la liste pour ??
RUN apk add --no-cache --virtual .api-phpexts-rundeps $runDeps;
RUN apk del .build-deps

# copy la bonne version du php.ini
RUN ln -s $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini
COPY docker/php/conf.d/api.prod.ini $PHP_INI_DIR/conf.d/api.ini

# ca modifie la conf de php-fpm, mais ca a toujours du sens si l'image n'est pas fpm ?
COPY docker/php/php-fpm.d/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.conf

VOLUME /var/run/php


# Installation de composer
RUN curl -sS https://getcomposer.org/installer | php -- \
    &&  mv composer.phar /usr/local/bin/composer

# Installation de la commande Symfony
RUN curl -sS https://get.symfony.com/cli/installer | bash \
    &&  mv /root/.symfony/bin/symfony /usr/local/bin

# https://getcomposer.org/doc/03-cli.md#composer-allow-superuser
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV PATH="${PATH}:/root/.composer/vendor/bin"

# install yarn
RUN npm install --global yarn

WORKDIR /srv/api




##
## "api" stage
##
FROM php_stage as api_stage

# build for production
ARG APP_ENV=prod
ARG SYMFONY_PHPUNIT_VERSION=9

# installation des dependances symfony
# prevent the reinstallation of vendors at every changes in the source code
COPY composer.json composer.lock symfony.lock ./
RUN set -eux;
RUN composer install --prefer-dist --no-dev --no-scripts --no-progress;
RUN composer clear-cache


# copy uniquement ce dont l'application à besoin
# COPY .env ./
# COPY bin bin/
# COPY config config/
# COPY migrations migrations/
# COPY public public/
# COPY src src/
# COPY templates templates/


# creer les répertoire de caches, dump je ne sais quoi, lance le script post-install et rend la console symfony executabe
RUN set -eux; \
    mkdir -p var/cache var/log; \
    composer dump-autoload --classmap-authoritative --no-dev; \
    composer dump-env prod; \
    composer run-script --no-dev post-install-cmd; \
    chmod +x bin/console; sync

VOLUME /srv/api/var

# healthcheck ??, on verra apres ce que c'est
# COPY ../_config/php/docker-healthcheck.sh /usr/local/bin/docker-healthcheck
# RUN chmod +x /usr/local/bin/docker-healthcheck
# HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD ["docker-healthcheck"]


# copy le script entrypoint et le rend executable
COPY ../_config/php/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

# pass la variable SYMFONY_PHPUNIT_VERSION a l'env du container
ENV SYMFONY_PHPUNIT_VERSION $SYMFONY_PHPUNIT_VERSION

ENTRYPOINT ["docker-entrypoint"]
# CMD ["php-fpm"]
