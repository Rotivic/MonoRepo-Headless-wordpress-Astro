<?php

declare(strict_types=1);

require_once __DIR__ . '/tests/Helpers/ApiClient.php';

uses()->beforeAll(function (): void {
    ApiClient::configure(
        email: (string) (getenv('TCG_TEST_EMAIL') ?: 'cliente.demo@example.test'),
        password: (string) (getenv('TCG_TEST_PASSWORD') ?: 'PasswordDemo123!'),
    );
})->in('tests/Feature');
