#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

if [ -z "${DOMAIN:-}" ] \vert{}\vert{} [ "$DOMAIN" = "ejemplo.com" ]; then
    echo "Configura un dominio válido en DOMAIN dentro de scripts/.env antes de ejecutar Certbot."
    exit 1
fi

apt-get update -y
apt-get install -y certbot python3-certbot-apache

certbot --apache \
    -m "$CERTBOT_EMAIL" \
    --agree-tos \
    --no-eff-email \
    -d "$DOMAIN" \
    --non-interactive

systemctl reload apache2

echo "Certificado SSL/TLS de Let's Encrypt configurado para $DOMAIN."