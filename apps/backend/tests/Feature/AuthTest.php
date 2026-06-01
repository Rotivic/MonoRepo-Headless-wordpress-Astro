<?php

declare(strict_types=1);

/**
 * @group integration
 */
describe('Auth endpoints', function (): void {
    it('returns 401 when calling /me without credentials', function (): void {
        $url = ApiClient::baseUrl() . '/wp-json/tcg/v1/me';
        $ch  = curl_init($url);
        curl_setopt_array($ch, [CURLOPT_RETURNTRANSFER => true, CURLOPT_TIMEOUT => 10]);
        $raw    = (string) curl_exec($ch);
        $status = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        expect($status)->toBe(401);
    });

    it('can login with valid credentials and receives a token', function (): void {
        $token = ApiClient::token();

        expect($token)->toBeString()->not->toBeEmpty();
    });

    it('returns current user data from /me', function (): void {
        $response = ApiClient::get('/me');

        expect($response['status'])->toBe(200)
            ->and($response['body']['data'])->toHaveKeys(['id', 'email', 'display_name'])
            ->and($response['body']['data']['email'])->not->toBeEmpty();
    });

    it('returns 401 with invalid credentials', function (): void {
        $url = ApiClient::baseUrl() . '/wp-json/tcg/v1/login';
        $ch  = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST           => true,
            CURLOPT_HTTPHEADER     => ['Content-Type: application/json'],
            CURLOPT_POSTFIELDS     => json_encode(['email' => 'nobody@nowhere.test', 'password' => 'wrong']),
            CURLOPT_TIMEOUT        => 10,
        ]);
        $status = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_exec($ch);
        $status = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        expect($status)->toBe(401);
    });
});
