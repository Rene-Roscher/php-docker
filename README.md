# php-docker: `php-8.4-zts-trixie`

PHP 8.4 with ZTS and `--enable-embed` on Debian trixie. The Dockerfile and the `docker-php-*`
helpers are taken unchanged from the official image (docker-library/php, `8.4/trixie/zts`). The
PHP sources come from php.net and are verified against the release managers' GPG keys during
the build.

Image: `ghcr.io/rene-roscher/php-docker:php-8.4-zts-trixie` (built by the workflow on every push).

Why it exists: on 21.10.2026 the official `php:8.4.27-zts-trixie` took hours to become
pullable after the PHP2Shell release (CVE-2026-109618 / CVE-2026-109619). This branch builds the
same image from source so dependent images (see `frankenphp-8.4`) did not have to wait. Prefer the
official image once it is available.

To update: copy `8.4/trixie/zts/` from https://github.com/docker-library/php again.
