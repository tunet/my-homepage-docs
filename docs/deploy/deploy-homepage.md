# Deploy homepage



### Добавить файлы для деплоя homepage на сервер

=== ".docker/php/php.prod.ini"

    ```
    apc.enable_cli = 1
    date.timezone = UTC
    session.auto_start = Off
    short_open_tag = Off

    # http://symfony.com/doc/current/performance.html
    opcache.max_accelerated_files = 20000
    realpath_cache_size = 4096K
    realpath_cache_ttl = 600

    opcache.preload=/srv/app/config/preload.php
    opcache.preload_user=www-data
    ```

=== ".docker/php/build.Dockerfile"

    ```
    ARG PHP_VERSION
    ARG NGINX_VERSION



    FROM tunet/php:${PHP_VERSION}-fpm-alpine3.17 as php-base

    COPY ./.docker/php/crontab /var/spool/cron/crontabs/root



    FROM php-base as php-composer

    ARG COMPOSER_VERSION

    RUN apk add --no-cache \
        git \
        && curl -OL https://getcomposer.org/download/${COMPOSER_VERSION}/composer.phar \
        && mv ./composer.phar /usr/bin/composer \
        && chmod +x /usr/bin/composer



    FROM php-composer as php-builded-app-env-prod

    COPY . /srv/app/

    RUN make build-prod



    FROM php-base as backend-env-prod

    RUN echo '' > /srv/app/.env

    COPY ./.docker/php/php.prod.ini /usr/local/etc/php/php.ini

    COPY --from=php-builded-app-env-prod /srv/app/bin/ /srv/app/bin/
    COPY --from=php-builded-app-env-prod /srv/app/config/ /srv/app/config/
    COPY --from=php-builded-app-env-prod /srv/app/migrations/ /srv/app/migrations/
    COPY --from=php-builded-app-env-prod /srv/app/public/ /srv/app/public/
    COPY --from=php-builded-app-env-prod /srv/app/src/ /srv/app/src/
    COPY --from=php-builded-app-env-prod /srv/app/templates/ /srv/app/templates/
    COPY --from=php-builded-app-env-prod /srv/app/var/ /srv/app/var/
    COPY --from=php-builded-app-env-prod /srv/app/vendor/ /srv/app/vendor/
    COPY --from=php-builded-app-env-prod \
        /srv/app/Makefile \
        /srv/app/composer.json \
        /srv/app/composer.lock \
        /srv/app/symfony.lock \
        /srv/app/



    FROM php-composer as backend-env-dev

    ARG XDEBUG_VERSION

    RUN apk update \
        && apk add --no-cache --virtual .build-deps \
            $PHPIZE_DEPS \
        && apk add --update \
            linux-headers \
        && pecl update-channels \
        && pecl install \
            xdebug-${XDEBUG_VERSION} \
        && docker-php-ext-enable xdebug \
        && pecl clear-cache \
        && rm -rf /tmp/* /var/cache/apk/* \
        && apk del .build-deps

    COPY ./.docker/php/php.ini /usr/local/etc/php/php.ini
    COPY . /srv/app/

    RUN make build-dev



    FROM nginx:${NGINX_VERSION}-alpine-slim as frontend-env-prod

    COPY --from=php-builded-app-env-prod /srv/app/public/ /srv/app/public/
    COPY ./.docker/nginx/default.conf /etc/nginx/conf.d/default.conf



    FROM nginx:${NGINX_VERSION}-alpine-slim as frontend-env-dev

    COPY --from=backend-env-dev /srv/app/public/ /srv/app/public/
    COPY ./.docker/nginx/default.conf /etc/nginx/conf.d/default.conf



    FROM php-composer as php-local

    ARG XDEBUG_VERSION

    RUN apk update \
        && apk add --no-cache --virtual .build-deps \
            $PHPIZE_DEPS \
        && apk add --no-cache \
            zsh \
        && apk add --update \
            linux-headers \
        && pecl update-channels \
        && pecl install \
            xdebug-${XDEBUG_VERSION} \
        && docker-php-ext-enable xdebug \
        && pecl clear-cache \
        && rm -rf /tmp/* /var/cache/apk/* \
        && apk del .build-deps

    ARG LINUX_USER_ID

    RUN addgroup --gid $LINUX_USER_ID docker \
        && adduser --uid $LINUX_USER_ID --ingroup docker --home /home/docker --shell /bin/zsh --disabled-password --gecos "" docker

    USER $LINUX_USER_ID

    # ARG COMPOSER_GITHUB_TOKEN
    # RUN composer config --global github-oauth.github.com $COMPOSER_GITHUB_TOKEN

    RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/65a1e4edbe678cdac37ad96ca4bc4f6d77e27adf/tools/install.sh -O - | zsh
    RUN echo 'export ZSH=/home/docker/.oh-my-zsh' > ~/.zshrc \
        && echo 'ZSH_THEME="simple"' >> ~/.zshrc \
        && echo 'source $ZSH/oh-my-zsh.sh' >> ~/.zshrc \
        && echo 'PROMPT="%{$fg_bold[yellow]%}php:%{$fg_bold[blue]%}%(!.%1~.%~)%{$reset_color%} "' > ~/.oh-my-zsh/themes/simple.zsh-theme

    ```

=== ".docker/docker-deploy-stack.yaml"

    ```
    version: '3.9'

    services:
        php:
            image: tunet/homepage-backend:${BACKEND_VERSION}
            networks:
                - webproxy
            environment:
                APP_ENV: ${APP_ENV}
                XDEBUG_CONFIG: client_host=host.docker.internal client_port=17502
                PHP_IDE_CONFIG: serverName=homepage
            extra_hosts:
                - "host.docker.internal:host-gateway"
            secrets:
                - source: symfony_env
                  target: /srv/app/.env
            deploy:
                replicas: 1
                restart_policy:
                condition: on-failure

        nginx:
            image: tunet/homepage-frontend:${FRONTEND_VERSION}
            networks:
                - webproxy
            depends_on:
                - php
            labels:
                - traefik.enable=true
                - traefik.http.routers.webservice.rule=Host(`test-calendar.aliaksandr-kulba.com`)
                - traefik.http.routers.webservice.entrypoints=web
                - traefik.http.routers.webservice.entrypoints=websecure
                - traefik.http.routers.webservice.tls.certresolver=myresolver
                - traefik.http.routers.webservice_http.rule=Host(`test-calendar.aliaksandr-kulba.com`)
                - traefik.http.routers.webservice_http.entrypoints=web
                - traefik.http.routers.webservice_http.middlewares=redirect-to-https
                - traefik.http.middlewares.redirect-to-https.redirectscheme.scheme=https
            deploy:
                replicas: 1
                restart_policy:
                condition: on-failure

        install:
            image: tunet/homepage-backend:${BACKEND_VERSION}
            networks:
                - webproxy
            environment:
                APP_ENV: ${APP_ENV}
            secrets:
                - source: symfony_env
                target: /srv/app/.env
            deploy:
                mode: replicated-job
                replicas: 1
            command: make install

    secrets:
        symfony_env:
            external: true

    networks:
        webproxy:
            external: true
    ```

=== "Makefile"

    ```
    SHELL := /bin/sh
    include .env



    build-prod:
        composer install --no-dev --optimize-autoloader --no-interaction --no-scripts
        APP_ENV=prod bin/console cache:clear
        APP_ENV=prod bin/console cache:warmup

    build-dev:
        composer install --no-interaction --no-scripts
        APP_ENV=dev bin/console cache:clear
        APP_ENV=dev bin/console cache:warmup

    install:
        bin/console doctrine:migrations:migrate --no-interaction

    docker-build:
        ./bin/.deploy/docker-build.sh

    docker-push:
        ./bin/.deploy/docker-push.sh

    deploy-prod:
        make docker-build
        make docker-push
        ./bin/.deploy/deploy.sh prod

    deploy-dev:
        make docker-build
        make docker-push
        ./bin/.deploy/deploy.sh dev



    entity:
        bin/console make:entity

    controller:
        bin/console make:controller

    migration:
        bin/console make:migration



    run-php:
        docker compose exec php zsh



    docker-up: docker-down
        @touch .docker/.zsh_history
        docker compose up -d --build

    docker-down:
        docker compose down

    docker-restart: docker-up

    docker-base-build-and-push:
        docker build \
            -t tunet/php:${PHP_VERSION}-fpm-alpine3.17 \
            -f .docker/php/base.Dockerfile \
            --build-arg PHP_VERSION=${PHP_VERSION} \
            .
        docker push tunet/php:${PHP_VERSION}-fpm-alpine3.17



    .PHONY: tests
    ```

=== "bin/.deploy/deploy.sh"

    ```bash
    #!/usr/bin/env bash
    set -e

    source .env

    APP_ENV=$@ \
    BACKEND_VERSION=latest-env-$@ \
    FRONTEND_VERSION=latest-env-$@ \
        hdocker compose -f .docker/docker-deploy-stack.yaml pull

    hdocker stack rm application

    APP_ENV=$@ \
    BACKEND_VERSION=latest-env-$@ \
    FRONTEND_VERSION=latest-env-$@ \
        hdocker stack deploy -c .docker/docker-deploy-stack.yaml application
    ```

=== "bin/.deploy/docker-build.sh"

    ```bash
    #!/usr/bin/env bash

    source .env

    docker build \
        -t tunet/homepage-backend:latest-env-prod \
        -f ./.docker/php/build.Dockerfile \
        --target backend-env-prod \
        --build-arg NGINX_VERSION=${NGINX_VERSION} \
        --build-arg PHP_VERSION=${PHP_VERSION} \
        --build-arg XDEBUG_VERSION=${XDEBUG_VERSION} \
        --build-arg COMPOSER_VERSION=${COMPOSER_VERSION} \
        .

    docker build \
        -t tunet/homepage-backend:latest-env-dev \
        -f ./.docker/php/build.Dockerfile \
        --target backend-env-dev \
        --build-arg NGINX_VERSION=${NGINX_VERSION} \
        --build-arg PHP_VERSION=${PHP_VERSION} \
        --build-arg XDEBUG_VERSION=${XDEBUG_VERSION} \
        --build-arg COMPOSER_VERSION=${COMPOSER_VERSION} \
        .

    docker build \
        -t tunet/homepage-frontend:latest-env-prod \
        -f ./.docker/php/build.Dockerfile \
        --target frontend-env-prod \
        --build-arg PHP_VERSION=${PHP_VERSION} \
        --build-arg NGINX_VERSION=${NGINX_VERSION} \
        --build-arg XDEBUG_VERSION=${XDEBUG_VERSION} \
        --build-arg COMPOSER_VERSION=${COMPOSER_VERSION} \
        .

    docker build \
        -t tunet/homepage-frontend:latest-env-dev \
        -f ./.docker/php/build.Dockerfile \
        --target frontend-env-dev \
        --build-arg PHP_VERSION=${PHP_VERSION} \
        --build-arg NGINX_VERSION=${NGINX_VERSION} \
        --build-arg XDEBUG_VERSION=${XDEBUG_VERSION} \
        --build-arg COMPOSER_VERSION=${COMPOSER_VERSION} \
        .
    ```

=== "bin/.deploy/docker-push.sh"

    ```bash
    #!/usr/bin/env bash

    docker push tunet/homepage-backend:latest-env-prod
    docker push tunet/homepage-backend:latest-env-dev
    docker push tunet/homepage-frontend:latest-env-prod
    docker push tunet/homepage-frontend:latest-env-dev
    ```

### Создать secret в docker-swarm

```shell
hdocker secret create symfony_env __путь_к_файлу__
```
