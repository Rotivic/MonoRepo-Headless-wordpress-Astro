<?php

declare(strict_types=1);

if (! defined('ABSPATH')) {
    exit;
}

trait TCG_API_ErrorTrait
{
    private static function error(string $code, string $message, int $status): WP_Error
    {
        return new WP_Error($code, $message, ['status' => $status]);
    }
}
