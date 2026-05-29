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

    private static function order_payload(WC_Order $order): array
    {
        return [
            'id' => $order->get_id(),
            'number' => $order->get_order_number(),
            'status' => $order->get_status(),
            'status_label' => wc_get_order_status_name($order->get_status()),
            'created_at' => $order->get_date_created()?->date(DATE_ATOM),
            'total' => html_entity_decode(wp_strip_all_tags($order->get_formatted_order_total()), ENT_QUOTES, get_bloginfo('charset')),
            'item_count' => $order->get_item_count(),
            'payment_method_title' => $order->get_payment_method_title(),
            'billing' => [
                'name' => trim($order->get_billing_first_name() . ' ' . $order->get_billing_last_name()),
                'email' => $order->get_billing_email(),
                'address' => trim($order->get_billing_address_1() . ' ' . $order->get_billing_postcode() . ' ' . $order->get_billing_city()),
            ],
            'items' => array_values(array_map(static function (WC_Order_Item_Product $item): array {
                return [
                    'product_id' => $item->get_product_id(),
                    'name' => $item->get_name(),
                    'quantity' => $item->get_quantity(),
                    'total' => self::money((float) $item->get_total()),
                ];
            }, $order->get_items())),
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

    private static function error(string $code, string $message, int $status): WP_Error
    {
        return new WP_Error($code, $message, ['status' => $status]);
    }
}
