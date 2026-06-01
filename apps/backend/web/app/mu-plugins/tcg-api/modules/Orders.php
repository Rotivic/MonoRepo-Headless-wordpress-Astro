<?php

declare(strict_types=1);

if (! defined('ABSPATH')) {
    exit;
}

final class TCG_Platform_API_Orders
{
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
            'data' => array_values(array_map([self::class, 'order_payload'], $orders)),
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

    public static function sales(): WP_REST_Response|WP_Error
    {
        if (! self::can_access_sales()) {
            return self::error('tcg_sales_forbidden', 'Backoffice permissions are required.', 403);
        }

        if (! function_exists('wc_get_orders')) {
            return self::error('tcg_sales_woocommerce_missing', 'WooCommerce is not available.', 503);
        }

        $orders = wc_get_orders([
            'limit' => 250,
            'orderby' => 'date',
            'order' => 'DESC',
            'status' => array_keys(wc_get_order_statuses()),
        ]);

        $total = 0.0;
        $pending = 0;
        $chart = self::empty_chart();

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

        return new WP_REST_Response([
            'data' => [
                'metrics' => [
                    'orders' => count($orders),
                    'revenue' => self::money($total),
                    'pending' => $pending,
                ],
                'chart' => array_values($chart),
                'orders' => array_values(array_map([self::class, 'order_payload'], $orders)),
            ],
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

    private static function empty_chart(): array
    {
        $chart = [];
        for ($index = 29; $index >= 0; $index--) {
            $time = strtotime("-{$index} days");
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

    private static function can_access_sales(): bool
    {
        return current_user_can('manage_options')
            || current_user_can('manage_woocommerce')
            || current_user_can('edit_shop_orders');
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

    private static function error(string $code, string $message, int $status): WP_Error
    {
        return new WP_Error($code, $message, ['status' => $status]);
    }
}
