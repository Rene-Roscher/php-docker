# Pinned to the PHP patch release on a supported Alpine. The old php:8.2-fpm-alpine3.16 tag
# stopped receiving updates with Alpine 3.16, which froze every image built from it at an early
# 8.2.x. PHP2Shell (CVE-2026-109618 / CVE-2026-109619) is fixed in 8.2.35. The official
# php:8.2.35-fpm-alpine3.23 was not pullable yet, so this is the same image built from the
# docker-library sources in this repo (branch php-8.2-fpm-alpine3.23). Go back to the official
# tag once it is available.
FROM ghcr.io/rene-roscher/php-docker:php-8.2-fpm-alpine3.23@sha256:186fddb24b16745343d41080d7aa90ff8436c8b66d8054b15c4938940af681bc

WORKDIR /var/www

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

RUN mv /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini

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

ENTRYPOINT ["php-entrypoint"]
CMD ["php-fpm", "-R"]
