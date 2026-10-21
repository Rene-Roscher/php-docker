# php-docker: `frankenphp-8.4`

FrankenPHP on PHP 8.4 ZTS, a drop-in for `dunglas/frankenphp:1-php8.4` (Debian trixie): same
paths (`/app`, `/config`, `/data`, `/etc/caddy`, `/etc/frankenphp`), environment, ports,
healthcheck and default Caddyfile, plus `install-php-extensions` and the `docker-php-ext-*`
helpers of the PHP base image.

Image: `ghcr.io/rene-roscher/php-docker:frankenphp-8.4` (built by the workflow on every push).

PHP comes from `php-docker:php-8.4-zts-trixie` (built from the php.net sources). FrankenPHP and
the e-dant/watcher library are built from source at the releases pinned in the Dockerfile
(`FRANKENPHP_VERSION`, `WATCHER_VERSION`), with the stages of the upstream Dockerfile, so the
binary is linked against exactly this PHP. The build fails if PHP is older than
`MIN_PHP_VERSION` (8.4.27, PHP2Shell: CVE-2026-109618 / CVE-2026-109619) or not thread safe.

Use: `FROM ghcr.io/rene-roscher/php-docker:frankenphp-8.4`, then your extensions and app as with
the official image. Move back to `dunglas/frankenphp:1-php8.4.27` or newer once it is published.

To update FrankenPHP, raise `FRANKENPHP_VERSION`, and `GO_IMAGE` if its `go.mod` asks for a newer
Go.
