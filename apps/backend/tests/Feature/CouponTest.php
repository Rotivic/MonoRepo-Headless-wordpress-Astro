<?php

declare(strict_types=1);

/**
 * @group integration
 * Tests coupon validation, apply, remove and totals discount.
 * Requires the seed to have created at least one valid coupon (see seed-demo-shop.php).
 */
describe('Coupon endpoints', function (): void {
    beforeEach(function (): void {
        ApiClient::delete('/cart');
        ApiClient::delete('/cart/coupon');

        $productId = first_published_product_id();
        if ($productId > 0) {
            ApiClient::post('/cart', ['product_id' => $productId, 'quantity' => 1]);
        }
    });

    afterAll(function (): void {
        ApiClient::delete('/cart');
        ApiClient::delete('/cart/coupon');
    });

    it('POST /cart/coupon with invalid code returns 422', function (): void {
        $response = ApiClient::post('/cart/coupon', ['code' => 'INVALID_CODE_XYZ_NOTEXIST']);

        expect($response['status'])->toBe(422)
            ->and($response['body']['code'])->toBe('tcg_coupon_invalid');
    });

    it('DELETE /cart/coupon removes coupon and returns totals', function (): void {
        $response = ApiClient::delete('/cart/coupon');

        expect($response['status'])->toBe(200)
            ->and($response['body']['data'])->toHaveKeys(['coupon_code', 'total_raw', 'subtotal_raw']);
        expect($response['body']['data']['coupon_code'])->toBe('');
    });

    it('GET /cart/totals with no coupon has zero discount', function (): void {
        $response = ApiClient::get('/cart/totals');

        expect($response['status'])->toBe(200)
            ->and($response['body']['data']['discount_raw'])->toBe(0.0)
            ->and($response['body']['data']['coupon_code'])->toBe('');
    });

    it('applies a valid seed coupon and reduces the total', function (): void {
        $couponCode = first_valid_coupon_code();
        if ($couponCode === '') {
            $this->markTestSkipped('No valid seed coupon found in WooCommerce.');
        }

        $before = ApiClient::get('/cart/totals');
        $apply  = ApiClient::post('/cart/coupon', ['code' => $couponCode]);

        expect($apply['status'])->toBe(200)
            ->and($apply['body']['data']['coupon_code'])->toBe(strtolower($couponCode))
            ->and($apply['body']['data']['discount_raw'])->toBeGreaterThan(0)
            ->and($apply['body']['data']['total_raw'])->toBeLessThanOrEqual($before['body']['data']['total_raw']);
    });

    it('removes an applied coupon and restores the total', function (): void {
        $couponCode = first_valid_coupon_code();
        if ($couponCode === '') {
            $this->markTestSkipped('No valid seed coupon found in WooCommerce.');
        }

        ApiClient::post('/cart/coupon', ['code' => $couponCode]);
        $withCoupon    = ApiClient::get('/cart/totals');
        ApiClient::delete('/cart/coupon');
        $withoutCoupon = ApiClient::get('/cart/totals');

        expect($withoutCoupon['body']['data']['total_raw'])
            ->toBeGreaterThanOrEqual($withCoupon['body']['data']['total_raw']);
        expect($withoutCoupon['body']['data']['coupon_code'])->toBe('');
    });

    it('POST /cart/coupon with empty code returns 400', function (): void {
        $response = ApiClient::post('/cart/coupon', ['code' => '']);
        expect($response['status'])->toBeIn([400, 422]);
    });
});

function first_published_product_id(): int
{
    static $id = null;
    if ($id !== null) {
        return $id;
    }

    $url = ApiClient::baseUrl() . '/wp-json/wc/store/v1/products?per_page=1&status=publish';
    $raw = @file_get_contents($url);
    if ($raw === false) {
        return 0;
    }

    $products = json_decode($raw, true);
    $id       = isset($products[0]['id']) ? (int) $products[0]['id'] : 0;

    return $id;
}

function first_valid_coupon_code(): string
{
    static $code = null;
    if ($code !== null) {
        return $code;
    }

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
    $code    = isset($coupons[0]['code']) ? (string) $coupons[0]['code'] : '';

    return $code;
}
