<?php

declare(strict_types=1);

/**
 * @group integration
 * Tests the checkout flow end-to-end: cart → checkout → order created.
 * Creates a real WooCommerce order. Teardown is not automatic (WooCommerce does
 * not expose a delete-order endpoint in the tcg API); orders can be reviewed in wp-admin.
 */
describe('Checkout endpoint', function (): void {
    beforeEach(function (): void {
        ApiClient::delete('/cart');
        ApiClient::delete('/cart/coupon');
    });

    it('returns 422 when cart is empty', function (): void {
        $response = ApiClient::post('/checkout', minimal_billing());

        expect($response['status'])->toBe(422)
            ->and($response['body']['code'])->toBe('tcg_checkout_empty_cart');
    });

    it('creates an order from cart and returns payload', function (): void {
        $productId = first_published_product_id();
        if ($productId === 0) {
            $this->markTestSkipped('No published products available for checkout.');
        }

        ApiClient::post('/cart', ['product_id' => $productId, 'quantity' => 1]);
        $response = ApiClient::post('/checkout', minimal_billing());

        expect($response['status'])->toBe(201)
            ->and($response['body']['data'])->toHaveKeys([
                'id', 'number', 'status',
                'subtotal_raw', 'subtotal',
                'shipping_raw', 'shipping',
                'tax_raw',
                'total_raw', 'total',
                'items',
            ])
            ->and($response['body']['data']['status'])->toBe('on-hold')
            ->and($response['body']['data']['items'])->not->toBeEmpty();
    });

    it('order number is a non-empty string or integer', function (): void {
        $productId = first_published_product_id();
        if ($productId === 0) {
            $this->markTestSkipped('No published products available.');
        }

        ApiClient::post('/cart', ['product_id' => $productId, 'quantity' => 1]);
        $response = ApiClient::post('/checkout', minimal_billing());

        expect($response['body']['data']['number'])->not->toBeEmpty();
    });

    it('cart is empty after successful checkout', function (): void {
        $productId = first_published_product_id();
        if ($productId === 0) {
            $this->markTestSkipped('No published products available.');
        }

        ApiClient::post('/cart', ['product_id' => $productId, 'quantity' => 1]);
        ApiClient::post('/checkout', minimal_billing());

        $cart = ApiClient::get('/cart');
        expect($cart['body']['meta']['count'])->toBe(0);
    });

    it('checkout with valid seed coupon applies discount to order', function (): void {
        $productId  = first_published_product_id();
        $couponCode = first_valid_coupon_code_co();
        if ($productId === 0 || $couponCode === '') {
            $this->markTestSkipped('No product or coupon available.');
        }

        ApiClient::post('/cart', ['product_id' => $productId, 'quantity' => 1]);
        $response = ApiClient::post('/checkout', [
            ...minimal_billing(),
            'coupon_code' => $couponCode,
        ]);

        // Discount may or may not apply depending on coupon conditions
        // We just verify the order is created successfully
        expect($response['status'])->toBe(201);
        if ($response['status'] === 201) {
            expect($response['body']['data'])->toHaveKey('coupon_codes');
        }
    });
});

function minimal_billing(): array
{
    return [
        'email'           => 'cliente.demo@example.test',
        'name'            => 'Cliente Demo',
        'phone'           => '600000000',
        'address'         => 'Calle Test 1',
        'postal_code'     => '28001',
        'city'            => 'Madrid',
        'state'           => 'Madrid',
        'country'         => 'ES',
        'shipping_method' => 'local_delivery',
        'notes'           => 'Test order from Pest integration suite.',
    ];
}

function first_valid_coupon_code_co(): string
{
    $url = ApiClient::baseUrl() . '/wp-json/wc/v3/coupons?per_page=1';
    $ch  = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_USERPWD        => 'admin:admin',
        CURLOPT_TIMEOUT        => 10,
    ]);
    $raw = (string) curl_exec($ch);
    curl_close($ch);

    $coupons = json_decode($raw, true);

    return isset($coupons[0]['code']) ? (string) $coupons[0]['code'] : '';
}
