<?php

declare(strict_types=1);

/**
 * Minimal HTTP client for integration tests against the running WP API.
 * Uses Bearer token auth to bypass CSRF checks (supported by the API).
 * Run from inside Docker: docker compose exec php vendor/bin/pest
 * or set TCG_TEST_API_URL=http://localhost:8080 to run from the host.
 */
final class ApiClient
{
    private static string $baseUrl = '';
    private static ?string $token = null;
    private static string $email = '';
    private static string $password = '';

    public static function configure(string $email, string $password): void
    {
        self::$email    = $email;
        self::$password = $password;
        self::$token    = null;
    }

    public static function baseUrl(): string
    {
        if (self::$baseUrl === '') {
            self::$baseUrl = rtrim((string) (getenv('TCG_TEST_API_URL') ?: 'http://nginx'), '/');
        }

        return self::$baseUrl;
    }

    public static function apiUrl(string $path): string
    {
        return self::baseUrl() . '/wp-json/tcg/v1' . $path;
    }

    /** Authenticates and returns the Bearer token. Caches token for the session. */
    public static function token(): string
    {
        if (self::$token !== null) {
            return self::$token;
        }

        $response = self::request('POST', '/login', [
            'email'       => self::$email,
            'password'    => self::$password,
            'device_name' => 'pest-integration-tests',
        ], false);

        if (! isset($response['body']['token'])) {
            throw new \RuntimeException('Login failed: ' . json_encode($response['body']));
        }

        self::$token = (string) $response['body']['token'];

        return self::$token;
    }

    public static function get(string $path, array $params = []): array
    {
        $url = self::apiUrl($path);
        if ($params !== []) {
            $url .= '?' . http_build_query($params);
        }

        return self::request('GET', $path, [], true, $url);
    }

    public static function post(string $path, array $body = []): array
    {
        return self::request('POST', $path, $body);
    }

    public static function patch(string $path, array $body = []): array
    {
        return self::request('PATCH', $path, $body);
    }

    public static function delete(string $path): array
    {
        return self::request('DELETE', $path);
    }

    public static function reset(): void
    {
        self::$token = null;
    }

    private static function request(string $method, string $path, array $body = [], bool $auth = true, ?string $fullUrl = null): array
    {
        $url = $fullUrl ?? self::apiUrl($path);

        $headers = ['Content-Type: application/json', 'Accept: application/json'];

        if ($auth) {
            $headers[] = 'Authorization: Bearer ' . self::token();
        }

        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HTTPHEADER     => $headers,
            CURLOPT_CUSTOMREQUEST  => $method,
            CURLOPT_TIMEOUT        => 15,
            CURLOPT_FOLLOWLOCATION => false,
        ]);

        if ($body !== [] && in_array($method, ['POST', 'PATCH', 'PUT'], true)) {
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($body));
        }

        $raw    = (string) curl_exec($ch);
        $status = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        $parsed = json_decode($raw, true);

        return [
            'status' => $status,
            'body'   => is_array($parsed) ? $parsed : ['raw' => $raw],
        ];
    }
}
