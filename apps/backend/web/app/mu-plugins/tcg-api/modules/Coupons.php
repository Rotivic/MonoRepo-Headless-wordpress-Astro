<?php

declare(strict_types=1);

if (! defined('ABSPATH')) {
    exit;
}

final class TCG_Platform_API_Coupons
{
    private const COUPON_META = 'tcg_applied_coupon';

    public static function register_routes(string $namespace): void
    {
        register_rest_route($namespace, '/cart/totals', [
            'methods'             => WP_REST_Server::READABLE,
            'callback'            => [self::class, 'totals'],
            'permission_callback' => ['TCG_Platform_API', 'require_auth'],
        ]);

        register_rest_route($namespace, '/cart/coupon', [
            [
                'methods'             => WP_REST_Server::CREATABLE,
                'callback'            => [self::class, 'apply_coupon'],
                'permission_callback' => ['TCG_Platform_API', 'require_auth'],
                'args'                => [
                    'code' => [
                        'required'          => true,
                        'type'              => 'string',
                        'sanitize_callback' => 'sanitize_text_field',
                    ],
                ],
            ],
            [
                'methods'             => WP_REST_Server::DELETABLE,
                'callback'            => [self::class, 'remove_coupon'],
                'permission_callback' => ['TCG_Platform_API', 'require_auth'],
            ],
        ]);
    }

    public static function totals(WP_REST_Request $request): WP_REST_Response|WP_Error
    {
        if (! function_exists('wc_get_product')) {
            return self::error('tcg_totals_woocommerce_missing', 'WooCommerce is not available.', 503);
        }

        $user_id         = get_current_user_id();
        $coupon_param    = sanitize_text_field((string) $request->get_param('coupon_code'));
        $coupon_code     = $coupon_param !== '' ? strtolower($coupon_param) : strtolower((string) get_user_meta($user_id, self::COUPON_META, true));
        $shipping_method = sanitize_key((string) ($request->get_param('shipping_method') ?: 'local_delivery'));

        $items    = self::cart_items($user_id);
        $subtotal = array_sum(array_map(static fn (array $item): float => $item['price_raw'] * $item['quantity'], $items));

        $coupon_label = '';
        $discount_raw = 0.0;
        $coupon_error = '';
        $applied_code = '';

        if ($coupon_code !== '') {
            $result = self::calculate_discount($coupon_code, $subtotal, $user_id);
            if (isset($result['error'])) {
                $coupon_error = $result['error'];
            } else {
                $discount_raw = (float) $result['discount'];
                $coupon_label = 'Cupon ' . strtoupper($coupon_code);
                $applied_code = $coupon_code;
            }
        }

        $shipping_methods = self::available_shipping_methods();
        $selected_method  = self::find_method($shipping_methods, $shipping_method);
        $shipping_raw     = $selected_method ? (float) $selected_method['cost_raw'] : 0.0;
        $shipping_label   = $selected_method ? (string) $selected_method['label'] : 'Entrega local de pruebas';

        $tax_raw   = 0.0;
        $tax_label = '';
        if (function_exists('wc_tax_enabled') && wc_tax_enabled()) {
            $taxable   = max(0.0, $subtotal - $discount_raw) + $shipping_raw;
            $tax_rates = WC_Tax::get_rates();
            if (! empty($tax_rates)) {
                $taxes     = WC_Tax::calc_tax($taxable, $tax_rates, wc_prices_include_tax());
                $tax_raw   = (float) array_sum($taxes);
                $labels    = array_unique(array_column($tax_rates, 'label'));
                $tax_label = implode(', ', array_filter($labels));
            }
        }

        $total_raw = max(0.0, $subtotal - $discount_raw) + $shipping_raw + $tax_raw;

        return new WP_REST_Response([
            'data' => [
                'subtotal_raw'     => $subtotal,
                'subtotal'         => self::money($subtotal),
                'coupon_code'      => $applied_code,
                'coupon_label'     => $coupon_label,
                'coupon_error'     => $coupon_error,
                'discount_raw'     => $discount_raw,
                'discount'         => $discount_raw > 0.0 ? '-' . self::money($discount_raw) : '',
                'shipping_method'  => $selected_method['id'] ?? $shipping_method,
                'shipping_label'   => $shipping_label,
                'shipping_raw'     => $shipping_raw,
                'shipping'         => self::money($shipping_raw),
                'shipping_methods' => $shipping_methods,
                'tax_raw'          => $tax_raw,
                'tax'              => $tax_raw > 0.0 ? self::money($tax_raw) : '',
                'tax_label'        => $tax_label,
                'total_raw'        => $total_raw,
                'total'            => self::money($total_raw),
            ],
        ]);
    }

    public static function apply_coupon(WP_REST_Request $request): WP_REST_Response|WP_Error
    {
        if (! class_exists('WC_Coupon')) {
            return self::error('tcg_coupon_woocommerce_missing', 'WooCommerce is not available.', 503);
        }

        $code    = strtolower(sanitize_text_field((string) $request->get_param('code')));
        $user_id = get_current_user_id();

        $validation = self::validate_coupon($code, $user_id);
        if (isset($validation['error'])) {
            return self::error('tcg_coupon_invalid', $validation['error'], 422);
        }

        update_user_meta($user_id, self::COUPON_META, $code);

        $fake = new WP_REST_Request('GET');
        $fake->set_param('coupon_code', $code);

        return self::totals($fake);
    }

    public static function remove_coupon(): WP_REST_Response|WP_Error
    {
        $user_id = get_current_user_id();
        delete_user_meta($user_id, self::COUPON_META);

        return self::totals(new WP_REST_Request('GET'));
    }

    public static function get_persisted_coupon(int $user_id): string
    {
        return strtolower((string) get_user_meta($user_id, self::COUPON_META, true));
    }

    public static function clear_persisted_coupon(int $user_id): void
    {
        delete_user_meta($user_id, self::COUPON_META);
    }

    public static function available_shipping_methods(): array
    {
        if (! class_exists('WC_Shipping_Zones')) {
            return self::local_fallback_methods();
        }

        $methods    = [];
        $zones_data = array_merge([['zone_id' => 0]], WC_Shipping_Zones::get_zones());

        foreach ($zones_data as $zone_data) {
            $zone_id = isset($zone_data['zone_id']) ? (int) $zone_data['zone_id'] : 0;
            $zone    = new WC_Shipping_Zone($zone_id);

            foreach ($zone->get_shipping_methods(true) as $method) {
                if (! $method->is_enabled()) {
                    continue;
                }

                $cost = 0.0;
                if (method_exists($method, 'get_instance_option')) {
                    $raw  = $method->get_instance_option('cost');
                    $cost = is_numeric($raw) ? (float) $raw : 0.0;
                }

                $methods[] = [
                    'id'       => $method->get_rate_id(),
                    'label'    => $method->get_method_title(),
                    'cost_raw' => $cost,
                    'cost'     => self::money($cost),
                ];
            }
        }

        return $methods !== [] ? $methods : self::local_fallback_methods();
    }

    private static function local_fallback_methods(): array
    {
        return [
            [
                'id'       => 'local_delivery',
                'label'    => 'Entrega local de pruebas',
                'cost_raw' => 0.0,
                'cost'     => self::money(0.0),
            ],
            [
                'id'       => 'local_pickup',
                'label'    => 'Recogida local',
                'cost_raw' => 0.0,
                'cost'     => self::money(0.0),
            ],
        ];
    }

    private static function validate_coupon(string $code, int $user_id): array
    {
        if ($code === '') {
            return ['error' => 'El codigo de cupon no puede estar vacio.'];
        }

        $coupon = new WC_Coupon($code);

        if ($coupon->get_id() === 0) {
            return ['error' => 'El cupon "' . esc_html(strtoupper($code)) . '" no existe o no es valido.'];
        }

        $expiry = $coupon->get_date_expires();
        if ($expiry instanceof WC_DateTime && $expiry->getTimestamp() < time()) {
            return ['error' => 'El cupon ha caducado.'];
        }

        $usage_limit = (int) $coupon->get_usage_limit();
        if ($usage_limit > 0 && (int) $coupon->get_usage_count() >= $usage_limit) {
            return ['error' => 'El cupon ha alcanzado su limite de usos.'];
        }

        $per_user = (int) $coupon->get_usage_limit_per_user();
        if ($per_user > 0 && $user_id > 0) {
            $used_by   = (array) $coupon->get_used_by();
            $user_data = get_userdata($user_id);
            $targets   = array_filter([$user_id, $user_data ? $user_data->user_email : '']);
            $count     = count(array_filter($used_by, static fn ($entry) => in_array($entry, array_map('strval', $targets), true)));
            if ($count >= $per_user) {
                return ['error' => 'Ya has alcanzado el limite de uso de este cupon.'];
            }
        }

        return ['valid' => true];
    }

    private static function calculate_discount(string $code, float $subtotal, int $user_id): array
    {
        $validation = self::validate_coupon($code, $user_id);
        if (isset($validation['error'])) {
            return $validation;
        }

        $coupon = new WC_Coupon($code);

        $min_spend = (float) $coupon->get_minimum_amount();
        if ($min_spend > 0.0 && $subtotal < $min_spend) {
            return ['error' => 'El pedido minimo para este cupon es ' . self::money($min_spend) . '.'];
        }

        $max_spend = (float) $coupon->get_maximum_amount();
        if ($max_spend > 0.0 && $subtotal > $max_spend) {
            return ['error' => 'Este cupon solo aplica en pedidos de hasta ' . self::money($max_spend) . '.'];
        }

        $type     = (string) $coupon->get_discount_type();
        $amount   = (float) $coupon->get_amount();
        $decimals = function_exists('wc_get_price_decimals') ? wc_get_price_decimals() : 2;

        $discount = match ($type) {
            'percent'    => round($subtotal * $amount / 100, $decimals),
            'fixed_cart' => min($subtotal, $amount),
            default      => 0.0,
        };

        return ['discount' => $discount];
    }

    private static function find_method(array $methods, string $id): ?array
    {
        foreach ($methods as $method) {
            if ((string) $method['id'] === $id) {
                return $method;
            }
        }

        return $methods[0] ?? null;
    }

    private static function cart_items(int $user_id): array
    {
        global $wpdb;

        $rows = $wpdb->get_results($wpdb->prepare(
            'SELECT product_id, quantity FROM ' . $wpdb->prefix . 'tcg_cart_items WHERE user_id = %d',
            $user_id
        )) ?: [];

        $items = [];
        foreach ($rows as $row) {
            $product = function_exists('wc_get_product') ? wc_get_product((int) $row->product_id) : null;
            if (! $product instanceof WC_Product) {
                continue;
            }

            $items[] = [
                'product_id' => (int) $row->product_id,
                'quantity'   => (int) $row->quantity,
                'price_raw'  => (float) $product->get_price(),
            ];
        }

        return $items;
    }

    private static function money(float $amount): string
    {
        if (function_exists('wc_price')) {
            return html_entity_decode(wp_strip_all_tags(wc_price($amount)), ENT_QUOTES, get_bloginfo('charset'));
        }

        return number_format($amount, 2, ',', '.') . ' €';
    }

    private static function error(string $code, string $message, int $status): WP_Error
    {
        return new WP_Error($code, $message, ['status' => $status]);
    }
}
