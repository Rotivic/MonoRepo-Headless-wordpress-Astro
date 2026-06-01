<?php

/**
 * Plugin Name: TCG Platform API
 * Description: REST API endpoints for the TCG Platform apps.
 * Author: TCG Platform
 * Version: 0.1.0
 */

if (! defined('ABSPATH')) {
    exit;
}

require_once __DIR__ . '/tcg-api/modules/Wishlist.php';
require_once __DIR__ . '/tcg-api/modules/Cart.php';
require_once __DIR__ . '/tcg-api/modules/Coupons.php';
require_once __DIR__ . '/tcg-api/modules/Checkout.php';
require_once __DIR__ . '/tcg-api/modules/Orders.php';
require_once __DIR__ . '/tcg-api/tcg-api.php';
