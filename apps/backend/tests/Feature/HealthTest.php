<?php

declare(strict_types=1);

/**
 * @group integration
 * Requires the Docker stack to be running.
 * Run: docker compose exec php vendor/bin/pest
 */
describe('Health endpoint', function (): void {
    it('returns 200 and ok status', function (): void {
        $response = ApiClient::get('/health');

        expect($response['status'])->toBe(200)
            ->and($response['body']['status'])->toBeIn(['ok', 'degraded'])
            ->and($response['body'])->toHaveKeys(['namespace', 'time', 'checks']);
    });

    it('includes required checks in response', function (): void {
        $response = ApiClient::get('/health');

        expect($response['body']['checks'])->toHaveKeys(['wordpress', 'database', 'woocommerce']);
    });

    it('reports wordpress as ok', function (): void {
        $response = ApiClient::get('/health');

        expect($response['body']['checks']['wordpress']['status'])->toBe('ok');
    });

    it('reports database as ok', function (): void {
        $response = ApiClient::get('/health');

        expect($response['body']['checks']['database']['status'])->toBe('ok');
    });
});
