<?php

/**
 * Plugin Name: TCG Platform Hardening
 * Description: Headless WordPress hardening for the TCG Platform starter.
 * Author: TCG Platform
 * Version: 0.1.0
 */

declare(strict_types=1);

if (! defined('ABSPATH')) {
    exit;
}

final class TCG_Platform_Hardening
{
    public static function boot(): void
    {
        add_action('init', [self::class, 'disable_comments_support'], 20);
        add_action('template_redirect', [self::class, 'redirect_wordpress_frontend'], 0);
        add_action('admin_init', [self::class, 'guard_wp_admin'], 0);
        add_action('login_enqueue_scripts', [self::class, 'login_notice']);

        add_filter('comments_open', '__return_false', 20);
        add_filter('pings_open', '__return_false', 20);
        add_filter('comments_array', '__return_empty_array', 20);
        add_filter('rest_endpoints', [self::class, 'disable_comments_rest_endpoints']);
        add_filter('rest_endpoints', [self::class, 'disable_user_rest_endpoints']);
        add_filter('xmlrpc_enabled', '__return_false');
        add_filter('the_generator', '__return_empty_string');
        add_filter('show_admin_bar', [self::class, 'show_admin_bar']);
        add_filter('login_redirect', [self::class, 'login_redirect'], 10, 3);
        add_filter('allowed_redirect_hosts', [self::class, 'allowed_redirect_hosts']);

        remove_action('wp_head', 'wp_generator');
        remove_action('wp_head', 'rsd_link');
        remove_action('wp_head', 'wlwmanifest_link');
    }

    public static function disable_comments_support(): void
    {
        foreach (get_post_types() as $post_type) {
            if (post_type_supports($post_type, 'comments')) {
                remove_post_type_support($post_type, 'comments');
            }

            if (post_type_supports($post_type, 'trackbacks')) {
                remove_post_type_support($post_type, 'trackbacks');
            }
        }
    }

    public static function redirect_wordpress_frontend(): void
    {
        if (is_admin() || wp_doing_ajax() || wp_doing_cron() || self::is_rest_request()) {
            return;
        }

        if (self::is_login_request()) {
            return;
        }

        $frontend = self::frontend_url();
        if ($frontend === '') {
            status_header(404);
            nocache_headers();
            exit;
        }

        wp_safe_redirect($frontend, 302);
        exit;
    }

    public static function guard_wp_admin(): void
    {
        if (wp_doing_ajax() || wp_doing_cron()) {
            return;
        }

        if (! is_user_logged_in()) {
            return;
        }

        if (! self::can_access_wp_admin()) {
            wp_safe_redirect(self::frontend_url('/perfil') ?: home_url('/'));
            exit;
        }

    }

    public static function login_notice(): void
    {
        ?>
        <style>
            .tcg-login-notice {
                margin: 0 0 16px;
                border-left: 4px solid #2271b1;
                background: #fff;
                padding: 12px;
                color: #1d2327;
                font-size: 13px;
                line-height: 1.45;
            }
        </style>
        <script>
            document.addEventListener('DOMContentLoaded', function () {
                var form = document.querySelector('#loginform');
                if (!form) return;
                var notice = document.createElement('p');
                notice.className = 'tcg-login-notice';
                notice.textContent = 'El panel de WordPress esta reservado para administradores. Los usuarios finales deben usar el frontend.';
                form.parentNode.insertBefore(notice, form);
            });
        </script>
        <?php
    }

    public static function disable_comments_rest_endpoints(array $endpoints): array
    {
        foreach (array_keys($endpoints) as $route) {
            if (str_starts_with($route, '/wp/v2/comments')) {
                unset($endpoints[$route]);
            }
        }

        return $endpoints;
    }

    public static function disable_user_rest_endpoints(array $endpoints): array
    {
        foreach (array_keys($endpoints) as $route) {
            if (str_starts_with($route, '/wp/v2/users')) {
                unset($endpoints[$route]);
            }
        }

        return $endpoints;
    }

    public static function show_admin_bar(bool $show): bool
    {
        return $show && self::can_access_wp_admin();
    }

    public static function login_redirect(string $redirect_to, string $requested_redirect_to, WP_User|WP_Error $user): string
    {
        if (! $user instanceof WP_User) {
            return $redirect_to;
        }

        if (user_can($user, 'manage_options')) {
            return admin_url();
        }

        return self::frontend_url('/perfil') ?: home_url('/');
    }

    public static function allowed_redirect_hosts(array $hosts): array
    {
        $host = wp_parse_url(self::frontend_url(), PHP_URL_HOST);
        if (is_string($host) && $host !== '') {
            $hosts[] = $host;
        }

        return array_values(array_unique($hosts));
    }

    private static function can_access_wp_admin(): bool
    {
        return current_user_can('manage_options');
    }

    private static function is_rest_request(): bool
    {
        $uri = isset($_SERVER['REQUEST_URI']) ? (string) $_SERVER['REQUEST_URI'] : '';

        return defined('REST_REQUEST') && REST_REQUEST
            || str_contains($uri, '/wp-json/')
            || str_starts_with($uri, '/wp-json');
    }

    private static function is_login_request(): bool
    {
        $script = isset($_SERVER['SCRIPT_NAME']) ? basename((string) $_SERVER['SCRIPT_NAME']) : '';

        return $script === 'wp-login.php';
    }

    private static function frontend_url(string $path = ''): string
    {
        $base = getenv('FRONTEND_URL') ?: getenv('PUBLIC_FRONTEND_URL') ?: 'http://localhost:4321';
        $base = untrailingslashit((string) $base);

        return $base . '/' . ltrim($path, '/');
    }
}

TCG_Platform_Hardening::boot();
