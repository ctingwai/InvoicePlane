FROM node:lts as builder
# install grunt
RUN npm install -g grunt-cli
# copy source files
COPY . /app
WORKDIR /app
# build assets
RUN grunt build

# start with our base image - php apache
FROM php:7.3-apache
# install all the system dependencies and enable PHP modules
RUN apt-get update && apt-get install -y \
      libfreetype6-dev \
      libjpeg62-turbo-dev \
      libpng-dev \
      libicu-dev \
      libpq-dev \
      libxml2-dev \
      libmcrypt-dev \
      librecode-dev \
      git \
    && rm -r /var/lib/apt/lists/*
RUN pecl install mcrypt
RUN docker-php-ext-enable mcrypt
RUN docker-php-ext-install -j$(nproc) gd
RUN docker-php-ext-install \
      mysqli \
      recode \
      hash \
      json \
      xmlrpc \
      mbstring
# Copy built file
COPY --from=builder /app .
# change uid and gid of apache to docker user uid/gid
RUN usermod -u 1000 www-data && groupmod -g 1000 www-data
# enable apache module rewrite
RUN a2enmod rewrite
# install composer and all dependencies
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer
RUN composer install --no-interaction
# work directory
WORKDIR /var/www/html
#change ownership of our applications
RUN chown -R www-data:www-data /var/www/html
