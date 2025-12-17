# -------------------------------------------------------------
# ETAPA 1: CONFIGURACIÓN DE IMAGEN BASE Y ARGUMENTOS
# -------------------------------------------------------------

# Define la versión de PHP. Su uso antes de FROM permite que la imagen base sea dinámica.
ARG PHP_V=8.3
FROM php:${PHP_V}-apache

# ARGUMENTOS REDECLARADOS: Estas variables se deben volver a declarar si se usarán
# después del comando FROM, ya que FROM inicia una nueva etapa de construcción
ARG PHP_V
ARG PHALCON_V
ARG AZURE_PERSONAL_TOKEN

# Configuración para evitar interacciones durante la instalación de paquetes (práctica estándar)
ARG DEBIAN_FRONTEND=noninteractive

# Define el directorio de trabajo por defecto para la aplicación web
WORKDIR /var/www/html

# -------------------------------------------------------------
# ETAPA 2: CONFIGURACIÓN DE APACHE Y HERRAMIENTAS
# -------------------------------------------------------------

# Copia la configuración de VirtualHost (app.conf) y la configura en Apache
COPY app.conf /etc/apache2/sites-available/app.conf

# Descarga el script instalador de extensiones de PHP (previene la necesidad de compilar muchas extensiones a mano)
ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

# -------------------------------------------------------------
# ETAPA 3: INSTALACIÓN Y CONFIGURACIÓN PRINCIPAL
# -------------------------------------------------------------

# Ejecuta todas las instalaciones y configuraciones en una sola capa (RUN) para optimizar el tamaño de la imagen final.
RUN mkdir -p /etc/apt/keyrings \
    # 1. ACTUALIZACIÓN E INSTALACIÓN DE DEPENDENCIAS \
    && apt-get update && apt-get upgrade -y \
    && apt-get install -y \
    git \
    zip \
    unzip \
    curl \
    libzip-dev \
    # 2. INSTALACIÓN DE EXTENSIONES DE PHP \
    && install-php-extensions \
    pdo_pgsql \
    pgsql \
    xdebug \
    # 3. CONFIGURACIÓN DE EXTENSIONES DE PHP \
    # 4. INSTALACIÓN DE PHALCON \
    && echo https://github.com/phalcon/cphalcon/releases/download/v${PHALCON_V}/phalcon-php${PHP_V}-nts-ubuntu-gcc-x64.zip \
    && curl -L -o /tmp/phalcon.zip https://github.com/phalcon/cphalcon/releases/download/v${PHALCON_V}/phalcon-php${PHP_V}-nts-ubuntu-gcc-x64.zip \
    && unzip /tmp/phalcon.zip -d /tmp \
    && mv /tmp/phalcon.so $(php -r 'echo ini_get("extension_dir");')/phalcon.so \
    && echo "extension=phalcon.so" > /usr/local/etc/php/conf.d/phalcon.ini \
    # 5. INSTALACIÓN DE COMPOSER \
    && curl -sLS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer \
    #    Establece el token personal de Azure para poder instalar PHP-RAC \
    && composer config --global --auth http-basic.dev.azure.com Coppel-Retail ${AZURE_PERSONAL_TOKEN} \
    # 6. CONFIGURACIÓN DE PHP Y APACHE \
    #    Establece el php.ini optimizado para desarrollo \
    && mv "${PHP_INI_DIR}/php.ini-development" "${PHP_INI_DIR}/php.ini" \
    #    Habilita mod_rewrite para URLs limpias y el VirtualHost de la aplicación \
    && a2enmod rewrite \
    && a2ensite app.conf \
    && a2dissite 000-default.conf \
    # 7. LIMPIEZA FINAL (reduce significativamente el tamaño de la imagen) \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE 80
