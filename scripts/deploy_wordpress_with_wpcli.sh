#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [ "$(id -u)" -ne 0 ]; then
    echo "Ejecuta este script como root o con sudo."
    exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
    echo "No se encuentra $ENV_FILE"
    exit 1
fi

set -a
source "$ENV_FILE"
set +a

# Instalar WP-CLI si no está disponible
if ! command -v wp >/dev/null 2>&1; then
    curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /tmp/wp-cli.phar
    chmod +x /tmp/wp-cli.phar
    mv /tmp/wp-cli.phar /usr/local/bin/wp
fi

# Preparar /var/www/html
mkdir -p /var/www/html
rm -rf /var/www/html/*

# Descargar WordPress y configurar base de datos
wp core download --locale="$WP_LOCALE" --path=/var/www/html --allow-root

mysql -u root <<EOF
DROP DATABASE IF EXISTS \`${DB_NAME}\`;
CREATE DATABASE \`${DB_NAME}\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
DROP USER IF EXISTS '${DB_USER}'@'localhost';
CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

wp config create \
    --dbname="$DB_NAME" \
    --dbuser="$DB_USER" \
    --dbpass="$DB_PASSWORD" \
    --dbhost="localhost" \
    --path=/var/www/html \
    --allow-root

wp core install \
    --url="$WP_URL" \
    --title="$WP_TITLE" \
    --admin_user="$WP_ADMIN_USER" \
    --admin_password="$WP_ADMIN_PASSWORD" \
    --admin_email="$WP_ADMIN_EMAIL" \
    --path=/var/www/html \
    --allow-root

# Copiar .htaccess y configurar permisos
if [ -f "$REPO_DIR/htaccess/.htaccess" ]; then
    cp "$REPO_DIR/htaccess/.htaccess" /var/www/html/.htaccess
fi

chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

echo "Despliegue de WordPress con WP-CLI completado."