# Настроить локальное окружение



### Обновить файл `~/.ssh/config`

Добавить

```yaml
Host swarm-homepage
  HostName __DOCKER_SWARM_SERVER_IP__
  User root
  IdentityFile __путь_к_приватному_ключу__
```



### Добавить `docker context` для swarm-сервера

```shell
docker context create swarm-homepage-context --docker "host=ssh://swarm-homepage"
```

Здесь:

1. `host=ssh://swarm-homepage` это имя ssh соединения, которое мы настроили на прошлом шаге в файле `~/.ssh/config`

2. `swarm-homepage-context` это имя нашего docker-контекста. По имени docker-контекста мы сможем делать запросы
на удалённый docker-хост.

Чтобы проверить, что docker-контекст добавился, можно выполнить:

```shell
docker context ls
```

Чтобы выполнить какую-нибудь команду на удалённом docker-хосте, можно выполнить:

```shell
docker --context swarm-homepage-context run hello-world
```



### Добавить утилиту для более удобных запросов к удалённому docker-хосту

```shell
echo '#!/usr/bin/env bash

docker --context swarm-homepage-context "$@"' > ~/bin/hdocker
```

```shell
chmod +x ~/bin/hdocker
```

Файл можно назвать как угодно. Но здесь первая буква `h` в файле `hdocker` обозначает homepage.
