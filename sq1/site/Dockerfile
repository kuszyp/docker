FROM node:12.22.12-bullseye as theme
COPY html***REMOVED*** /home/node/app
WORKDIR /home/node/app
RUN npm install && npm run build

WORKDIR /home/node/app/react
RUN npm install && npm install react-scripts && npm run production

# Usr php8.2 image and add extensions that would be used
FROM php:8.2-cli as plugin
RUN apt-get update && apt-get install -y \
  unzip git curl && \
  rm -rf /var/lib/apt/lists/*

# Download docker-php-extension-installer and install required extensions
ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN install-php-extensions zip
COPY --chmod=0755 html***REMOVED*** /app
WORKDIR /app
RUN php composer.phar self-update && php composer.phar update --with-all-dependencies --ignore-platform-reqs

# Brand new image for wordpress 6.8.2
FROM wordpress:6.8.2-php8.2-apache as site
#RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Update the dist and install expected packages
RUN apt-get update && apt-get upgrade -y && apt-get install -y git gcc curl apache2

# Copy entire site into new image
COPY --chown=www-data:www-data html /var/www/html

# Remove theme build and copy it from theme container
RUN rm -rf /var/www/html***REMOVED***/build \
  && rm -rf /var/www/html***REMOVED***/react/dist \
  && rm -rf /var/www/html***REMOVED***

COPY --chown=www-data:www-data --from=theme /home/node/app/build /var/www/html***REMOVED***/build
COPY --chown=www-data:www-data --from=theme /home/node/app/react/dist /var/www/html***REMOVED***/react/dist
COPY --chown=www-data:www-data --from=plugin /app /var/www/html***REMOVED***

RUN cp /etc/apache2/mods-available/headers.load /etc/apache2/mods-enabled/ \
  && cp /etc/apache2/mods-available/ssl.load /etc/apache2/mods-enabled/

COPY default-ssl.conf /etc/apache2/sites-enabled 
COPY pod-local-key.pem /etc/ssl/private
COPY pod-local-cert.pem /etc/ssl/certs
COPY ***REMOVED*** /usr/local/etc/php/conf.d/***REMOVED***
COPY ***REMOVED*** /etc/apache2/conf-enabled/***REMOVED***
COPY security.conf /etc/apache2/conf-enabled/security.conf


COPY --chown=www-data:www-data wp-config-docker.php /usr/src/wordpress/
COPY --chmod=0755 docker-entrypoint.sh /usr/local/bin/
# https://github.com/docker-library/wordpress/issues/969
RUN ln -svfT /usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-ensure-installed.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["apache2-foreground"]

