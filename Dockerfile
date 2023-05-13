FROM php:8.1-fpm-alpine
# Install the php extension installer from its image
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
# Install dependencies
RUN apk add --no-cache \
    openssl \
    ca-certificates \
    libxml2-dev \
    oniguruma-dev \
    vim
# Install php extensions
RUN install-php-extensions \
    bcmath \
    ctype \
    dom \
    fileinfo \
    mbstring \
    pdo pdo_mysql \
    tokenizer \
    pcntl \
    redis-stable \
    gd \
    zip

# Install the composer packages using www-data user
WORKDIR /app
RUN chown www-data:www-data /app
COPY --chown=www-data:www-data . .
COPY --from=composer:2.2 /usr/bin/composer /usr/bin/composer
USER www-data
RUN composer install

RUN mkdir -p storage/framework/sessions
RUN mkdir -p storage/framework/views
RUN mkdir -p storage/framework/cache

RUN chmod -R 775 storage/framework
RUN chown -R www-data:www-data storage/framework

# Setup nginx & supervisor as root user
USER root
RUN apk add --no-progress --quiet --no-cache nginx supervisor
COPY ./docker/nginx.conf /etc/nginx/http.d/default.conf
COPY ./docker/supervisord.conf /etc/supervisord.conf

# Apply the required changes to run nginx as www-data user
RUN chown -R www-data:www-data /run/nginx /var/lib/nginx /var/log/nginx && \
    sed -i '/user nginx;/d' /etc/nginx/nginx.conf
# Switch to www-user
USER www-data

EXPOSE 8000
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
