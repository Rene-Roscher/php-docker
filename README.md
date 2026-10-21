# php-docker: `php-8.2-fpm-alpine3.23`

PHP 8.2 FPM on Alpine 3.23. The Dockerfile and the `docker-php-*` helpers are taken unchanged
from the official image (docker-library/php, `8.2/alpine3.23/fpm`). The PHP sources come from
php.net and are verified against the release managers' GPG keys during the build.

Image: `ghcr.io/rene-roscher/php-docker:php-8.2-fpm-alpine3.23` (built by the workflow on every
push).

Why it exists: on 21.10.2026 the official `php:8.2.35-fpm-alpine3.23` took hours to become
pullable after the PHP2Shell release (CVE-2026-109618 / CVE-2026-109619). This branch builds the
same image from source so `php-8.2` and `certbot-8.2` did not have to wait. Prefer the official
image once it is available.

To update: copy `8.2/alpine3.23/fpm/` from https://github.com/docker-library/php again.
