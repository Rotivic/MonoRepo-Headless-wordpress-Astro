<?php

declare(strict_types=1);

/**
 * @group integration
 * Tests cart CRUD, validation and totals endpoint.
 * Uses the seed product catalog (expects at least one published product).
 */
describe('Cart endpoints', function (): void {
    beforeEach(function (): void {
        // Start each test with a clean cart
        ApiClient::delete('/cart');
    });

    afterAll(function (): void {
        ApiClient::delete('/cart');
    });

    it('GET /cart returns empty cart for fresh user', function (): void {
        $response = ApiClient::get('/cart');

        expect($response['status'])->toBe(200)
            ->and($response['body'])->toHaveKeys(['data', 'meta'])
            ->and($response['body']['data'])->toBeArray()
            ->and($response['body']['meta'])->toHaveKeys(['count', 'quantity', 'subtotal_raw']);
    });

    it('POST /cart adds a product and returns updated cart', function (): void {
        $productId = first_available_product_id();
        expect($productId)->toBeGreaterThan(0, 'Seed catalog has no published products.');

        $response = ApiClient::post('/cart', ['product_id' => $productId, 'quantity' => 1]);

        expect($response['status'])->toBe(201)
            ->and($response['body']['meta']['count'])->toBe(1)
            ->and($response['body']['data'][0]['product_id'])->toBe($productId);
    });

    it('PATCH /cart/{id} updates quantity', function (): void {
        $productId = first_available_product_id();
        ApiClient::post('/cart', ['product_id' => $productId, 'quantity' => 1]);

        $response = ApiClient::patch("/cart/{$productId}", ['quantity' => 2]);

        expect($response['status'])->toBe(200)
            ->and($response['body']['data'][0]['quantity'])->toBe(2);
    });

    it('PATCH /cart/{id} with quantity 0 removes the item', function (): void {
        $productId = first_available_product_id();
        ApiClient::post('/cart', ['product_id' => $productId, 'quantity' => 1]);

        $response = ApiClient::patch("/cart/{$productId}", ['quantity' => 0]);

        expect($response['status'])->toBe(200)
            ->and($response['body']['meta']['count'])->toBe(0);
    });

    it('DELETE /cart/{id} removes specific item', function (): void {
        $productId = first_available_product_id();
        ApiClient::post('/cart', ['product_id' => $productId, 'quantity' => 1]);

        $response = ApiClient::delete("/cart/{$productId}");

        expect($response['status'])->toBe(200)
            ->and($response['body']['meta']['count'])->toBe(0);
    });

    it('DELETE /cart clears all items', function (): void {
        $productId = first_available_product_id();
        ApiClient::post('/cart', ['product_id' => $productId, 'quantity' => 1]);

        $response = ApiClient::delete('/cart');

        expect($response['status'])->toBe(200)
            ->and($response['body']['meta']['count'])->toBe(0);
    });

    it('GET /cart/totals returns full breakdown', function (): void {
        $productId = first_available_product_id();
        ApiClient::post('/cart', ['product_id' => $productId, 'quantity' => 1]);

        $response = ApiClient::get('/cart/totals');

        expect($response['status'])->toBe(200)
            ->and($response['body']['data'])->toHaveKeys([
                'subtotal_raw', 'subtotal',
                'discount_raw', 'discount',
                'shipping_raw', 'shipping',
                'tax_raw',
                'total_raw', 'total',
                'shipping_methods',
            ])
            ->and($response['body']['data']['subtotal_raw'])->toBeGreaterThanOrEqual(0)
            ->and($response['body']['data']['shipping_methods'])->toBeArray()->not->toBeEmpty();
    });

    it('cart item payload contains expected fields', function (): void {
        $productId = first_available_product_id();
        ApiClient::post('/cart', ['product_id' => $productId, 'quantity' => 1]);

        $response = ApiClient::get('/cart');
        $item      = $response['body']['data'][0];

        expect($item)->toHaveKeys([
            'product_id', 'name', 'price', 'price_raw',
            'line_subtotal', 'line_subtotal_raw',
            'quantity', 'is_in_stock', 'is_valid',
        ]);
    });

    it('rejects product_id 0', function (): void {
        $response = ApiClient::post('/cart', ['product_id' => 0, 'quantity' => 1]);
        expect($response['status'])->toBe(400);
    });
});

function first_available_product_id(): int
{
    static $id = null;
    if ($id !== null) {
        return $id;
    }

    $url = ApiClient::baseUrl() . '/wp-json/wc/store/v1/products?per_page=1&status=publish';
    $raw = file_get_contents($url);
    if ($raw === false) {
        return 0;
    }

    $products = json_decode($raw, true);
    $id       = isset($products[0]['id']) ? (int) $products[0]['id'] : 0;

    return $id;
}
