<?php

declare(strict_types=1);

if (! defined('ABSPATH')) {
    exit;
}

final class TCG_Platform_API_Cart
{
    use TCG_API_ErrorTrait;
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
            quantity INT UNSIGNED NOT NULL DEFAULT 1,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL,
            PRIMARY KEY (id),
            UNIQUE KEY user_product (user_id, product_id),
            KEY user_id (user_id),
            KEY product_id (product_id),
            KEY updated_at (updated_at)
        ) {$charset_collate};";

        dbDelta($sql);
    }

    public static function register_routes(string $namespace): void
    {
        register_rest_route($namespace, '/cart', [
            [
                'methods' => WP_REST_Server::READABLE,
                'callback' => [self::class, 'index'],
                'permission_callback' => ['TCG_Platform_API', 'require_auth'],
            ],
            [
                'methods' => WP_REST_Server::CREATABLE,
                'callback' => [self::class, 'store'],
                'permission_callback' => ['TCG_Platform_API', 'require_auth'],
                'args' => self::item_args(),
            ],
            [
                'methods' => WP_REST_Server::DELETABLE,
                'callback' => [self::class, 'clear'],
                'permission_callback' => ['TCG_Platform_API', 'require_auth'],
            ],
        ]);

        register_rest_route($namespace, '/cart/merge', [
            'methods' => WP_REST_Server::CREATABLE,
            'callback' => [self::class, 'merge'],
            'permission_callback' => ['TCG_Platform_API', 'require_auth'],
        ]);

        register_rest_route($namespace, '/cart/(?P<product_id>\d+)', [
            [
                'methods' => WP_REST_Server::EDITABLE,
                'callback' => [self::class, 'update'],
                'permission_callback' => ['TCG_Platform_API', 'require_auth'],
                'args' => [
                    'quantity' => [
                        'required' => true,
                        'type' => 'integer',
                        'minimum' => 0,
                        'sanitize_callback' => 'absint',
                    ],
                ],
            ],
            [
                'methods' => WP_REST_Server::DELETABLE,
                'callback' => [self::class, 'destroy'],
                'permission_callback' => ['TCG_Platform_API', 'require_auth'],
            ],
        ]);
    }

    public static function index(): WP_REST_Response
    {
        return self::cart_response();
    }

    public static function store(WP_REST_Request $request): WP_REST_Response|WP_Error
    {
        $product_id = absint($request->get_param('product_id'));
        $quantity = max(1, absint($request->get_param('quantity')));

        $result = self::add_or_increment($product_id, $quantity);
        if (is_wp_error($result)) {
            return $result;
        }

        return self::cart_response(201);
    }

    public static function update(WP_REST_Request $request): WP_REST_Response|WP_Error
    {
        $product_id = absint($request['product_id']);
        $quantity = absint($request->get_param('quantity'));

        if ($quantity === 0) {
            self::delete_item($product_id);
            return self::cart_response();
        }

        $validation = self::validate_quantity($product_id, $quantity);
        if (is_wp_error($validation)) {
            return $validation;
        }

        self::upsert_quantity($product_id, $quantity);

        return self::cart_response();
    }

    public static function destroy(WP_REST_Request $request): WP_REST_Response
    {
        self::delete_item(absint($request['product_id']));

        return self::cart_response();
    }

    public static function clear(): WP_REST_Response
    {
        global $wpdb;

        $wpdb->delete(self::table(), ['user_id' => get_current_user_id()], ['%d']);

        return self::cart_response();
    }

    public static function merge(WP_REST_Request $request): WP_REST_Response|WP_Error
    {
        $items = $request->get_param('items');
        if (! is_array($items)) {
            return self::error('tcg_cart_invalid_items', 'Cart items must be an array.', 422);
        }

        $errors = [];

        foreach ($items as $item) {
            if (! is_array($item)) {
                continue;
            }

            $product_id = absint($item['product_id'] ?? $item['id'] ?? 0);
            $quantity = max(1, absint($item['quantity'] ?? 1));

            if ($product_id <= 0) {
                continue;
            }

            $result = self::add_or_increment($product_id, $quantity);
            if (is_wp_error($result)) {
                $errors[] = [
                    'product_id' => $product_id,
                    'code' => $result->get_error_code(),
                    'message' => $result->get_error_message(),
                ];
            }
        }

        $response = self::cart_response();
        $data = $response->get_data();
        $data['merge_errors'] = $errors;
        $response->set_data($data);

        return $response;
    }

    private static function add_or_increment(int $product_id, int $quantity): true|WP_Error
    {
        global $wpdb;

        $current = (int) $wpdb->get_var($wpdb->prepare(
            'SELECT quantity FROM ' . self::table() . ' WHERE user_id = %d AND product_id = %d',
            get_current_user_id(),
            $product_id
        ));

        $next_quantity = $current + $quantity;
        $validation = self::validate_quantity($product_id, $next_quantity);
        if (is_wp_error($validation)) {
            return $validation;
        }

        self::upsert_quantity($product_id, $next_quantity);

        return true;
    }

    private static function upsert_quantity(int $product_id, int $quantity): void
    {
        global $wpdb;

        $now = TCG_Platform_API::now();

        $wpdb->query($wpdb->prepare(
            'INSERT INTO ' . self::table() . ' (user_id, product_id, quantity, created_at, updated_at)
            VALUES (%d, %d, %d, %s, %s)
            ON DUPLICATE KEY UPDATE quantity = VALUES(quantity), updated_at = VALUES(updated_at)',
            get_current_user_id(),
            $product_id,
            $quantity,
            $now,
            $now
        ));
    }

    private static function delete_item(int $product_id): void
    {
        global $wpdb;

        $wpdb->delete(
            self::table(),
            ['user_id' => get_current_user_id(), 'product_id' => $product_id],
            ['%d', '%d']
        );
    }

    private static function validate_quantity(int $product_id, int $quantity): true|WP_Error
    {
        $product = self::get_product($product_id);
        if (! $product instanceof WC_Product) {
            return self::error('tcg_cart_product_not_found', 'Product not found.', 404);
        }

        if (! $product->is_purchasable()) {
            return self::error('tcg_cart_product_unavailable', 'Product is not purchasable.', 422);
        }

        if (! $product->is_in_stock()) {
            return self::error('tcg_cart_product_out_of_stock', 'Product is out of stock.', 409);
        }

        if (! $product->backorders_allowed() && $product->managing_stock()) {
            $stock = $product->get_stock_quantity();
            if ($stock !== null && $quantity > (int) $stock) {
                return self::error('tcg_cart_not_enough_stock', 'Not enough stock for requested quantity.', 409);
            }
        }

        return true;
    }

    private static function cart_response(int $status = 200): WP_REST_Response
    {
        global $wpdb;

        $rows = $wpdb->get_results($wpdb->prepare(
            'SELECT product_id, quantity, created_at, updated_at FROM ' . self::table() . ' WHERE user_id = %d ORDER BY updated_at DESC',
            get_current_user_id()
        ));

        $items = array_values(array_filter(array_map([self::class, 'item_payload_from_row'], $rows ?: [])));

        return new WP_REST_Response([
            'data' => $items,
            'meta' => [
                'count' => count($items),
                'quantity' => array_sum(array_map(static fn (array $item): int => (int) $item['quantity'], $items)),
                'subtotal' => self::money_label(array_sum(array_map(static fn (array $item): float => (float) $item['line_subtotal_raw'], $items))),
                'subtotal_raw' => array_sum(array_map(static fn (array $item): float => (float) $item['line_subtotal_raw'], $items)),
                'has_issues' => count(array_filter($items, static fn (array $item): bool => ! (bool) $item['is_valid'])) > 0,
            ],
        ], $status);
    }

    private static function item_payload_from_row(object $row): ?array
    {
        $product = self::get_product((int) $row->product_id);
        if (! $product instanceof WC_Product) {
            return null;
        }

        return self::item_payload($product, (int) $row->quantity, (string) $row->created_at, (string) $row->updated_at);
    }

    private static function item_payload(WC_Product $product, int $quantity, string $created_at = '', string $updated_at = ''): array
    {
        $image_id = $product->get_image_id();
        $image = $image_id ? wp_get_attachment_image_url($image_id, 'woocommerce_thumbnail') : '';
        $price_raw = (float) $product->get_price();
        $stock_quantity = $product->managing_stock() ? $product->get_stock_quantity() : null;
        $max_quantity = $stock_quantity !== null && ! $product->backorders_allowed() ? max(0, (int) $stock_quantity) : null;
        $is_valid = $product->is_purchasable() && $product->is_in_stock() && ($max_quantity === null || $quantity <= $max_quantity);
        $notice = '';

        if (! $product->is_purchasable()) {
            $notice = 'Este producto ya no se puede comprar.';
        } elseif (! $product->is_in_stock()) {
            $notice = 'Este producto esta sin stock.';
        } elseif ($max_quantity !== null && $quantity > $max_quantity) {
            $notice = 'Solo quedan ' . $max_quantity . ' unidades disponibles.';
        } elseif ($stock_quantity !== null && $stock_quantity <= 3) {
            $notice = 'Quedan pocas unidades.';
        }

        return [
            'id' => $product->get_id(),
            'product_id' => $product->get_id(),
            'slug' => $product->get_slug(),
            'name' => $product->get_name(),
            'price' => self::money_label($price_raw),
            'price_raw' => $price_raw,
            'line_subtotal' => self::money_label($price_raw * $quantity),
            'line_subtotal_raw' => $price_raw * $quantity,
            'image' => $image ?: '',
            'quantity' => $quantity,
            'is_in_stock' => $product->is_in_stock(),
            'stock_quantity' => $stock_quantity,
            'stock_status' => $product->get_stock_status(),
            'max_quantity' => $max_quantity,
            'is_valid' => $is_valid,
            'notice' => $notice,
            'permalink' => $product->get_permalink(),
            'created_at' => $created_at,
            'updated_at' => $updated_at,
        ];
    }

    private static function item_args(): array
    {
        return [
            'product_id' => [
                'required' => true,
                'type' => 'integer',
                'minimum' => 1,
                'sanitize_callback' => 'absint',
            ],
            'quantity' => [
                'required' => false,
                'type' => 'integer',
                'minimum' => 1,
                'default' => 1,
                'sanitize_callback' => 'absint',
            ],
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

        return $wpdb->prefix . 'tcg_cart_items';
    }

    private static function money_label(float $amount): string
    {
        if (function_exists('wc_price')) {
            return html_entity_decode(wp_strip_all_tags(wc_price($amount)), ENT_QUOTES, get_bloginfo('charset'));
        }

        return number_format($amount, 2, '.', '');
    }
}
