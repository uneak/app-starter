# app-starter

## Build Image
---
docker-compose build --pull --no-cache 


## Run
--- 
docker-compose up -d
# build image
docker-compose up -d --build
docker-compose --env-file .env up -d --build

## Stop
---
docker-compose down --remove-orphans

## consume message:
---
docker-compose exec php bin/console messenger:consume async_high async async_low -vv

## composer require
---
docker-compose exec php composer require amqp-messenger
docker-compose exec php composer require elasticsearch/elasticsearch