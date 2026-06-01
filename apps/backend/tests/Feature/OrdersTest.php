<?php

declare(strict_types=1);

/**
 * @group integration
 * Tests that the orders endpoint returns real WooCommerce orders for the authenticated user.
 */
describe('Orders endpoints', function (): void {
    it('GET /orders returns a list', function (): void {
        $response = ApiClient::get('/orders');

        expect($response['status'])->toBe(200)
            ->and($response['body'])->toHaveKey('data')
            ->and($response['body']['data'])->toBeArray();
    });

    it('orders contain expected fields', function (): void {
        $response = ApiClient::get('/orders');
        $orders   = $response['body']['data'] ?? [];

        if (empty($orders)) {
            $this->markTestSkipped('No orders found for this user.');
        }

        $order = $orders[0];
        expect($order)->toHaveKeys([
            'id', 'number', 'status', 'status_label',
            'total', 'item_count', 'created_at',
        ]);
    });

    it('GET /orders/{id} returns 404 for non-existent order', function (): void {
        $response = ApiClient::get('/orders/999999999');

        expect($response['status'])->toBe(404)
            ->and($response['body']['code'])->toBe('tcg_order_not_found');
    });

    it('GET /orders/{id} returns detailed order for user-owned order', function (): void {
        $list   = ApiClient::get('/orders');
        $orders = $list['body']['data'] ?? [];

        if (empty($orders)) {
            $this->markTestSkipped('No orders available to test detail endpoint.');
        }

        $orderId  = (int) $orders[0]['id'];
        $response = ApiClient::get("/orders/{$orderId}");

        expect($response['status'])->toBe(200)
            ->and($response['body']['data'])->toHaveKeys([
                'id', 'number', 'status', 'items', 'billing', 'timeline',
            ]);
    });

    it('admin /admin/sales is forbidden for regular customer', function (): void {
        $response = ApiClient::get('/admin/sales');

        expect($response['status'])->toBe(403)
            ->and($response['body']['code'])->toBe('tcg_sales_forbidden');
    });

    it('admin /admin/inventory is forbidden for regular customer', function (): void {
        $response = ApiClient::get('/admin/inventory');

        expect($response['status'])->toBe(403)
            ->and($response['body']['code'])->toBe('tcg_inventory_forbidden');
    });
});
