# taken from https://frankenphp.dev/docs/docker/
FROM dunglas/frankenphp

LABEL maintainer="Rainer Burgstaller"

ARG USER=www-data
ARG WWWGROUP=www-data

WORKDIR /app

ENV DEBIAN_FRONTEND noninteractive
ENV TZ=UTC

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

#
RUN apt-get update && apt-get install -y \
      gnupg git libnss3-tools \
      vim  # for testing for now



RUN install-php-extensions gd pdo_mysql zip intl

ENV NODE_VERSION 20.11.1

RUN mkdir /usr/local/nvm
ENV NVM_DIR /usr/local/nvm

RUN curl https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

RUN apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH


# ensure that php is in the path that the artisan commands expect it to be
RUN ln -s /usr/local/bin/php /usr/bin/php

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN mkdir /.composer && \
    chmod -R ugo+rw /.composer && \
    chown -R "$USER" /.composer

RUN chown -R "$USER":${WWWGROUP} /data/caddy && \
    chown -R "$USER":${WWWGROUP} /config/caddy && \
    mkdir -p /var/www/.npm && chown -R $USER:$WWWGROUP /var/www/.npm && \
    chown -R $USER:$WWWGROUP /app


# Switch to use a non-root user from here on
USER ${USER}


# Add application
WORKDIR /app

COPY --chown=$USER:$WWWGROUP . /app

RUN mkdir -p /app/storage/logs && \
    npm install && \
    npm run build

RUN composer install --no-interaction --no-dev --prefer-dist --optimize-autoloader
