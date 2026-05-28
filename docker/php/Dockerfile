FROM php:8.3-fpm

# System deps
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    curl \
    default-mysql-client \
    libzip-dev \
    libpng-dev \
    libonig-dev \
    libicu-dev \
    && docker-php-ext-install \
    pdo \
    pdo_mysql \
    mysqli \
    zip \
    intl \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

COPY opcache.ini /usr/local/etc/php/conf.d/opcache.ini

COPY init.sh /usr/local/bin/init.sh
RUN sed -i 's/\r$//' /usr/local/bin/init.sh \
    && chmod +x /usr/local/bin/init.sh

WORKDIR /var/www/html
