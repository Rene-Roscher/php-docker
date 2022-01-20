#!/bin/sh
set -e

if [ "${1#-}" != "$1" ]; then
  set -- php-fpm "$@"
fi

if [ "$1" = 'php-fpm' ] || [ "$1" = 'php' ]; then

  # Cache everything
  php artisan optimize
  php artisan config:cache

fi

exec "$@" &
exec nginx
exec crond
