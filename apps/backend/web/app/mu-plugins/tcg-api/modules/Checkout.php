<?php

declare(strict_types=1);

if (! defined('ABSPATH')) {
    exit;
}

final class TCG_Platform_API_Checkout
{
    use TCG_API_ErrorTrait;
    public static function register_routes(string $namespace): void
    {
        register_rest_route($namespace, '/checkout', [
            'methods'             => WP_REST_Server::CREATABLE,
            'callback'            => [self::class, 'create_order'],
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

        $user_id          = get_current_user_id();
        $billing          = self::billing_from_request($request);
        $shipping_method  = sanitize_text_field((string) $request->get_param('shipping_method'));
        $coupon_code      = strtolower(sanitize_text_field((string) $request->get_param('coupon_code')));
        $customer_note    = sanitize_textarea_field((string) $request->get_param('notes'));

        if ($coupon_code === '' && class_exists('TCG_Platform_API_Coupons')) {
            $coupon_code = TCG_Platform_API_Coupons::get_persisted_coupon($user_id);
        }

        if ($shipping_method === '') {
            $shipping_method = 'local_delivery';
        }

        $order = wc_create_order(['customer_id' => $user_id]);
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
        $order->set_customer_note($customer_note);
        $order->set_payment_method('tcg_local_test');
        $order->set_payment_method_title('Local test checkout');
        $order->set_created_via('tcg-platform-api');

        self::add_shipping_line($order, $shipping_method, $billing);

        if ($coupon_code !== '') {
            $coupon_result = $order->apply_coupon($coupon_code);
            if (is_wp_error($coupon_result)) {
                $coupon_code = '';
            }
        }

        $order->update_meta_data('_tcg_delivery_method', $shipping_method);
        $order->add_order_note('Pedido creado desde checkout local de pruebas TCG Platform.');
        if ($customer_note !== '') {
            $order->add_order_note('Nota del cliente: ' . $customer_note);
        }

        $order->calculate_totals();
        $order->update_status('on-hold', 'Pedido local de pruebas creado sin pasarela externa.', true);
        $order->save();

        if (function_exists('wc_reduce_stock_levels')) {
            wc_reduce_stock_levels($order->get_id());
        }

        self::clear_cart();
        self::persist_customer_checkout_data($user_id, $billing, $shipping_method);

        if (class_exists('TCG_Platform_API_Coupons')) {
            TCG_Platform_API_Coupons::clear_persisted_coupon($user_id);
        }

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
            $product  = function_exists('wc_get_product') ? wc_get_product((int) $item->product_id) : null;
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
        $last_name  = sanitize_text_field((string) $request->get_param('last_name'));
        $full_name  = trim(sanitize_text_field((string) $request->get_param('name')));

        if ($first_name === '' && $full_name !== '') {
            $parts      = preg_split('/\s+/', $full_name);
            $first_name = (string) array_shift($parts);
            $last_name  = trim(implode(' ', $parts));
        }

        $user  = wp_get_current_user();
        $email = sanitize_email((string) $request->get_param('email')) ?: $user->user_email;

        return [
            'first_name' => $first_name,
            'last_name'  => $last_name,
            'email'      => $email,
            'address_1'  => sanitize_text_field((string) $request->get_param('address')),
            'address_2'  => sanitize_text_field((string) $request->get_param('address_2')),
            'postcode'   => sanitize_text_field((string) $request->get_param('postal_code')),
            'city'       => sanitize_text_field((string) $request->get_param('city')),
            'state'      => sanitize_text_field((string) $request->get_param('state')),
            'country'    => sanitize_text_field((string) ($request->get_param('country') ?: 'ES')),
            'phone'      => sanitize_text_field((string) $request->get_param('phone')),
        ];
    }

    private static function add_shipping_line(WC_Order $order, string $shipping_method, array $billing): void
    {
        $methods     = class_exists('TCG_Platform_API_Coupons') ? TCG_Platform_API_Coupons::available_shipping_methods() : [];
        $method_data = null;

        foreach ($methods as $m) {
            if ((string) $m['id'] === $shipping_method) {
                $method_data = $m;
                break;
            }
        }

        $is_local_method = in_array($shipping_method, ['local_delivery', 'local_pickup'], true);

        $shipping = new WC_Order_Item_Shipping();

        if ($method_data !== null && ! $is_local_method) {
            $shipping->set_method_id($shipping_method);
            $shipping->set_method_title((string) $method_data['label']);
            $shipping->set_total((float) $method_data['cost_raw']);
        } else {
            $title = $shipping_method === 'local_pickup' ? 'Recogida local' : 'Entrega local de pruebas';
            $shipping->set_method_id($shipping_method);
            $shipping->set_method_title($title);
            $shipping->set_total(0);
        }

        $order->add_item($shipping);
    }

    private static function persist_customer_checkout_data(int $user_id, array $billing, string $shipping_method): void
    {
        foreach ($billing as $key => $value) {
            update_user_meta($user_id, 'billing_' . $key, $value);
            update_user_meta($user_id, 'shipping_' . $key, $value);
        }

        update_user_meta($user_id, 'tcg_delivery_method', $shipping_method);
    }

    private static function clear_cart(): void
    {
        global $wpdb;

        $wpdb->delete(self::cart_table(), ['user_id' => get_current_user_id()], ['%d']);
    }

    private static function order_payload(WC_Order $order): array
    {
        $coupon_codes = $order->get_coupon_codes();
        $discount_raw = (float) $order->get_discount_total();
        $shipping_raw = (float) $order->get_shipping_total();
        $tax_raw      = (float) $order->get_total_tax();
        $subtotal_raw = (float) $order->get_subtotal();
        $total_raw    = (float) $order->get_total();

        return [
            'id'                   => $order->get_id(),
            'number'               => $order->get_order_number(),
            'status'               => $order->get_status(),
            'created_at'           => $order->get_date_created()?->date(DATE_ATOM),
            'currency'             => $order->get_currency(),
            'payment_method'       => $order->get_payment_method(),
            'payment_method_title' => $order->get_payment_method_title(),
            'delivery_method'      => (string) $order->get_meta('_tcg_delivery_method'),
            'customer_note'        => $order->get_customer_note(),
            'coupon_codes'         => $coupon_codes,
            'subtotal_raw'         => $subtotal_raw,
            'subtotal'             => self::money($subtotal_raw),
            'discount_raw'         => $discount_raw,
            'discount'             => $discount_raw > 0.0 ? '-' . self::money($discount_raw) : '',
            'shipping_raw'         => $shipping_raw,
            'shipping'             => self::money($shipping_raw),
            'tax_raw'              => $tax_raw,
            'tax'                  => $tax_raw > 0.0 ? self::money($tax_raw) : '',
            'total_raw'            => $total_raw,
            'total'                => self::money($total_raw),
            'items'                => array_values(array_map(static function (WC_Order_Item_Product $item): array {
                return [
                    'product_id' => $item->get_product_id(),
                    'name'       => $item->get_name(),
                    'quantity'   => $item->get_quantity(),
                    'subtotal'   => self::money((float) $item->get_subtotal()),
                    'total'      => self::money((float) $item->get_total()),
                ];
            }, $order->get_items())),
        ];
    }

    private static function cart_table(): string
    {
        global $wpdb;

        return $wpdb->prefix . 'tcg_cart_items';
    }

    private static function money(float $amount): string
    {
        if (function_exists('wc_price')) {
            return html_entity_decode(wp_strip_all_tags(wc_price($amount)), ENT_QUOTES, get_bloginfo('charset'));
        }

        return number_format($amount, 2, ',', '.') . ' €';
    }

}
