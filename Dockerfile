FROM php:8.2-apache

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    libxml2-dev \
    libzip-dev \
    libonig-dev \
    zip \
    unzip \
    && docker-php-ext-install dom xml xmlwriter mbstring zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Set the document root
WORKDIR /var/www/html

# Copy application files
COPY . /var/www/html/

# Install dependencies
RUN composer install --no-interaction --prefer-dist

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

CMD ["apache2-foreground"]