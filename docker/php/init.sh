#!/bin/bash
set -e

cd /var/www/html

if [ ! -f "vendor/autoload.php" ] \
  || [ ! -f "web/wp/wp-settings.php" ] \
  || [ ! -f "web/app/plugins/redis-cache/redis-cache.php" ] \
  || [ ! -f "web/app/plugins/woocommerce/woocommerce.php" ] \
  || [ ! -f "web/app/plugins/advanced-custom-fields/acf.php" ]; then
  echo "Installing Composer dependencies..."
  composer install --no-interaction --prefer-dist --optimize-autoloader
fi

echo "Waiting for DB..."

until php -r 'require "/var/www/html/web/wp-config.php"; mysqli_report(MYSQLI_REPORT_OFF); $db = @mysqli_connect(DB_HOST, DB_USER, DB_PASSWORD, DB_NAME); exit($db ? 0 : 1);'; do
  sleep 3
done

echo "DB ready"

echo "Checking WordPress installation..."

if ! wp core is-installed --allow-root; then
  echo "WordPress is not installed. Installing WordPress..."
  wp core install \
    --url="${WP_HOME:-http://localhost:8080}" \
    --title="${WP_TITLE:-TCG Market}" \
    --admin_user="${WP_ADMIN_USER:-admin}" \
    --admin_password="${WP_ADMIN_PASSWORD:-admin}" \
    --admin_email="${WP_ADMIN_EMAIL:-admin@test.com}" \
    --skip-email \
    --allow-root
fi

echo "Configuring WordPress defaults..."
wp rewrite structure '/%postname%/' --allow-root
wp rewrite flush --allow-root

wp plugin activate redis-cache --allow-root || true
wp plugin activate woocommerce --allow-root || true
wp plugin activate advanced-custom-fields --allow-root || true

touch .initialized

echo "Init completed"

exec php-fpm
