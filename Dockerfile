FROM php:8.2-apache-bullseye

# Credit/Initial maintainer: Garcia MICHEL <garcia@soamichel.fr>
# Modified according to the GPL license by developers of the Dolibarr community:
# 2024 Alois Micard
# 2024 Laurent Destailleur
LABEL maintainer="The Dolibarr foundation <contact@dolibarr.org>"

ENV DOLI_VERSION=19.0.4
ENV DOLI_VERSION_FOR_INIT_DEMO=19.0

ENV DOLI_DB_TYPE=mysqli
ENV DOLI_NOCSRFCHECK=0

ENV DOLI_AUTH=dolibarr
ENV DOLI_LDAP_HOST=127.0.0.1
ENV DOLI_LDAP_PORT=389
ENV DOLI_LDAP_VERSION=3
ENV DOLI_LDAP_SERVER_TYPE=openldap
ENV DOLI_LDAP_LOGIN_ATTRIBUTE=uid
ENV DOLI_LDAP_DN='ou=users,dc=my-domain,dc=com'
ENV DOLI_LDAP_FILTER=''
ENV DOLI_LDAP_BIND_DN=''
ENV DOLI_LDAP_BIND_PASS=''
ENV DOLI_LDAP_DEBUG=false

ENV PHP_INI_DATE_TIMEZONE='UTC'
ENV PHP_INI_MEMORY_LIMIT=256M
ENV PHP_INI_UPLOAD_MAX_FILESIZE=20M
ENV PHP_INI_POST_MAX_SIZE=22M
ENV PHP_INI_ALLOW_URL_FOPEN=0

VOLUME /var/www/documents
VOLUME /var/www/html

EXPOSE 80

COPY docker-run.sh /usr/local/bin/

RUN sed -i \
  -e 's/^\(ServerSignature On\)$/#\1/g' \
  -e 's/^#\(ServerSignature Off\)$/\1/g' \
  -e 's/^\(ServerTokens\) OS$/\1 Prod/g' \
  /etc/apache2/conf-available/security.conf && \
  chmod +x /usr/local/bin/docker-run.sh && \
  ln -s /var/www/html /var/www/htdocs

RUN apt-get update -y && \
  apt-get dist-upgrade -y && \
  apt-get install -y --no-install-recommends \
    libc-client-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libkrb5-dev \
    libldap2-dev \
    libldap-common \
    libpng-dev \
    libpq-dev \
    libxml2-dev \
    libzip-dev \
    default-mysql-client \
    postgresql-client \
    vim-tiny \
    cron && \
  apt-get autoremove -y && \
  docker-php-ext-configure gd --with-freetype --with-jpeg && \
  docker-php-ext-install -j$(nproc) calendar intl mysqli pdo_mysql gd soap zip opcache && \
  docker-php-ext-configure pgsql -with-pgsql && \
  docker-php-ext-install pdo_pgsql pgsql && \
  docker-php-ext-configure ldap --with-libdir=lib/$(gcc -dumpmachine)/ && \
  docker-php-ext-install -j$(nproc) ldap && \
  docker-php-ext-configure imap --with-kerberos --with-imap-ssl && \
  docker-php-ext-install imap && \
  mv ${PHP_INI_DIR}/php.ini-development ${PHP_INI_DIR}/php.ini && \
  rm -rf /var/lib/apt/lists/*

RUN pecl install xdebug-3.3.2 && \
  docker-php-ext-enable xdebug && \
  echo "xdebug.mode=debug,develop" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
  echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
  echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

ENTRYPOINT ["docker-run.sh"]

CMD ["apache2-foreground"]
