<?php

declare(strict_types=1);

if (! defined('ABSPATH')) {
    exit;
}

final class TCG_Platform_API_Checkout
{
    public static function register_routes(string $namespace): void
    {
        register_rest_route($namespace, '/checkout', [
            'methods' => WP_REST_Server::CREATABLE,
            'callback' => [self::class, 'create_order'],
            'permission_callback' => ['TCG_Platform_API', 'require_auth'],
        ]);
    }

    public static function create_order(WP_REST_Request $request): WP_REST_Response|WP_Error
    {
        if (! function_exists('wc_create_order')) {
            return self::error('tcg_checkout_woocommerce_missing', 'WooCommerce is not available.', 503);
        }

        $items = self::cart_items();
        if ($items === []) {
            return self::error('tcg_checkout_empty_cart', 'Cart is empty.', 422);
        }

        $validation = self::validate_items($items);
        if (is_wp_error($validation)) {
            return $validation;
        }

        $billing = self::billing_from_request($request);
        $order = wc_create_order(['customer_id' => get_current_user_id()]);

        if (! $order instanceof WC_Order) {
            return self::error('tcg_checkout_order_failed', 'Order could not be created.', 500);
        }

        foreach ($items as $item) {
            $product = wc_get_product((int) $item->product_id);
            if ($product instanceof WC_Product) {
                $order->add_product($product, (int) $item->quantity);
            }
        }

        $order->set_address($billing, 'billing');
        $order->set_address($billing, 'shipping');
        $order->set_payment_method('tcg_local_test');
        $order->set_payment_method_title('Local test checkout');
        $order->set_created_via('tcg-platform-api');
        $order->add_order_note('Pedido creado desde checkout local de pruebas TCG Platform.');
        $order->calculate_totals();
        $order->update_status('on-hold', 'Pedido local de pruebas creado sin pasarela externa.', true);
        $order->save();

        if (function_exists('wc_reduce_stock_levels')) {
            wc_reduce_stock_levels($order->get_id());
        }

        self::clear_cart();

        return new WP_REST_Response([
            'data' => self::order_payload($order),
        ], 201);
    }

    private static function cart_items(): array
    {
        global $wpdb;

        return $wpdb->get_results($wpdb->prepare(
            'SELECT product_id, quantity FROM ' . self::cart_table() . ' WHERE user_id = %d ORDER BY updated_at DESC',
            get_current_user_id()
        )) ?: [];
    }

    private static function validate_items(array $items): true|WP_Error
    {
        foreach ($items as $item) {
            $product = function_exists('wc_get_product') ? wc_get_product((int) $item->product_id) : null;
            $quantity = (int) $item->quantity;

            if (! $product instanceof WC_Product || $product->get_status() !== 'publish') {
                return self::error('tcg_checkout_product_not_found', 'A product in the cart is no longer available.', 409);
            }

            if (! $product->is_purchasable()) {
                return self::error('tcg_checkout_product_unavailable', 'A product in the cart is not purchasable.', 409);
            }

            if (! $product->is_in_stock()) {
                return self::error('tcg_checkout_product_out_of_stock', 'A product in the cart is out of stock.', 409);
            }

            if (! $product->backorders_allowed() && $product->managing_stock()) {
                $stock = $product->get_stock_quantity();
                if ($stock !== null && $quantity > (int) $stock) {
                    return self::error('tcg_checkout_not_enough_stock', 'Not enough stock for one or more products.', 409);
                }
            }
        }

        return true;
    }

    private static function billing_from_request(WP_REST_Request $request): array
    {
        $first_name = sanitize_text_field((string) $request->get_param('first_name'));
        $last_name = sanitize_text_field((string) $request->get_param('last_name'));
        $full_name = trim(sanitize_text_field((string) $request->get_param('name')));

        if ($first_name === '' && $full_name !== '') {
            $parts = preg_split('/\s+/', $full_name);
            $first_name = (string) array_shift($parts);
            $last_name = trim(implode(' ', $parts));
        }

        $user = wp_get_current_user();
        $email = sanitize_email((string) $request->get_param('email')) ?: $user->user_email;

        return [
            'first_name' => $first_name,
            'last_name' => $last_name,
            'email' => $email,
            'address_1' => sanitize_text_field((string) $request->get_param('address')),
            'postcode' => sanitize_text_field((string) $request->get_param('postal_code')),
            'city' => sanitize_text_field((string) $request->get_param('city')),
            'country' => sanitize_text_field((string) ($request->get_param('country') ?: 'ES')),
        ];
    }

    private static function clear_cart(): void
    {
        global $wpdb;

        $wpdb->delete(self::cart_table(), ['user_id' => get_current_user_id()], ['%d']);
    }

    private static function order_payload(WC_Order $order): array
    {
        return [
            'id' => $order->get_id(),
            'number' => $order->get_order_number(),
            'status' => $order->get_status(),
            'created_at' => $order->get_date_created()?->date(DATE_ATOM),
            'total' => html_entity_decode(wp_strip_all_tags($order->get_formatted_order_total()), ENT_QUOTES, get_bloginfo('charset')),
            'currency' => $order->get_currency(),
            'payment_method' => $order->get_payment_method(),
            'payment_method_title' => $order->get_payment_method_title(),
            'items' => array_values(array_map(static function (WC_Order_Item_Product $item): array {
                return [
                    'product_id' => $item->get_product_id(),
                    'name' => $item->get_name(),
                    'quantity' => $item->get_quantity(),
                    'subtotal' => html_entity_decode(wp_strip_all_tags(wc_price((float) $item->get_subtotal())), ENT_QUOTES, get_bloginfo('charset')),
                    'total' => html_entity_decode(wp_strip_all_tags(wc_price((float) $item->get_total())), ENT_QUOTES, get_bloginfo('charset')),
                ];
            }, $order->get_items())),
        ];
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
