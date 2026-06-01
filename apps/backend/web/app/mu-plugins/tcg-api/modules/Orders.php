<?php

declare(strict_types=1);

if (! defined('ABSPATH')) {
    exit;
}

final class TCG_Platform_API_Orders
{
    use TCG_API_ErrorTrait;
    public static function register_routes(string $namespace): void
    {
        register_rest_route($namespace, '/orders', [
            'methods' => WP_REST_Server::READABLE,
            'callback' => [self::class, 'user_orders'],
            'permission_callback' => ['TCG_Platform_API', 'require_auth'],
        ]);

        register_rest_route($namespace, '/orders/(?P<id>\d+)', [
            'methods' => WP_REST_Server::READABLE,
            'callback' => [self::class, 'user_order'],
            'permission_callback' => ['TCG_Platform_API', 'require_auth'],
        ]);

        register_rest_route($namespace, '/orders/(?P<id>\d+)/repeat', [
            'methods' => WP_REST_Server::CREATABLE,
            'callback' => [self::class, 'repeat_order'],
            'permission_callback' => ['TCG_Platform_API', 'require_auth'],
        ]);

        register_rest_route($namespace, '/admin/sales', [
            'methods' => WP_REST_Server::READABLE,
            'callback' => [self::class, 'sales'],
            'permission_callback' => ['TCG_Platform_API', 'require_auth'],
        ]);

        register_rest_route($namespace, '/admin/sales/orders', [
            'methods' => WP_REST_Server::READABLE,
            'callback' => [self::class, 'sales_orders'],
            'permission_callback' => ['TCG_Platform_API', 'require_auth'],
        ]);

        register_rest_route($namespace, '/admin/sales/orders/(?P<id>\d+)', [
            'methods' => WP_REST_Server::READABLE,
            'callback' => [self::class, 'sales_order'],
            'permission_callback' => ['TCG_Platform_API', 'require_auth'],
        ]);

        register_rest_route($namespace, '/admin/inventory', [
            'methods' => WP_REST_Server::READABLE,
            'callback' => [self::class, 'inventory'],
            'permission_callback' => ['TCG_Platform_API', 'require_auth'],
        ]);
    }

    public static function user_orders(): WP_REST_Response|WP_Error
    {
        if (! function_exists('wc_get_orders')) {
            return self::error('tcg_orders_woocommerce_missing', 'WooCommerce is not available.', 503);
        }

        $orders = wc_get_orders([
            'customer_id' => get_current_user_id(),
            'limit' => 20,
            'orderby' => 'date',
            'order' => 'DESC',
        ]);

        return new WP_REST_Response([
            'data' => array_values(array_map([self::class, 'order_summary_payload'], $orders)),
        ]);
    }

    public static function user_order(WP_REST_Request $request): WP_REST_Response|WP_Error
    {
        $order = self::get_user_order(absint($request['id']));
        if (is_wp_error($order)) {
            return $order;
        }

        return new WP_REST_Response([
            'data' => self::order_payload($order, true),
        ]);
    }

    public static function repeat_order(WP_REST_Request $request): WP_REST_Response|WP_Error
    {
        $order = self::get_user_order(absint($request['id']));
        if (is_wp_error($order)) {
            return $order;
        }

        global $wpdb;

        $errors = [];
        foreach ($order->get_items() as $item) {
            if (! $item instanceof WC_Order_Item_Product) {
                continue;
            }

            $product_id = (int) ($item->get_variation_id() ?: $item->get_product_id());
            $quantity = max(1, (int) $item->get_quantity());
            $product = wc_get_product($product_id);

            if (! $product instanceof WC_Product || $product->get_status() !== 'publish' || ! $product->is_purchasable() || ! $product->is_in_stock()) {
                $errors[] = ['product_id' => $product_id, 'name' => $item->get_name(), 'message' => 'Producto no disponible.'];
                continue;
            }

            if (! $product->backorders_allowed() && $product->managing_stock()) {
                $stock = $product->get_stock_quantity();
                if ($stock !== null && $quantity > (int) $stock) {
                    $errors[] = ['product_id' => $product_id, 'name' => $item->get_name(), 'message' => 'Stock insuficiente.'];
                    continue;
                }
            }

            $now = TCG_Platform_API::now();
            $current = (int) $wpdb->get_var($wpdb->prepare(
                'SELECT quantity FROM ' . self::cart_table() . ' WHERE user_id = %d AND product_id = %d',
                get_current_user_id(),
                $product_id
            ));
            $next_quantity = $current + $quantity;

            $wpdb->query($wpdb->prepare(
                'INSERT INTO ' . self::cart_table() . ' (user_id, product_id, quantity, created_at, updated_at)
                VALUES (%d, %d, %d, %s, %s)
                ON DUPLICATE KEY UPDATE quantity = VALUES(quantity), updated_at = VALUES(updated_at)',
                get_current_user_id(),
                $product_id,
                $next_quantity,
                $now,
                $now
            ));
        }

        return new WP_REST_Response([
            'message' => $errors ? 'Order partially repeated.' : 'Order repeated.',
            'errors' => $errors,
        ], $errors ? 207 : 201);
    }

    public static function sales(WP_REST_Request $request): WP_REST_Response|WP_Error
    {
        if (! self::can_access_sales()) {
            return self::error('tcg_sales_forbidden', 'Backoffice permissions are required.', 403);
        }

        if (! function_exists('wc_get_orders')) {
            return self::error('tcg_sales_woocommerce_missing', 'WooCommerce is not available.', 503);
        }

        $date_from = sanitize_text_field((string) $request->get_param('date_from'));
        $date_to = sanitize_text_field((string) $request->get_param('date_to'));
        $date_query = self::date_query($date_from, $date_to);

        $cache_key = 'tcg_sales_summary_' . md5($date_from . '|' . $date_to);
        $cached = get_transient($cache_key);
        if (is_array($cached)) {
            return new WP_REST_Response(['data' => $cached]);
        }

        $orders = wc_get_orders([
            'limit' => 500,
            'orderby' => 'date',
            'order' => 'DESC',
            'status' => array_keys(wc_get_order_statuses()),
            ...($date_query ? ['date_created' => $date_query] : []),
        ]);

        $total = 0.0;
        $pending = 0;
        $chart = self::empty_chart($date_from, $date_to);

        foreach ($orders as $order) {
            if (! $order instanceof WC_Order) {
                continue;
            }

            if (in_array($order->get_status(), ['pending', 'on-hold'], true)) {
                $pending++;
            }

            if (! in_array($order->get_status(), ['cancelled', 'failed', 'refunded'], true)) {
                $total += (float) $order->get_total();
            }

            $created = $order->get_date_created();
            if ($created) {
                $key = $created->date('Y-m-d');
                if (isset($chart[$key]) && ! in_array($order->get_status(), ['cancelled', 'failed', 'refunded'], true)) {
                    $chart[$key]['total'] += (float) $order->get_total();
                    $chart[$key]['orders']++;
                }
            }
        }

        $data = [
            'metrics' => [
                'orders' => count($orders),
                'revenue' => self::money($total),
                'pending' => $pending,
            ],
            'chart' => array_values($chart),
            'range' => [
                'from' => $date_from,
                'to' => $date_to,
            ],
        ];

        set_transient($cache_key, $data, 30);

        return new WP_REST_Response(['data' => $data]);
    }

    public static function sales_orders(WP_REST_Request $request): WP_REST_Response|WP_Error
    {
        if (! self::can_access_sales()) {
            return self::error('tcg_sales_forbidden', 'Backoffice permissions are required.', 403);
        }

        if (! function_exists('wc_get_orders')) {
            return self::error('tcg_sales_woocommerce_missing', 'WooCommerce is not available.', 503);
        }

        $page = max(1, absint($request->get_param('page') ?: 1));
        $per_page = min(30, max(5, absint($request->get_param('per_page') ?: 8)));
        $date_from = sanitize_text_field((string) $request->get_param('date_from'));
        $date_to = sanitize_text_field((string) $request->get_param('date_to'));
        $search = sanitize_text_field((string) $request->get_param('search'));
        $date_query = self::date_query($date_from, $date_to);

        $args = [
            'limit' => $per_page,
            'page' => $page,
            'paginate' => true,
            'orderby' => 'date',
            'order' => 'DESC',
            'status' => array_keys(wc_get_order_statuses()),
            ...($date_query ? ['date_created' => $date_query] : []),
        ];

        if ($search !== '') {
            $args['search'] = '*' . $search . '*';
            $args['search_columns'] = ['ID', 'billing_email', 'billing_first_name', 'billing_last_name'];
        }

        $result = wc_get_orders($args);
        $orders = is_object($result) && isset($result->orders) ? $result->orders : [];
        $total = is_object($result) && isset($result->total) ? (int) $result->total : count($orders);
        $total_pages = is_object($result) && isset($result->max_num_pages) ? (int) $result->max_num_pages : 1;

        return new WP_REST_Response([
            'data' => array_values(array_map([self::class, 'order_summary_payload'], $orders)),
            'meta' => [
                'page' => $page,
                'per_page' => $per_page,
                'total' => $total,
                'total_pages' => $total_pages,
            ],
        ]);
    }

    public static function sales_order(WP_REST_Request $request): WP_REST_Response|WP_Error
    {
        if (! self::can_access_sales()) {
            return self::error('tcg_sales_forbidden', 'Backoffice permissions are required.', 403);
        }

        if (! function_exists('wc_get_order')) {
            return self::error('tcg_sales_woocommerce_missing', 'WooCommerce is not available.', 503);
        }

        $order = wc_get_order(absint($request['id']));
        if (! $order instanceof WC_Order) {
            return self::error('tcg_sales_order_not_found', 'Order not found.', 404);
        }

        return new WP_REST_Response([
            'data' => self::order_payload($order, true),
        ]);
    }

    public static function inventory(WP_REST_Request $request): WP_REST_Response|WP_Error
    {
        if (! self::can_access_inventory()) {
            return self::error('tcg_inventory_forbidden', 'Backoffice permissions are required.', 403);
        }

        if (! function_exists('wc_get_products')) {
            return self::error('tcg_inventory_woocommerce_missing', 'WooCommerce is not available.', 503);
        }

        $page = max(1, absint($request->get_param('page') ?: 1));
        $per_page = min(50, max(5, absint($request->get_param('per_page') ?: 10)));
        $search = sanitize_text_field((string) $request->get_param('search'));
        $stock = sanitize_key((string) $request->get_param('stock'));
        $type = sanitize_key((string) $request->get_param('type'));
        $category = sanitize_text_field((string) $request->get_param('category'));

        $args = [
            'limit' => $per_page,
            'page' => $page,
            'paginate' => true,
            'orderby' => 'date',
            'order' => 'DESC',
            'status' => ['publish'],
            'return' => 'objects',
        ];

        if ($search !== '') {
            $args['s'] = $search;
        }

        if (in_array($stock, ['instock', 'outofstock', 'onbackorder'], true)) {
            $args['stock_status'] = $stock;
        }

        if ($type !== '') {
            $args['type'] = $type;
        }

        if ($category !== '') {
            $args['category'] = [$category];
        }

        $result = wc_get_products($args);
        $products = is_object($result) && isset($result->products) ? $result->products : [];
        $total = is_object($result) && isset($result->total) ? (int) $result->total : count($products);
        $total_pages = is_object($result) && isset($result->max_num_pages) ? (int) $result->max_num_pages : 1;

        $alerts = self::inventory_alerts();

        return new WP_REST_Response([
            'data' => array_values(array_map([self::class, 'product_payload'], $products)),
            'meta' => [
                'page' => $page,
                'per_page' => $per_page,
                'total' => $total,
                'total_pages' => $total_pages,
            ],
            'alerts' => $alerts,
        ]);
    }

    private static function order_payload(WC_Order $order, bool $detailed = false): array
    {
        $status = $order->get_status();
        $payload = [
            'id' => $order->get_id(),
            'number' => $order->get_order_number(),
            'status' => $status,
            'status_label' => wc_get_order_status_name($status),
            'status_help' => self::status_help($status),
            'status_tone' => self::status_tone($status),
            'created_at' => $order->get_date_created()?->date(DATE_ATOM),
            'total' => html_entity_decode(wp_strip_all_tags($order->get_formatted_order_total()), ENT_QUOTES, get_bloginfo('charset')),
            'subtotal' => self::money((float) $order->get_subtotal()),
            'shipping_total' => self::money((float) $order->get_shipping_total()),
            'discount_total' => self::money((float) $order->get_discount_total()),
            'item_count' => $order->get_item_count(),
            'payment_method_title' => $order->get_payment_method_title(),
            'delivery_method' => (string) $order->get_meta('_tcg_delivery_method'),
            'delivery_method_label' => self::delivery_label((string) $order->get_meta('_tcg_delivery_method')),
            'customer_note' => $order->get_customer_note(),
            'can_repeat' => ! in_array($status, ['cancelled', 'failed', 'refunded'], true),
            'receipt_available' => false,
            'support_available' => true,
            'cancellation_available' => in_array($status, ['pending', 'on-hold'], true),
            'edit_url' => admin_url('admin.php?page=wc-orders&action=edit&id=' . $order->get_id()),
            'billing' => [
                'name' => trim($order->get_billing_first_name() . ' ' . $order->get_billing_last_name()),
                'email' => $order->get_billing_email(),
                'phone' => $order->get_billing_phone(),
                'address' => self::address_label($order, 'billing'),
            ],
            'shipping' => [
                'name' => trim($order->get_shipping_first_name() . ' ' . $order->get_shipping_last_name()),
                'address' => self::address_label($order, 'shipping'),
            ],
            'items' => array_values(array_map(static function (WC_Order_Item_Product $item): array {
                return [
                    'product_id' => $item->get_product_id(),
                    'variation_id' => $item->get_variation_id(),
                    'name' => $item->get_name(),
                    'quantity' => $item->get_quantity(),
                    'subtotal' => self::money((float) $item->get_subtotal()),
                    'total' => self::money((float) $item->get_total()),
                ];
            }, $order->get_items())),
        ];

        if ($detailed) {
            $payload['timeline'] = self::timeline($order);
            $payload['receipt_note'] = 'La descarga de recibo/factura queda preparada para una integracion fiscal posterior.';
            $payload['support_note'] = 'Las solicitudes se gestionaran fuera de WordPress hasta definir el flujo de soporte.';
        }

        return $payload;
    }

    private static function order_summary_payload(WC_Order $order): array
    {
        $status = $order->get_status();

        return [
            'id' => $order->get_id(),
            'number' => $order->get_order_number(),
            'status' => $status,
            'status_label' => wc_get_order_status_name($status),
            'created_at' => $order->get_date_created()?->date(DATE_ATOM),
            'total' => html_entity_decode(wp_strip_all_tags($order->get_formatted_order_total()), ENT_QUOTES, get_bloginfo('charset')),
            'item_count' => $order->get_item_count(),
            'payment_method_title' => $order->get_payment_method_title(),
            'edit_url' => admin_url('admin.php?page=wc-orders&action=edit&id=' . $order->get_id()),
            'billing' => [
                'name' => trim($order->get_billing_first_name() . ' ' . $order->get_billing_last_name()),
                'email' => $order->get_billing_email(),
            ],
        ];
    }

    private static function get_user_order(int $order_id): WC_Order|WP_Error
    {
        if (! function_exists('wc_get_order')) {
            return self::error('tcg_orders_woocommerce_missing', 'WooCommerce is not available.', 503);
        }

        $order = wc_get_order($order_id);
        if (! $order instanceof WC_Order || (int) $order->get_customer_id() !== get_current_user_id()) {
            return self::error('tcg_order_not_found', 'Order not found.', 404);
        }

        return $order;
    }

    private static function address_label(WC_Order $order, string $type): string
    {
        $values = $type === 'shipping'
            ? [$order->get_shipping_address_1(), $order->get_shipping_address_2(), $order->get_shipping_postcode(), $order->get_shipping_city(), $order->get_shipping_state(), $order->get_shipping_country()]
            : [$order->get_billing_address_1(), $order->get_billing_address_2(), $order->get_billing_postcode(), $order->get_billing_city(), $order->get_billing_state(), $order->get_billing_country()];

        return trim(implode(' ', array_filter(array_map('trim', $values))));
    }

    private static function delivery_label(string $method): string
    {
        return $method === 'local_pickup' ? 'Recogida local' : 'Entrega local';
    }

    private static function status_help(string $status): string
    {
        return match ($status) {
            'pending' => 'El pedido esta pendiente de pago o confirmacion.',
            'on-hold' => 'Pedido recibido y en espera de revision local.',
            'processing' => 'Pedido confirmado y en preparacion.',
            'completed' => 'Pedido completado.',
            'cancelled' => 'Pedido cancelado.',
            'refunded' => 'Pedido reembolsado.',
            'failed' => 'El pedido fallo y no se procesara.',
            default => 'Estado sincronizado desde WooCommerce.',
        };
    }

    private static function status_tone(string $status): string
    {
        return match ($status) {
            'completed' => 'success',
            'processing' => 'info',
            'pending', 'on-hold' => 'warning',
            'cancelled', 'refunded', 'failed' => 'danger',
            default => 'neutral',
        };
    }

    private static function timeline(WC_Order $order): array
    {
        return [
            ['label' => 'Pedido creado', 'date' => $order->get_date_created()?->date(DATE_ATOM), 'active' => true],
            ['label' => 'En preparacion', 'date' => $order->get_date_paid()?->date(DATE_ATOM), 'active' => in_array($order->get_status(), ['processing', 'completed'], true)],
            ['label' => 'Completado', 'date' => $order->get_date_completed()?->date(DATE_ATOM), 'active' => $order->get_status() === 'completed'],
        ];
    }

    private static function empty_chart(string $date_from = '', string $date_to = ''): array
    {
        $chart = [];

        $end = $date_to !== '' ? strtotime($date_to) : time();
        $start = $date_from !== '' ? strtotime($date_from) : strtotime('-29 days', $end ?: time());

        if (! $start || ! $end || $start > $end) {
            $end = time();
            $start = strtotime('-29 days', $end);
        }

        $days = min(60, max(1, (int) floor(($end - $start) / DAY_IN_SECONDS) + 1));

        for ($index = 0; $index < $days; $index++) {
            $time = strtotime("+{$index} days", $start);
            $key = gmdate('Y-m-d', $time);
            $chart[$key] = [
                'date' => $key,
                'label' => gmdate('d/m', $time),
                'total' => 0.0,
                'orders' => 0,
            ];
        }

        return $chart;
    }

    private static function date_query(string $date_from, string $date_to): string
    {
        if ($date_from === '' && $date_to === '') {
            return '';
        }

        $from = $date_from !== '' ? $date_from . ' 00:00:00' : '1970-01-01 00:00:00';
        $to = $date_to !== '' ? $date_to . ' 23:59:59' : gmdate('Y-m-d 23:59:59');

        return $from . '...' . $to;
    }

    private static function product_payload(WC_Product $product): array
    {
        $image_id = $product->get_image_id();
        $stock_quantity = $product->managing_stock() ? $product->get_stock_quantity() : null;
        $variation_stock = null;

        if ($product instanceof WC_Product_Variable) {
            $variation_stock = self::cached_variation_stock_summary($product);
            $stock_quantity = $variation_stock['total_managed_stock'];
        }

        $low_stock_amount = (int) get_post_meta($product->get_id(), '_low_stock_amount', true);
        $low_stock_amount = $low_stock_amount > 0 ? $low_stock_amount : 3;
        $is_low = $stock_quantity !== null && $stock_quantity > 0 && (int) $stock_quantity <= $low_stock_amount;

        return [
            'id' => $product->get_id(),
            'name' => $product->get_name(),
            'slug' => $product->get_slug(),
            'type' => $product->get_type(),
            'sku' => $product->get_sku(),
            'price' => self::money((float) $product->get_price()),
            'stock_status' => $product->get_stock_status(),
            'is_in_stock' => $product->is_in_stock(),
            'stock_quantity' => $stock_quantity,
            'variation_stock' => $variation_stock,
            'low_stock' => $is_low,
            'image' => $image_id ? wp_get_attachment_image_url($image_id, 'woocommerce_thumbnail') : '',
            'edit_url' => admin_url('post.php?post=' . $product->get_id() . '&action=edit'),
            'permalink' => get_permalink($product->get_id()),
        ];
    }

    private static function variation_stock_summary(WC_Product_Variable $product): array
    {
        $total = 0;
        $managed = 0;
        $available = 0;
        $out = 0;

        foreach ($product->get_children() as $variation_id) {
            $variation = wc_get_product((int) $variation_id);
            if (! $variation instanceof WC_Product) {
                continue;
            }

            if ($variation->is_in_stock()) {
                $available++;
            } else {
                $out++;
            }

            if ($variation->managing_stock()) {
                $stock = $variation->get_stock_quantity();
                if ($stock !== null) {
                    $managed++;
                    $total += max(0, (int) $stock);
                }
            }
        }

        return [
            'total_managed_stock' => $managed > 0 ? $total : null,
            'available_variations' => $available,
            'out_of_stock_variations' => $out,
        ];
    }

    private static function cached_variation_stock_summary(WC_Product_Variable $product): array
    {
        $cache_key = 'tcg_variation_stock_' . $product->get_id();
        $cached = get_transient($cache_key);
        if (is_array($cached)) {
            return $cached;
        }

        $summary = self::variation_stock_summary($product);
        set_transient($cache_key, $summary, 120);

        return $summary;
    }

    private static function inventory_alerts(): array
    {
        $cached = get_transient('tcg_inventory_alerts');
        if (is_array($cached)) {
            return $cached;
        }

        $low = [];
        $empty = [];

        $products = wc_get_products([
            'limit' => 100,
            'status' => ['publish'],
            'return' => 'objects',
        ]);

        foreach ($products as $product) {
            if (! $product instanceof WC_Product) {
                continue;
            }

            $stock_quantity = $product->managing_stock() ? $product->get_stock_quantity() : null;

            if (! $product->is_in_stock()) {
                $empty[] = self::product_payload($product);
                continue;
            }

            if ($stock_quantity !== null && (int) $stock_quantity <= 3) {
                $low[] = self::product_payload($product);
            }
        }

        $alerts = [
            'low_stock' => array_slice($low, 0, 8),
            'out_of_stock' => array_slice($empty, 0, 8),
        ];

        set_transient('tcg_inventory_alerts', $alerts, 60);

        return $alerts;
    }

    private static function can_access_sales(): bool
    {
        return current_user_can('manage_options')
            || current_user_can('manage_woocommerce')
            || current_user_can('edit_shop_orders');
    }

    private static function can_access_inventory(): bool
    {
        return current_user_can('manage_options')
            || current_user_can('manage_woocommerce')
            || current_user_can('edit_products');
    }

    private static function money(float $amount): string
    {
        return html_entity_decode(wp_strip_all_tags(wc_price($amount)), ENT_QUOTES, get_bloginfo('charset'));
    }

    private static function cart_table(): string
    {
        global $wpdb;

        return $wpdb->prefix . 'tcg_cart_items';
    }

}
