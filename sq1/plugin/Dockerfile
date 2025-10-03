FROM php:8.2-cli

# Install dependencies
RUN apt-get update && apt-get install -y \
  unzip git curl && \
  rm -rf /var/lib/apt/lists/*

# Download docker-php-extension-installer and install required extensions
ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN install-php-extensions zip

WORKDIR /app

# Copy entrypoint script
COPY --chmod=0755 entrypoint.sh /entrypoint.sh

# Entrypoint script
ENTRYPOINT ["/entrypoint.sh"]

# Default command
CMD ["php", "--version"]
