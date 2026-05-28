<?php
/**
 * Seed completo: usuarios, productos y blog.
 * Ejecutar con: wp eval-file scripts/seed-demo-all.php --allow-root
 *
 * Para ejecutar seeds individuales:
 *   wp eval-file scripts/seed-demo-users.php --allow-root
 *   wp eval-file scripts/seed-demo-products.php --allow-root
 *   wp eval-file scripts/seed-demo-blog.php --allow-root
 */

$base = dirname( __FILE__ );

WP_CLI::log( '── Usuarios demo ──────────────────────────────' );
require $base . '/seed-demo-users.php';

WP_CLI::log( '── Productos demo ─────────────────────────────' );
require $base . '/seed-demo-products.php';

WP_CLI::log( '── Blog demo ──────────────────────────────────' );
require $base . '/seed-demo-blog.php';

WP_CLI::success( 'Seed completo finalizado.' );
