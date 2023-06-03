# Deploy traefik



### Создать docker-сеть `webproxy` для traefik

```shell
hdocker network create --driver=overlay webproxy
```



### Добавить `label` для текущего узла `swarm`

```shell
hdocker node update --label-add webproxy.traefik-public-certificates=true $(hdocker info -f '{{.Swarm.NodeID}}')
```

Этот `label` нужен, чтобы деплоить `traefik` всегда только на главный узел swarm-кластера
(если вдруг узлов потом станет больше чем один).



### Добавить в панели управления DNS запись для traefik

Пример:

```
traefik.aliaksandr-kulba.com.   A   __IP_АДРЕС_СЕРВЕРА__
```



### Создать файлы для деплоя traefik на сервер

=== "docker-deploy-stack.yaml"

    ```yaml
    version: '3.9'

    services:
      traefik:
        image: traefik:${TRAEFIK_VERSION}
        networks:
          - webproxy
        command:
          - --api.dashboard=true
          - --providers.docker=true
          - --providers.docker.exposedbydefault=false
          - --entrypoints.web.address=:80
          - --entrypoints.websecure.address=:443
          - --certificatesresolvers.myresolver.acme.tlschallenge=true
          - --certificatesresolvers.myresolver.acme.email=${ADMIN_EMAIL}
          - --certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json
          - --entrypoints.web.http.redirections.entryPoint.to=websecure
          - --entrypoints.web.http.redirections.entryPoint.scheme=https
        labels:
          - traefik.enable=true
          - traefik.http.routers.traefik.rule=Host(`${TRAEFIK_DOMAIN}`)
          - traefik.http.routers.traefik.entrypoints=websecure
          - traefik.http.routers.traefik.tls.certresolver=myresolver
          - traefik.http.routers.traefik.service=api@internal
          - traefik.http.routers.traefik.middlewares=traefik-basic-auth
          - traefik.http.middlewares.traefik-basic-auth.basicauth.users=admin:${TRAEFIL_PASSWORD}
        ports:
          - '80:80'
          - '443:443'
        volumes:
          - letsencrypt:/letsencrypt
          - /var/run/docker.sock:/var/run/docker.sock:ro
        deploy:
          placement:
            constraints:
              - node.labels.webproxy.traefik-public-certificates == true
          replicas: 1
          restart_policy:
            condition: on-failure

    volumes:
      letsencrypt:

    networks:
      webproxy:
        external: true
    ```

=== ".env"

    ```
    TRAEFIK_VERSION=2.9.10
    ADMIN_EMAIL=__ВАШ_EMAIL__
    TRAEFIK_DOMAIN=traefik.aliaksandr-kulba.com
    TRAEFIL_PASSWORD=__ШИФРОВАННЫЙ_ПАРОЛЬ__
    ```

=== "deploy.sh"

    ```bash
    #!/usr/bin/env bash
    set -e

    source .env

    hdocker pull traefik:${TRAEFIK_VERSION}

    hdocker stack rm traefik

    TRAEFIK_VERSION=${TRAEFIK_VERSION} \
    TRAEFIK_DOMAIN=${TRAEFIK_DOMAIN} \
    TRAEFIL_PASSWORD=${TRAEFIL_PASSWORD} \
        hdocker stack deploy -c docker-deploy-stack.yaml traefik
    ```
