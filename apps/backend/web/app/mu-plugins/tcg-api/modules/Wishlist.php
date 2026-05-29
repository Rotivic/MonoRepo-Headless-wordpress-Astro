<?php

declare(strict_types=1);

if (! defined('ABSPATH')) {
    exit;
}

final class TCG_Platform_API_Wishlist
{
    public static function install(): void
    {
        global $wpdb;

        require_once ABSPATH . 'wp-admin/includes/upgrade.php';

        $table = self::table();
        $charset_collate = $wpdb->get_charset_collate();

        $sql = "CREATE TABLE {$table} (
            id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
            user_id BIGINT UNSIGNED NOT NULL,
            product_id BIGINT UNSIGNED NOT NULL,
            created_at DATETIME NOT NULL,
            PRIMARY KEY (id),
            UNIQUE KEY user_product (user_id, product_id),
            KEY user_id (user_id),
            KEY product_id (product_id),
            KEY created_at (created_at)
        ) {$charset_collate};";

        dbDelta($sql);
    }

    public static function register_routes(string $namespace): void
    {
        register_rest_route($namespace, '/wishlist', [
            [
                'methods' => WP_REST_Server::READABLE,
                'callback' => [self::class, 'index'],
                'permission_callback' => ['TCG_Platform_API', 'require_auth'],
            ],
            [
                'methods' => WP_REST_Server::CREATABLE,
                'callback' => [self::class, 'store'],
                'permission_callback' => ['TCG_Platform_API', 'require_auth'],
                'args' => self::product_args(),
            ],
        ]);

        register_rest_route($namespace, '/wishlist/(?P<product_id>\d+)', [
            'methods' => WP_REST_Server::DELETABLE,
            'callback' => [self::class, 'destroy'],
            'permission_callback' => ['TCG_Platform_API', 'require_auth'],
        ]);
    }

    public static function index(WP_REST_Request $request): WP_REST_Response
    {
        global $wpdb;

        $user_id = get_current_user_id();
        $rows = $wpdb->get_results($wpdb->prepare(
            'SELECT product_id, created_at FROM ' . self::table() . ' WHERE user_id = %d ORDER BY created_at DESC',
            $user_id
        ));

        $items = array_map([self::class, 'item_payload_from_row'], $rows ?: []);

        return new WP_REST_Response([
            'data' => array_values(array_filter($items)),
        ]);
    }

    public static function store(WP_REST_Request $request): WP_REST_Response|WP_Error
    {
        global $wpdb;

        $product_id = absint($request->get_param('product_id'));
        $product    = self::get_product($product_id);

        if (! $product instanceof WC_Product) {
            return self::error('tcg_wishlist_product_not_found', 'Product not found.', 404);
        }

        $wpdb->query($wpdb->prepare(
            'INSERT IGNORE INTO ' . self::table() . ' (user_id, product_id, created_at) VALUES (%d, %d, %s)',
            get_current_user_id(),
            $product_id,
            TCG_Platform_API::now()
        ));

        return new WP_REST_Response([
            'data' => self::item_payload($product),
        ], 201);
    }

    public static function destroy(WP_REST_Request $request): WP_REST_Response
    {
        global $wpdb;

        $wpdb->delete(
            self::table(),
            [
                'user_id'    => get_current_user_id(),
                'product_id' => absint($request['product_id']),
            ],
            ['%d', '%d']
        );

        return new WP_REST_Response(['message' => 'Removed from wishlist.']);
    }

    private static function product_args(): array
    {
        return [
            'product_id' => [
                'required' => true,
                'type' => 'integer',
                'minimum' => 1,
                'sanitize_callback' => 'absint',
            ],
        ];
    }

    private static function item_payload_from_row(object $row): ?array
    {
        $product = self::get_product((int) $row->product_id);

        if (! $product instanceof WC_Product) {
            return null;
        }

        return self::item_payload($product, (string) $row->created_at);
    }

    private static function item_payload(WC_Product $product, string $created_at = ''): array
    {
        // Para variaciones, los datos de navegación deben venir del padre.
        $parent = $product instanceof WC_Product_Variation
            ? wc_get_product($product->get_parent_id())
            : null;

        // Slug y permalink: siempre del padre (las variaciones no tienen URL propia).
        $nav = ($parent instanceof WC_Product) ? $parent : $product;

        // Imagen: primero la propia de la variación; si no tiene, la del padre.
        $image_id = $product->get_image_id() ?: ($parent instanceof WC_Product ? $parent->get_image_id() : 0);
        $image    = $image_id ? wp_get_attachment_image_url($image_id, 'woocommerce_thumbnail') : '';

        $price = function_exists('wc_price')
            ? html_entity_decode(wp_strip_all_tags(wc_price((float) $product->get_price())), ENT_QUOTES, get_bloginfo('charset'))
            : (string) $product->get_price();

        return [
            'product_id'  => $product->get_id(),
            'slug'        => $nav->get_slug(),
            // get_name() en una variación incluye los atributos: "Padre - Attr1, Attr2"
            'name'        => $product->get_name(),
            'price'       => $price,
            'image'       => $image ?: '',
            'is_in_stock' => $product->is_in_stock(),
            'permalink'   => $nav->get_permalink(),
            'created_at'  => $created_at,
        ];
    }

    private static function get_product(int $product_id): ?WC_Product
    {
        if (! function_exists('wc_get_product')) {
            return null;
        }

        $product = wc_get_product($product_id);

        if (! $product instanceof WC_Product || $product->get_status() !== 'publish') {
            return null;
        }

        return $product;
    }

    private static function table(): string
    {
        global $wpdb;

        return $wpdb->prefix . 'tcg_wishlist_items';
    }

    private static function error(string $code, string $message, int $status): WP_Error
    {
        return new WP_Error($code, $message, ['status' => $status]);
    }
}
