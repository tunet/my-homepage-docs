# Развернуть docker swarm



### Обновить ПО на сервере

```shell
apt update
```

```shell
apt upgrade
```

```shell
reboot
```



### Установить docker на сервере

[Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)



### Донастроить SSH на сервере

```shell
sed  -i '1i PubkeyAcceptedKeyTypes=+ssh-rsa' /etc/ssh/sshd_config
```

```shell
service ssh restart
```

(нужно было для подключения некоторых клиентов БД по SSH-тунелю)

Найдите в файле `/etc/ssh/sshd_config` настройку `GatewayPorts`.
При необходимости раскомментируйте и замените значение на `yes`.

```shell
service ssh restart
```

(нужно было для работы docker + xdebug + vscode)



### Запустить docker в режиме swarm

```shell
docker swarm init --advertise-addr __IP_ADDRESS_ТЕКУЩЕГО_СЕРВЕРА__
```
