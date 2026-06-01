<?php

declare(strict_types=1);

/**
 * @group integration
 */
describe('Wishlist endpoints', function (): void {
    beforeEach(function (): void {
        // Clean wishlist before each test
        $existing = ApiClient::get('/wishlist');
        foreach ($existing['body']['data'] ?? [] as $item) {
            $id = (int) ($item['product_id'] ?? $item['id'] ?? 0);
            if ($id > 0) {
                ApiClient::delete("/wishlist/{$id}");
            }
        }
    });

    it('GET /wishlist returns empty list initially', function (): void {
        $response = ApiClient::get('/wishlist');

        expect($response['status'])->toBe(200)
            ->and($response['body']['data'])->toBeArray()->toBeEmpty();
    });

    it('POST /wishlist adds a product', function (): void {
        $productId = first_published_product_id();
        expect($productId)->toBeGreaterThan(0);

        $response = ApiClient::post('/wishlist', ['product_id' => $productId]);

        expect($response['status'])->toBeIn([200, 201])
            ->and($response['body']['data'])->toBeArray()->not->toBeEmpty();
    });

    it('GET /wishlist returns the added product', function (): void {
        $productId = first_published_product_id();
        ApiClient::post('/wishlist', ['product_id' => $productId]);

        $response = ApiClient::get('/wishlist');
        $ids      = array_column($response['body']['data'] ?? [], 'product_id');

        expect($ids)->toContain($productId);
    });

    it('wishlist item contains expected fields from WooCommerce', function (): void {
        $productId = first_published_product_id();
        ApiClient::post('/wishlist', ['product_id' => $productId]);

        $response = ApiClient::get('/wishlist');
        $item      = $response['body']['data'][0] ?? [];

        expect($item)->toHaveKeys(['product_id', 'name', 'price']);
    });

    it('DELETE /wishlist/{id} removes a product', function (): void {
        $productId = first_published_product_id();
        ApiClient::post('/wishlist', ['product_id' => $productId]);

        $delete = ApiClient::delete("/wishlist/{$productId}");

        expect($delete['status'])->toBe(200);

        $after = ApiClient::get('/wishlist');
        $ids   = array_column($after['body']['data'] ?? [], 'product_id');
        expect($ids)->not->toContain($productId);
    });

    it('adding same product twice does not create duplicates', function (): void {
        $productId = first_published_product_id();
        ApiClient::post('/wishlist', ['product_id' => $productId]);
        ApiClient::post('/wishlist', ['product_id' => $productId]);

        $response = ApiClient::get('/wishlist');
        $ids      = array_column($response['body']['data'] ?? [], 'product_id');

        expect(array_count_values($ids)[$productId] ?? 0)->toBe(1);
    });
});
