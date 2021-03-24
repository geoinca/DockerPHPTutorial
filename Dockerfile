FROM php:7.4-apache

RUN apt-get update
# 1. development packages

RUN apt-get install -y \
    git \
    zip \
    curl \
    wget \
    sudo \
    unzip \
    libicu-dev \
    libbz2-dev \
    libpng-dev \
    libjpeg-dev \
    libmcrypt-dev \
    libreadline-dev \
    libfreetype6-dev \
    g++ \
    --no-install-recommends

# 2. apache configs + document root
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf


# 3. mod_rewrite for URL rewrite and mod_headers for .htaccess extra headers like Access-Control-Allow-Origin-
RUN a2enmod rewrite headers

# 4. start with base php config, then add extensions
# Install PHP intl module
RUN apt-get update && apt-get install -y libicu-dev \
	&& docker-php-ext-configure intl \
	&& docker-php-ext-install intl
# Install PHP database modules
RUN docker-php-ext-install pdo pdo_mysql mysqli 
# PHP Zip Archive
RUN apt-get install -y zlib1g-dev \
     libzip-dev \
     zip 

# Install PHP String module
#RUN docker-php-ext-install mbstring

RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

RUN docker-php-ext-install \
    bz2 \
    intl \
    iconv \
    bcmath \
    opcache \
    calendar  


# 5. composer
#Install Composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php composer-setup.php --install-dir=. --filename=composer
RUN mv composer /usr/local/bin/
RUN wget https://dl.min.io/client/mc/release/linux-amd64/mc
RUN chmod +x mc
RUN cp mc /usr/local/bin 
RUN wget https://github.com/argoproj/argo/releases/download/v2.12.10/argo-linux-amd64.gz
RUN gunzip argo-linux-amd64.gz
RUN chmod +x argo-linux-amd64
RUN mv ./argo-linux-amd64 /usr/local/bin/argo
# Set your timezone here
RUN rm /etc/localtime
RUN ln -s /usr/share/zoneinfo/Europe/Madrid /etc/localtime
RUN "date"

# Install Node.js (LTS version 8.11.1)
ENV NODE_VERSION=12.21.0
RUN curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
    && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
    && rm "node-v$NODE_VERSION-linux-x64.tar.xz" \
    && ln -s /usr/local/bin/node /usr/local/bin/nodejs \
    && node -v \
    && npm -v 

# 6.  Create system user to run Composer and Artisan Commands
ENV user=demo
ENV uid=1000
##RUN usermod -u $uid www-data \
##    && groupmod -g $uid www-data
RUN useradd -rm -d /home/www-data -s /bin/bash -g www-data  -u $uid $user
RUN chgrp -R www-data /var/www \
    && sudo chmod -R g+w /var/www \
    && usermod -a -G www-data demo
#USER www-data

#RUN mkdir -p /home/devuser/.composer && \
#    chown -R devuser:devuser /home/devuser

# Set Profile to All Files
#RUN chown -R $user:$user /var/www/



EXPOSE 80
