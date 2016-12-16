FROM alpine:3.3

ENV HUMHUB_VERSION=v1.1.2

RUN apk add --no-cache \
    php \
    php-fpm \
    php-curl \
    php-pdo_mysql \
    php-zip \
    php-exif \
    php-intl \
    imagemagick \
    php-ldap \
    php-apcu \
    php-memcache \
    php-gd \
    php-cli \
    php-openssl \
    php-phar \
    php-json \
    php-ctype \
    php-iconv \
    supervisor \
    nginx \
    git wget unzip \
    sqlite \
    && rm -rf /var/cache/apk/*


RUN php -r "readfile('https://getcomposer.org/installer');" > composer-setup.php && \
    php -r "if (hash('SHA384', file_get_contents('composer-setup.php')) === 'aa96f26c2b67226a324c27919f1eb05f21c248b987e6195cad9690d5c1ff713d53020a02ac8c217dbf90a7eacc9d141d') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    php -r "unlink('composer-setup.php');"


RUN mkdir /app && \
    cd /app && \
    git clone https://github.com/humhub/humhub.git humhub && \
    cd humhub && \
    git checkout $HUMHUB_VERSION

WORKDIR /app/humhub

COPY config.json /root/.composer/config.json
COPY auth.json /root/.composer/auth.json

RUN composer global require "fxp/composer-asset-plugin:~1.1.0" && \
    composer update --no-dev

RUN chmod +x protected/yii && \
    chmod +x protected/yii.bat && \
    chown -R nginx:nginx /app/humhub && \
	chown -R nginx:nginx /var/lib/nginx/ && \
	touch /var/run/supervisor.sock && \
	chmod 777 /var/run/supervisor.sock

COPY pool.conf /etc/php-fpm.d/pool.conf
COPY nginx.conf /etc/nginx/nginx.conf
copy supervisord.conf /etc/supervisord.conf

VOLUME /app/humhub/uploads
VOLUME /app/humhub/assets
VOLUME /app/humhub/protected/runtime
VOLUME /app/humhub/protected/config
VOLUME /app/humhub/protected/modules

EXPOSE 80

CMD supervisord
