FROM php:8.2.19-fpm-alpine3.19

LABEL version="1.0.0"
LABEL description="NODE - PHP backend for multi-depot stock management"

RUN docker-php-ext-install pdo pdo_mysql

WORKDIR /var/www/html

COPY public/ /var/www/html/

EXPOSE 9000
