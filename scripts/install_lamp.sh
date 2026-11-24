#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ "$(id -u)" -ne 0 ]; then
    echo "Ejecuta este script como root o con sudo."
    exit 1
fi

apt-get update -y
apt-get install -y apache2 mariadb-server php libapache2-mod-php php-mysql php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip unzip curl

if [ -f "$REPO_DIR/conf/000-default.conf" ]; then
    cp "$REPO_DIR/conf/000-default.conf" /etc/apache2/sites-available/000-default.conf
fi

a2enmod rewrite
systemctl enable apache2 mariadb
systemctl restart apache2 mariadb

echo "Instalación LAMP completada correctamente."