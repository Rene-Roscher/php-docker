#!/bin/sh
set -e

if [ "${1#-}" != "$1" ]; then
  set -- php-fpm "$@"
fi

if [ "$1" = 'php-fpm' ] || [ "$1" = 'php' ]; then

  # Cache everything
  php artisan optimize
  php artisan config:cache
  php artisan route:cache
  php artisan view:cache
  php artisan event:cache
#  php artisan ziggy:generate

  chmod -R gu+w storage/ && chmod -R guo+w storage/ && chmod -R gu+w bootstrap/cache/ && chmod -R guo+w bootstrap/cache/

fi

exec "$@" &
exec nginx
exec crond
