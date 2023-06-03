# Установка и настройка PostgreSQL



### Установка

```shell
apt update
```

```shell
apt install postgresql
```

### Создание пользователя и БД

```shell
sudo -u postgres createuser --interactive
```

```shell
sudo -u postgres createdb __название_БД__
```

```shell
sudo -u postgres psql
```

```psql
psql=# alter user <username> with encrypted password '<password>';
```

В приведённом выше примере, чтобы всё заработало, нужно чтобы БД и пользователь назывались одинаково.
