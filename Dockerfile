# syntax=docker/dockerfile:1
#
# FrankenPHP built from source on php-8.4-zts-alpine. Follows the upstream alpine.Dockerfile
# (github.com/php/frankenphp, stages common, builder and runner) at a pinned release, so the
# image only depends on our PHP build and not on when the official image is rebuilt.
#
# Build args:
#   PHP_IMAGE           the ZTS + embed PHP base (default: php-8.4-zts-alpine of this repo)
#   GO_IMAGE            Go toolchain, must satisfy the `go` line of frankenphp's go.mod
#   FRANKENPHP_VERSION  release tag of github.com/php/frankenphp
#   WATCHER_VERSION     release tag of github.com/e-dant/watcher (file watching)
#   MIN_PHP_VERSION     the build fails below this PHP version

ARG PHP_IMAGE=ghcr.io/rene-roscher/php-docker:php-8.4-zts-alpine
ARG GO_IMAGE=golang:1.27-alpine

FROM ${GO_IMAGE} AS golang-base

FROM golang-base AS source

ARG FRANKENPHP_VERSION=v1.13.1
ARG WATCHER_VERSION=0.14.5

RUN set -eux; \
	apk add --no-cache curl git tar; \
	git clone --depth 1 --branch "${FRANKENPHP_VERSION}" https://github.com/php/frankenphp.git /src/frankenphp; \
	mkdir -p /src/watcher; \
	curl -fsSL "https://github.com/e-dant/watcher/archive/refs/tags/${WATCHER_VERSION}.tar.gz" \
		| tar xz --strip-components 1 -C /src/watcher


FROM ${PHP_IMAGE} AS common

ARG MIN_PHP_VERSION=8.4.27

WORKDIR /app

RUN php -r 'exit(version_compare(PHP_VERSION, getenv("MIN_PHP_VERSION"), ">=") && PHP_ZTS ? 0 : 1);' \
	|| { echo "PHP $(php -r 'echo PHP_VERSION;') (ZTS: $(php -r 'echo PHP_ZTS;')) is below ${MIN_PHP_VERSION} or not thread safe" >&2; exit 1; }

RUN apk add --no-cache \
	ca-certificates \
	libcap \
	mailcap

RUN set -eux; \
	mkdir -p \
		/app/public \
		/config/caddy \
		/data/caddy \
		/etc/caddy \
		/etc/frankenphp; \
	sed -i 's/php/frankenphp run/g' /usr/local/bin/docker-php-entrypoint

COPY --link --from=source /src/frankenphp/caddy/frankenphp/Caddyfile /etc/caddy/Caddyfile
COPY --link --from=source /src/frankenphp/package/content/index.php /app/public/index.php

RUN ln /etc/caddy/Caddyfile /etc/frankenphp/Caddyfile && \
	curl -sSLf \
		-o /usr/local/bin/install-php-extensions \
		https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions && \
	chmod +x /usr/local/bin/install-php-extensions

CMD ["--config", "/etc/frankenphp/Caddyfile", "--adapter", "caddyfile"]
HEALTHCHECK CMD curl -f http://localhost:2019/metrics || exit 1

# See https://caddyserver.com/docs/conventions#file-locations for details
ENV XDG_CONFIG_HOME=/config
ENV XDG_DATA_HOME=/data

EXPOSE 80
EXPOSE 443
EXPOSE 443/udp
EXPOSE 2019

LABEL org.opencontainers.image.title=FrankenPHP
LABEL org.opencontainers.image.description="FrankenPHP built from source on php-docker:php-8.4-zts-alpine"
LABEL org.opencontainers.image.url=https://frankenphp.dev
LABEL org.opencontainers.image.source=https://github.com/Rene-Roscher/php-docker
LABEL org.opencontainers.image.licenses=MIT


FROM common AS builder

ARG FRANKENPHP_VERSION=v1.13.1
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

COPY --link --from=golang-base /usr/local/go /usr/local/go

ENV PATH=/usr/local/go/bin:$PATH
ENV GOTOOLCHAIN=local

# hadolint ignore=SC2086
RUN apk add --no-cache --virtual .build-deps \
	$PHPIZE_DEPS \
	argon2-dev \
	bash \
	brotli-dev \
	cmake \
	coreutils \
	curl-dev \
	git \
	gnu-libiconv-dev \
	libsodium-dev \
	libstdc++ \
	libxml2-dev \
	linux-headers \
	oniguruma-dev \
	openssl-dev \
	readline-dev \
	sqlite-dev

COPY --from=source /src/watcher /usr/local/src/watcher
WORKDIR /usr/local/src/watcher
RUN cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && \
	cmake --build build && \
	cmake --install build

COPY --from=source /src/frankenphp /go/src/app

WORKDIR /go/src/app
RUN go mod download

WORKDIR /go/src/app/caddy
RUN go mod download

# See https://github.com/docker-library/php/blob/master/8.3/alpine3.20/zts/Dockerfile#L53-L55
ENV CGO_CFLAGS="-DFRANKENPHP_VERSION=$FRANKENPHP_VERSION $PHP_CFLAGS"
ENV CGO_CPPFLAGS=$PHP_CPPFLAGS
ENV CGO_LDFLAGS="-lssl -lcrypto -lreadline -largon2 -lcurl -lonig -lz $PHP_LDFLAGS"

WORKDIR /go/src/app/caddy/frankenphp
RUN GOBIN=/usr/local/bin \
		../../go.sh install -ldflags "-w -s -extldflags '-Wl,-z,stack-size=0x80000' -X 'github.com/caddyserver/caddy/v2.CustomVersion=FrankenPHP $FRANKENPHP_VERSION PHP $PHP_VERSION Caddy' -X 'github.com/caddyserver/caddy/v2.CustomBinaryName=frankenphp' -X 'github.com/caddyserver/caddy/v2/modules/caddyhttp.ServerHeader=FrankenPHP Caddy'" -buildvcs=true && \
	setcap cap_net_bind_service=+ep /usr/local/bin/frankenphp && \
	frankenphp version && \
	frankenphp build-info

WORKDIR /go/src/app


FROM common AS runner

ARG MIN_PHP_VERSION=8.4.27

ENV GODEBUG=cgocheck=0

# libgcc and libstdc++ are needed for the watcher
COPY --from=builder /usr/local/lib/libwatcher* /usr/local/lib/
RUN apk add --no-cache libstdc++ && \
	ldconfig /usr/local/lib

COPY --from=builder /usr/local/bin/frankenphp /usr/local/bin/frankenphp
RUN setcap cap_net_bind_service=+ep /usr/local/bin/frankenphp && \
	frankenphp version && \
	frankenphp build-info > /dev/null && \
	frankenphp php-cli -r 'exit(version_compare(PHP_VERSION, getenv("MIN_PHP_VERSION"), ">=") ? 0 : 1);'
