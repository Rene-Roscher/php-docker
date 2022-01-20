FROM php:8.0.3-fpm-alpine

WORKDIR /var/www

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

RUN mv /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini

RUN pecl install redis && docker-php-ext-enable redis


RUN install-php-extensions \
    bcmath \
    exif \
    gd \
    gmp \
    opcache \
    pdo_mysql \
    zip \
    && rm /usr/local/bin/install-php-extensions

RUN apk add nginx git

RUN { crontab -l; echo "* * * * * php /var/www/artisan schedule:run >/dev/null 2>&1"; } | crontab -

COPY ./entrypoint.sh /usr/local/bin/php-entrypoint
RUN chmod +x /usr/local/bin/php-entrypoint
COPY ./web/www.conf /usr/local/etc/php-fpm.d/www.conf

EXPOSE 80

ADD web/nginx.conf /etc/nginx/nginx.conf
COPY web/sites/* /etc/nginx/conf.d/

COPY ./web/php.ini /usr/local/etc/php/php.ini

RUN apk add --update supervisor && rm  -rf /tmp/* /var/cache/apk/*

RUN apk add certbot certbot-nginx


ENTRYPOINT ["php-entrypoint"]
CMD ["php-fpm", "-R"]
