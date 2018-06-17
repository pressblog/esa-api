# EsaApi

このライブラリはesaのapiを利用してバッチ処理を行うためのものです。

## setup

```sh
$ docker-compose build
$ cp .env.sample .env
$ vim .env
# ESA_ACCESS_TOKENに発行したトークンを設定する
```

## タスク一覧

```sh
$ docker-compose run --rm app rake -T
```

### タスク実行時の環境変数の指定方法

```sh
$ docker-compose run --rm app rake task_name NAME=hoge TEAM=piyo
or
$ docker-compose run --rm -e NAME=hoge -e TEAM=piyo app rake task_name
```

## デバッグ

```sh
$ docker-compose run --rm app pry
```
