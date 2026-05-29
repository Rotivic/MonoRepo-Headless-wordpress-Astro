<?php

declare(strict_types=1);

if (! defined('ABSPATH')) {
    exit;
}

final class TCG_Platform_API
{
    private const NAMESPACE = 'tcg/v1';
    private const DB_VERSION = '2';
    private const DB_VERSION_OPTION = 'tcg_api_db_version';
    private const TOKEN_TTL = 30 * DAY_IN_SECONDS;
    private const LOGIN_LIMIT = 5;
    private const LOGIN_WINDOW = 15 * MINUTE_IN_SECONDS;
    private const SENSITIVE_ACTION_LIMIT = 5;
    private const SENSITIVE_ACTION_WINDOW = 15 * MINUTE_IN_SECONDS;
    private const SESSION_COOKIE = 'tcg_platform_session';
    private const CSRF_COOKIE = 'tcg_platform_csrf';
    private const CSRF_HEADER = 'x-tcg-csrf';
    private const REVOKE_SAME_DEVICE_SESSIONS = true;
    private const TWO_FACTOR_ISSUER = 'TCG Platform';
    private const TWO_FACTOR_SECRET_META = 'tcg_2fa_secret';
    private const TWO_FACTOR_PENDING_SECRET_META = 'tcg_2fa_pending_secret';
    private const TWO_FACTOR_ENABLED_META = 'tcg_2fa_enabled';
    private const TWO_FACTOR_RECOVERY_CODES_META = 'tcg_2fa_recovery_codes';
    private const TWO_FACTOR_CHALLENGE_TTL = 5 * MINUTE_IN_SECONDS;
    private const EMAIL_VERIFIED_META = 'tcg_email_verified';
    private const EMAIL_VERIFICATION_TOKEN_META = 'tcg_email_verification_token';
    private const EMAIL_VERIFICATION_EXPIRES_META = 'tcg_email_verification_expires';
    private const PASSWORD_RESET_TOKEN_META = 'tcg_password_reset_token';
    private const PASSWORD_RESET_EXPIRES_META = 'tcg_password_reset_expires';
    private const SHORT_TOKEN_TTL = 30 * MINUTE_IN_SECONDS;

    public static function boot(): void
    {
        add_action('rest_api_init', [self::class, 'register_routes']);
        add_action('init', [self::class, 'maybe_install']);
        add_action('phpmailer_init', [self::class, 'configure_mailer']);
        add_filter('wp_mail_from', [self::class, 'mail_from']);
        add_filter('wp_mail_from_name', [self::class, 'mail_from_name']);
        add_filter('rest_pre_serve_request', [self::class, 'send_cors_headers'], 10, 4);

        if (defined('WP_CLI') && WP_CLI) {
            WP_CLI::add_command('tcg 2fa-reset', [self::class, 'cli_two_factor_reset']);
        }
    }

    public static function maybe_install(): void
    {
        if (! self::wordpress_tables_exist() || ! get_option('siteurl')) {
            return;
        }

        if (get_option(self::DB_VERSION_OPTION) === self::DB_VERSION) {
            return;
        }

        self::install();
        update_option(self::DB_VERSION_OPTION, self::DB_VERSION, false);
    }

    public static function install(): void
    {
        global $wpdb;

        require_once ABSPATH . 'wp-admin/includes/upgrade.php';

        $table = self::tokens_table();
        $charset_collate = $wpdb->get_charset_collate();

        $sql = "CREATE TABLE {$table} (
            id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
            user_id BIGINT UNSIGNED NOT NULL,
            token_hash CHAR(64) NOT NULL,
            device_name VARCHAR(191) NULL,
            ip_hash CHAR(64) NULL,
            user_agent_hash CHAR(64) NULL,
            created_at DATETIME NOT NULL,
            last_used_at DATETIME NULL,
            expires_at DATETIME NOT NULL,
            revoked_at DATETIME NULL,
            PRIMARY KEY (id),
            UNIQUE KEY token_hash (token_hash),
            KEY user_id (user_id),
            KEY expires_at (expires_at),
            KEY revoked_at (revoked_at)
        ) {$charset_collate};";

        dbDelta($sql);

        if (class_exists('TCG_Platform_API_Wishlist')) {
            TCG_Platform_API_Wishlist::install();
        }
    }

    public static function register_routes(): void
    {
        register_rest_route(self::NAMESPACE, '/health', [
            'methods' => WP_REST_Server::READABLE,
            'callback' => [self::class, 'health'],
            'permission_callback' => [self::class, 'require_admin'],
        ]);

        register_rest_route(self::NAMESPACE, '/register', [
            'methods' => WP_REST_Server::CREATABLE,
            'callback' => [self::class, 'register_user'],
            'permission_callback' => '__return_true',
            'args' => self::register_args(),
        ]);

        register_rest_route(self::NAMESPACE, '/login', [
            'methods' => WP_REST_Server::CREATABLE,
            'callback' => [self::class, 'login'],
            'permission_callback' => '__return_true',
            'args' => self::login_args(),
        ]);

        register_rest_route(self::NAMESPACE, '/password/forgot', [
            'methods' => WP_REST_Server::CREATABLE,
            'callback' => [self::class, 'forgot_password'],
            'permission_callback' => '__return_true',
        ]);

        register_rest_route(self::NAMESPACE, '/password/reset', [
            'methods' => WP_REST_Server::CREATABLE,
            'callback' => [self::class, 'reset_password'],
            'permission_callback' => '__return_true',
        ]);

        register_rest_route(self::NAMESPACE, '/email/verify', [
            'methods' => WP_REST_Server::CREATABLE,
            'callback' => [self::class, 'verify_email'],
            'permission_callback' => '__return_true',
        ]);

        register_rest_route(self::NAMESPACE, '/email/resend', [
            'methods' => WP_REST_Server::CREATABLE,
            'callback' => [self::class, 'resend_email_verification'],
            'permission_callback' => [self::class, 'require_auth'],
        ]);

        register_rest_route(self::NAMESPACE, '/me', [
            'methods' => WP_REST_Server::READABLE,
            'callback' => [self::class, 'me'],
            'permission_callback' => [self::class, 'require_auth'],
        ]);

        register_rest_route(self::NAMESPACE, '/me', [
            'methods' => WP_REST_Server::EDITABLE,
            'callback' => [self::class, 'update_me'],
            'permission_callback' => [self::class, 'require_auth'],
        ]);

        register_rest_route(self::NAMESPACE, '/me/password', [
            'methods' => WP_REST_Server::CREATABLE,
            'callback' => [self::class, 'change_password'],
            'permission_callback' => [self::class, 'require_auth'],
        ]);

        register_rest_route(self::NAMESPACE, '/sessions', [
            'methods' => WP_REST_Server::READABLE,
            'callback' => [self::class, 'sessions'],
            'permission_callback' => [self::class, 'require_auth'],
        ]);

        register_rest_route(self::NAMESPACE, '/sessions/(?P<id>\d+)', [
            'methods' => WP_REST_Server::DELETABLE,
            'callback' => [self::class, 'revoke_session'],
            'permission_callback' => [self::class, 'require_auth'],
        ]);

        register_rest_route(self::NAMESPACE, '/admin/users', [
            'methods' => WP_REST_Server::READABLE,
            'callback' => [self::class, 'admin_users'],
            'permission_callback' => [self::class, 'require_admin'],
        ]);

        register_rest_route(self::NAMESPACE, '/logout', [
            'methods' => WP_REST_Server::CREATABLE,
            'callback' => [self::class, 'logout'],
            'permission_callback' => [self::class, 'require_auth'],
        ]);

        register_rest_route(self::NAMESPACE, '/2fa/setup', [
            'methods' => WP_REST_Server::CREATABLE,
            'callback' => [self::class, 'two_factor_setup'],
            'permission_callback' => [self::class, 'require_auth'],
        ]);

        register_rest_route(self::NAMESPACE, '/2fa/enable', [
            'methods' => WP_REST_Server::CREATABLE,
            'callback' => [self::class, 'two_factor_enable'],
            'permission_callback' => [self::class, 'require_auth'],
        ]);

        register_rest_route(self::NAMESPACE, '/2fa/disable', [
            'methods' => WP_REST_Server::CREATABLE,
            'callback' => [self::class, 'two_factor_disable'],
            'permission_callback' => [self::class, 'require_auth'],
        ]);

        register_rest_route(self::NAMESPACE, '/2fa/verify', [
            'methods' => WP_REST_Server::CREATABLE,
            'callback' => [self::class, 'two_factor_verify'],
            'permission_callback' => '__return_true',
        ]);

        if (class_exists('TCG_Platform_API_Wishlist')) {
            TCG_Platform_API_Wishlist::register_routes(self::NAMESPACE);
        }
    }

    public static function register_user(WP_REST_Request $request): WP_REST_Response|WP_Error
    {
        $email = sanitize_email((string) $request->get_param('email'));
        $password = (string) $request->get_param('password');
        $password_confirmation = (string) $request->get_param('password_confirmation');
        $first_name = sanitize_text_field((string) $request->get_param('first_name'));
        $last_name = sanitize_text_field((string) $request->get_param('last_name'));
        $website = trim((string) $request->get_param('website'));
        $rate_key = self::action_rate_key('register', $email);

        if ($website !== '') {
            return self::error('tcg_register_failed', 'The account could not be created.', 422);
        }

        if (self::is_rate_limited($rate_key, self::SENSITIVE_ACTION_LIMIT)) {
            return self::error('tcg_register_limited', 'Too many attempts. Try again later.', 429);
        }

        self::increment_rate_limit($rate_key, self::SENSITIVE_ACTION_WINDOW);

        if ($password !== $password_confirmation) {
            return self::error('tcg_password_mismatch', 'Password confirmation does not match.', 422);
        }

        $password_error = self::validate_password($password);
        if ($password_error instanceof WP_Error) {
            return $password_error;
        }

        if (email_exists($email)) {
            return self::error('tcg_register_failed', 'The account could not be created.', 422);
        }

        $user_id = wp_insert_user([
            'user_login' => self::username_from_email($email),
            'user_email' => $email,
            'user_pass' => $password,
            'first_name' => $first_name,
            'last_name' => $last_name,
            'display_name' => trim("{$first_name} {$last_name}") ?: $email,
            'role' => class_exists('WooCommerce') ? 'customer' : 'subscriber',
        ]);

        if (is_wp_error($user_id)) {
            return self::error('tcg_register_failed', 'The account could not be created.', 500);
        }

        update_user_meta((int) $user_id, self::EMAIL_VERIFIED_META, '0');
        self::send_email_verification((int) $user_id);

        $device_name = self::device_name($request);
        $token = self::issue_token((int) $user_id, $device_name);
        $user = get_user_by('id', (int) $user_id);
        self::send_session_cookie($token);

        return new WP_REST_Response([
            'token' => $token,
            'two_factor' => false,
            'data' => self::user_payload($user),
        ], 201);
    }

    public static function health(): WP_REST_Response
    {
        global $wpdb;

        $checks = [
            'wordpress' => [
                'status' => get_option('siteurl') ? 'ok' : 'error',
                'label' => 'WordPress instalado',
            ],
            'database' => [
                'status' => $wpdb->check_connection(false) ? 'ok' : 'error',
                'label' => 'Base de datos',
            ],
            'woocommerce' => [
                'status' => class_exists('WooCommerce') ? 'ok' : 'warning',
                'label' => 'WooCommerce activo',
            ],
            'acf' => [
                'status' => function_exists('acf') ? 'ok' : 'warning',
                'label' => 'ACF activo',
            ],
            'fluent_forms' => [
                'status' => defined('FLUENTFORM') || defined('FLUENTFORM_VERSION') ? 'ok' : 'warning',
                'label' => 'Fluent Forms activo',
            ],
            'redis_extension' => [
                'status' => extension_loaded('redis') ? 'ok' : 'warning',
                'label' => 'Extension Redis PHP',
            ],
            'object_cache' => [
                'status' => wp_using_ext_object_cache() ? 'ok' : 'warning',
                'label' => 'Object cache externo',
            ],
            'mail' => [
                'status' => getenv('WP_MAIL_SMTP_HOST') ? 'ok' : 'warning',
                'label' => 'SMTP local configurado',
            ],
        ];

        $has_error = in_array('error', array_column($checks, 'status'), true);

        return new WP_REST_Response([
            'status' => $has_error ? 'degraded' : 'ok',
            'namespace' => self::NAMESPACE,
            'time' => gmdate(DATE_ATOM),
            'checks' => $checks,
        ]);
    }

    public static function login(WP_REST_Request $request): WP_REST_Response|WP_Error
    {
        $email = sanitize_email((string) $request->get_param('email'));
        $password = (string) $request->get_param('password');
        $rate_key = self::rate_key($email);

        if (self::is_rate_limited($rate_key)) {
            return self::error('tcg_login_limited', 'Too many login attempts. Try again later.', 429);
        }

        $user = wp_authenticate($email, $password);

        if (is_wp_error($user)) {
            self::increment_rate_limit($rate_key);

            return self::error('tcg_invalid_credentials', 'Invalid email or password.', 401);
        }

        delete_transient($rate_key);

        $device_name = self::device_name($request);
        if (self::is_two_factor_enabled((int) $user->ID)) {
            return new WP_REST_Response([
                'two_factor' => true,
                'challenge_token' => self::issue_two_factor_challenge((int) $user->ID, $device_name),
                'message' => 'Two-factor verification is required.',
            ]);
        }

        $token = self::issue_token((int) $user->ID, $device_name);
        self::send_session_cookie($token);

        return new WP_REST_Response([
            'token' => $token,
            'two_factor' => false,
            'data' => self::user_payload($user),
        ]);
    }

    public static function me(WP_REST_Request $request): WP_REST_Response|WP_Error
    {
        $auth = self::authenticate_request($request);
        if (is_wp_error($auth)) {
            return $auth;
        }

        return new WP_REST_Response([
            'data' => self::user_payload($auth['user']),
        ]);
    }

    public static function logout(WP_REST_Request $request): WP_REST_Response|WP_Error
    {
        $auth = self::authenticate_request($request);
        if (is_wp_error($auth)) {
            return $auth;
        }

        global $wpdb;

        $wpdb->update(
            self::tokens_table(),
            ['revoked_at' => self::now()],
            ['id' => (int) $auth['token_row']->id],
            ['%s'],
            ['%d']
        );

        self::clear_session_cookie();

        return new WP_REST_Response(['message' => 'Logged out.']);
    }

    public static function forgot_password(WP_REST_Request $request): WP_REST_Response
    {
        $email = sanitize_email((string) $request->get_param('email'));
        $rate_key = self::action_rate_key('forgot_password', $email);

        if (self::is_rate_limited($rate_key, self::SENSITIVE_ACTION_LIMIT)) {
            return new WP_REST_Response([
                'message' => 'If the email exists, password reset instructions were sent.',
            ]);
        }

        self::increment_rate_limit($rate_key, self::SENSITIVE_ACTION_WINDOW);
        $user = get_user_by('email', $email);

        if ($user instanceof WP_User) {
            $token = self::issue_user_short_token((int) $user->ID, self::PASSWORD_RESET_TOKEN_META, self::PASSWORD_RESET_EXPIRES_META);
            $url = self::frontend_url('/recuperar', [
                'email' => $user->user_email,
                'token' => $token,
            ]);

            wp_mail($user->user_email, 'Restablecer contrasena', "Puedes restablecer tu contrasena aqui:\n\n{$url}");
        }

        return new WP_REST_Response([
            'message' => 'If the email exists, password reset instructions were sent.',
        ]);
    }

    public static function reset_password(WP_REST_Request $request): WP_REST_Response|WP_Error
    {
        $email = sanitize_email((string) $request->get_param('email'));
        $token = self::sanitize_short_token((string) $request->get_param('token'));
        $password = (string) $request->get_param('password');
        $password_confirmation = (string) $request->get_param('password_confirmation');
        $user = get_user_by('email', $email);
        $rate_key = self::action_rate_key('reset_password', $email);

        if (self::is_rate_limited($rate_key, self::SENSITIVE_ACTION_LIMIT)) {
            return self::error('tcg_password_reset_limited', 'Too many attempts. Try again later.', 429);
        }

        self::increment_rate_limit($rate_key, self::SENSITIVE_ACTION_WINDOW);

        if (! $user instanceof WP_User || ! self::verify_user_short_token((int) $user->ID, $token, self::PASSWORD_RESET_TOKEN_META, self::PASSWORD_RESET_EXPIRES_META)) {
            return self::error('tcg_password_reset_invalid', 'Password reset token is invalid or expired.', 422);
        }

        if ($password !== $password_confirmation) {
            return self::error('tcg_password_mismatch', 'Password confirmation does not match.', 422);
        }

        $password_error = self::validate_password($password);
        if ($password_error instanceof WP_Error) {
            return $password_error;
        }

        wp_set_password($password, (int) $user->ID);
        self::revoke_user_tokens_except((int) $user->ID, 0);
        delete_user_meta($user->ID, self::PASSWORD_RESET_TOKEN_META);
        delete_user_meta($user->ID, self::PASSWORD_RESET_EXPIRES_META);

        return new WP_REST_Response(['message' => 'Password reset completed.']);
    }

    public static function verify_email(WP_REST_Request $request): WP_REST_Response|WP_Error
    {
        $email = sanitize_email((string) $request->get_param('email'));
        $token = self::sanitize_short_token((string) $request->get_param('token'));
        $user = get_user_by('email', $email);

        if (! $user instanceof WP_User || ! self::verify_user_short_token((int) $user->ID, $token, self::EMAIL_VERIFICATION_TOKEN_META, self::EMAIL_VERIFICATION_EXPIRES_META)) {
            return self::error('tcg_email_verification_invalid', 'Email verification token is invalid or expired.', 422);
        }

        update_user_meta($user->ID, self::EMAIL_VERIFIED_META, '1');
        delete_user_meta($user->ID, self::EMAIL_VERIFICATION_TOKEN_META);
        delete_user_meta($user->ID, self::EMAIL_VERIFICATION_EXPIRES_META);

        return new WP_REST_Response(['message' => 'Email verified.']);
    }

    public static function resend_email_verification(WP_REST_Request $request): WP_REST_Response|WP_Error
    {
        $auth = self::authenticate_request($request);
        if (is_wp_error($auth)) {
            return $auth;
        }

        if (self::is_email_verified((int) $auth['user']->ID)) {
            return new WP_REST_Response(['message' => 'Email is already verified.']);
        }

        self::send_email_verification((int) $auth['user']->ID);

        return new WP_REST_Response(['message' => 'Verification email sent.']);
    }

    public static function update_me(WP_REST_Request $request): WP_REST_Response|WP_Error
    {
        $auth = self::authenticate_request($request);
        if (is_wp_error($auth)) {
            return $auth;
        }

        $user = $auth['user'];
        $first_name = sanitize_text_field((string) $request->get_param('first_name'));
        $last_name = sanitize_text_field((string) $request->get_param('last_name'));
        $display_name = trim(sanitize_text_field((string) $request->get_param('display_name')));

        $update = [
            'ID' => (int) $user->ID,
            'first_name' => $first_name,
            'last_name' => $last_name,
            'display_name' => $display_name ?: trim("{$first_name} {$last_name}") ?: $user->user_email,
        ];

        $updated = wp_update_user($update);
        if (is_wp_error($updated)) {
            return self::error('tcg_profile_update_failed', 'Profile could not be updated.', 422);
        }

        $fresh_user = get_user_by('id', (int) $user->ID);

        return new WP_REST_Response([
            'message' => 'Profile updated.',
            'data' => self::user_payload($fresh_user),
        ]);
    }

    public static function change_password(WP_REST_Request $request): WP_REST_Response|WP_Error
    {
        $auth = self::authenticate_request($request);
        if (is_wp_error($auth)) {
            return $auth;
        }

        $current_password = (string) $request->get_param('current_password');
        $password = (string) $request->get_param('password');
        $password_confirmation = (string) $request->get_param('password_confirmation');

        if (! wp_check_password($current_password, $auth['user']->user_pass, (int) $auth['user']->ID)) {
            return self::error('tcg_current_password_invalid', 'Current password is invalid.', 422);
        }

        if ($password !== $password_confirmation) {
            return self::error('tcg_password_mismatch', 'Password confirmation does not match.', 422);
        }

        $password_error = self::validate_password($password);
        if ($password_error instanceof WP_Error) {
            return $password_error;
        }

        wp_set_password($password, (int) $auth['user']->ID);
        self::revoke_user_tokens_except((int) $auth['user']->ID, (int) $auth['token_row']->id);

        return new WP_REST_Response([
            'message' => 'Password updated. Other sessions were closed.',
        ]);
    }

    public static function sessions(WP_REST_Request $request): WP_REST_Response|WP_Error
    {
        $auth = self::authenticate_request($request);
        if (is_wp_error($auth)) {
            return $auth;
        }

        global $wpdb;

        $rows = $wpdb->get_results($wpdb->prepare(
            'SELECT id, device_name, created_at, last_used_at, expires_at FROM ' . self::tokens_table() . ' WHERE user_id = %d AND revoked_at IS NULL AND expires_at > UTC_TIMESTAMP() ORDER BY COALESCE(last_used_at, created_at) DESC',
            (int) $auth['user']->ID
        ));

        return new WP_REST_Response([
            'data' => array_map(static fn (object $row): array => [
                'id' => (int) $row->id,
                'device_name' => (string) $row->device_name,
                'created_at' => mysql_to_rfc3339((string) $row->created_at),
                'last_used_at' => $row->last_used_at ? mysql_to_rfc3339((string) $row->last_used_at) : null,
                'expires_at' => mysql_to_rfc3339((string) $row->expires_at),
                'current' => (int) $row->id === (int) $auth['token_row']->id,
            ], $rows),
        ]);
    }

    public static function revoke_session(WP_REST_Request $request): WP_REST_Response|WP_Error
    {
        $auth = self::authenticate_request($request);
        if (is_wp_error($auth)) {
            return $auth;
        }

        $session_id = (int) $request->get_param('id');

        global $wpdb;
        $updated = $wpdb->update(
            self::tokens_table(),
            ['revoked_at' => self::now()],
            [
                'id' => $session_id,
                'user_id' => (int) $auth['user']->ID,
            ],
            ['%s'],
            ['%d', '%d']
        );

        if ($session_id === (int) $auth['token_row']->id) {
            self::clear_session_cookie();
        }

        return new WP_REST_Response([
            'message' => $updated ? 'Session revoked.' : 'Session not found.',
            'current_revoked' => $session_id === (int) $auth['token_row']->id,
        ]);
    }

    public static function admin_users(WP_REST_Request $request): WP_REST_Response|WP_Error
    {
        $auth = self::authenticate_request($request);
        if (is_wp_error($auth)) {
            return $auth;
        }

        if (! user_can($auth['user'], 'manage_options')) {
            return self::error('tcg_admin_forbidden', 'Administrator permissions are required.', 403);
        }

        $search = sanitize_text_field((string) $request->get_param('search'));
        $page = max(1, (int) $request->get_param('page'));
        $per_page = min(50, max(1, (int) ($request->get_param('per_page') ?: 10)));
        $args = [
            'number' => $per_page,
            'paged' => $page,
            'orderby' => 'registered',
            'order' => 'DESC',
            'fields' => 'all',
            'count_total' => true,
        ];

        if ($search !== '') {
            $args['search'] = '*' . esc_attr($search) . '*';
            $args['search_columns'] = ['user_login', 'user_email', 'display_name'];
        }

        $query = new WP_User_Query($args);
        $users = $query->get_results();
        $total = (int) $query->get_total();

        return new WP_REST_Response([
            'data' => array_map(static fn (WP_User $user): array => [
                'id' => (int) $user->ID,
                'email' => $user->user_email,
                'display_name' => $user->display_name,
                'roles' => array_values((array) $user->roles),
                'is_admin' => user_can($user, 'manage_options'),
                'is_verified' => self::is_email_verified((int) $user->ID),
                'created_at' => mysql_to_rfc3339($user->user_registered),
                'edit_url' => admin_url('user-edit.php?user_id=' . (int) $user->ID),
            ], $users),
            'meta' => [
                'page' => $page,
                'per_page' => $per_page,
                'total' => $total,
                'total_pages' => max(1, (int) ceil($total / $per_page)),
            ],
        ]);
    }

    public static function two_factor_setup(WP_REST_Request $request): WP_REST_Response|WP_Error
    {
        $auth = self::authenticate_request($request);
        if (is_wp_error($auth)) {
            return $auth;
        }

        $user = $auth['user'];
        $secret = self::generate_totp_secret();
        update_user_meta($user->ID, self::TWO_FACTOR_PENDING_SECRET_META, self::encrypt_secret($secret));

        return new WP_REST_Response([
            'secret' => $secret,
            'otpauth_uri' => self::totp_uri($user, $secret),
            'enabled' => self::is_two_factor_enabled((int) $user->ID),
        ]);
    }

    public static function two_factor_enable(WP_REST_Request $request): WP_REST_Response|WP_Error
    {
        $auth = self::authenticate_request($request);
        if (is_wp_error($auth)) {
            return $auth;
        }

        $code = self::sanitize_totp_code((string) $request->get_param('code'));
        $encrypted = (string) get_user_meta($auth['user']->ID, self::TWO_FACTOR_PENDING_SECRET_META, true);
        $secret = self::decrypt_secret($encrypted);

        if ($secret === '' || ! self::verify_totp($secret, $code)) {
            return self::error('tcg_2fa_invalid_code', 'Invalid verification code.', 422);
        }

        update_user_meta($auth['user']->ID, self::TWO_FACTOR_SECRET_META, self::encrypt_secret($secret));
        update_user_meta($auth['user']->ID, self::TWO_FACTOR_ENABLED_META, '1');
        delete_user_meta($auth['user']->ID, self::TWO_FACTOR_PENDING_SECRET_META);
        $recovery_codes = self::generate_recovery_codes();
        update_user_meta($auth['user']->ID, self::TWO_FACTOR_RECOVERY_CODES_META, self::hash_recovery_codes($recovery_codes));

        return new WP_REST_Response([
            'message' => 'Two-factor authentication enabled.',
            'recovery_codes' => $recovery_codes,
            'data' => self::user_payload($auth['user']),
        ]);
    }

    public static function two_factor_disable(WP_REST_Request $request): WP_REST_Response|WP_Error
    {
        $auth = self::authenticate_request($request);
        if (is_wp_error($auth)) {
            return $auth;
        }

        $code = self::sanitize_totp_code((string) $request->get_param('code'));
        $secret = self::user_totp_secret((int) $auth['user']->ID);

        if ($secret !== '' && ! self::verify_totp($secret, $code)) {
            return self::error('tcg_2fa_invalid_code', 'Invalid verification code.', 422);
        }

        delete_user_meta($auth['user']->ID, self::TWO_FACTOR_SECRET_META);
        delete_user_meta($auth['user']->ID, self::TWO_FACTOR_PENDING_SECRET_META);
        delete_user_meta($auth['user']->ID, self::TWO_FACTOR_ENABLED_META);
        delete_user_meta($auth['user']->ID, self::TWO_FACTOR_RECOVERY_CODES_META);

        return new WP_REST_Response([
            'message' => 'Two-factor authentication disabled.',
            'data' => self::user_payload($auth['user']),
        ]);
    }

    public static function two_factor_verify(WP_REST_Request $request): WP_REST_Response|WP_Error
    {
        $challenge_token = self::sanitize_challenge_token((string) $request->get_param('challenge_token'));
        $code = self::sanitize_totp_code((string) $request->get_param('code'));
        $rate_key = self::action_rate_key('2fa_verify', $challenge_token);

        if (self::is_rate_limited($rate_key, self::SENSITIVE_ACTION_LIMIT)) {
            return self::error('tcg_2fa_limited', 'Too many attempts. Try again later.', 429);
        }

        self::increment_rate_limit($rate_key, self::SENSITIVE_ACTION_WINDOW);
        $challenge = self::read_two_factor_challenge($challenge_token);

        if (! $challenge) {
            return self::error('tcg_2fa_invalid_challenge', 'Two-factor challenge is invalid or expired.', 401);
        }

        $user = get_user_by('id', (int) $challenge['user_id']);
        if (! $user instanceof WP_User || ! self::verify_two_factor_code((int) $user->ID, $code)) {
            return self::error('tcg_2fa_invalid_code', 'Invalid verification code.', 422);
        }

        delete_transient(self::two_factor_challenge_key($challenge_token));

        $token = self::issue_token((int) $user->ID, (string) $challenge['device_name']);
        self::send_session_cookie($token);

        return new WP_REST_Response([
            'token' => $token,
            'two_factor' => false,
            'data' => self::user_payload($user),
        ]);
    }

    public static function send_cors_headers(mixed $served, WP_HTTP_Response $result, WP_REST_Request $request, WP_REST_Server $server): mixed
    {
        $origin = get_http_origin();
        if (self::is_allowed_origin($origin)) {
            header('Access-Control-Allow-Origin: ' . $origin);
            header('Access-Control-Allow-Credentials: true');
            header('Access-Control-Allow-Headers: Authorization, Content-Type, X-TCG-CSRF');
            header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
            header('Vary: Origin', false);
        }

        return $served;
    }

    public static function configure_mailer(PHPMailer\PHPMailer\PHPMailer $phpmailer): void
    {
        $host = getenv('WP_MAIL_SMTP_HOST') ?: '';
        if ($host === '') {
            return;
        }

        $phpmailer->isSMTP();
        $phpmailer->Host = $host;
        $phpmailer->Port = (int) (getenv('WP_MAIL_SMTP_PORT') ?: 1025);
        $phpmailer->SMTPAuth = false;

        $from = getenv('WP_MAIL_FROM') ?: '';
        if ($from !== '') {
            $phpmailer->setFrom($from, getenv('WP_MAIL_FROM_NAME') ?: get_bloginfo('name'));
        }
    }

    public static function mail_from(string $from): string
    {
        return getenv('WP_MAIL_FROM') ?: $from;
    }

    public static function mail_from_name(string $name): string
    {
        return getenv('WP_MAIL_FROM_NAME') ?: $name;
    }

    public static function cli_two_factor_reset(array $args): void
    {
        $login = $args[0] ?? '';
        $user = is_numeric($login) ? get_user_by('id', (int) $login) : get_user_by('login', $login);

        if (! $user instanceof WP_User && is_email($login)) {
            $user = get_user_by('email', $login);
        }

        if (! $user instanceof WP_User) {
            WP_CLI::error('User not found.');
        }

        delete_user_meta($user->ID, self::TWO_FACTOR_SECRET_META);
        delete_user_meta($user->ID, self::TWO_FACTOR_PENDING_SECRET_META);
        delete_user_meta($user->ID, self::TWO_FACTOR_ENABLED_META);
        delete_user_meta($user->ID, self::TWO_FACTOR_RECOVERY_CODES_META);

        WP_CLI::success("Two-factor authentication reset for user {$user->user_login}.");
    }

    public static function require_auth(WP_REST_Request $request): true|WP_Error
    {
        $auth = self::authenticate_request($request);

        if (is_wp_error($auth)) {
            return $auth;
        }

        return self::validate_state_change($request, $auth);
    }

    public static function require_admin(WP_REST_Request $request): true|WP_Error
    {
        $auth = self::authenticate_request($request);
        if (is_wp_error($auth)) {
            return $auth;
        }

        if (! user_can($auth['user'], 'manage_options')) {
            return self::error('tcg_admin_forbidden', 'Administrator permissions are required.', 403);
        }

        return self::validate_state_change($request, $auth);
    }

    private static function authenticate_request(WP_REST_Request $request): array|WP_Error
    {
        global $wpdb;

        $token = self::request_token($request);
        if ($token === '') {
            return self::error('tcg_missing_token', 'Authentication token is required.', 401);
        }

        $token_hash = self::hash_token($token);
        $row = $wpdb->get_row($wpdb->prepare(
            'SELECT * FROM ' . self::tokens_table() . ' WHERE token_hash = %s AND revoked_at IS NULL AND expires_at > UTC_TIMESTAMP() LIMIT 1',
            $token_hash
        ));

        if (! $row) {
            return self::error('tcg_invalid_token', 'Authentication token is invalid or expired.', 401);
        }

        $user = get_user_by('id', (int) $row->user_id);
        if (! $user instanceof WP_User) {
            return self::error('tcg_invalid_token_user', 'Authentication token is invalid.', 401);
        }

        if (self::should_touch_token($row)) {
            $wpdb->update(
                self::tokens_table(),
                [
                    'last_used_at' => self::now(),
                    'ip_hash' => self::hash_context(self::client_ip()),
                    'user_agent_hash' => self::hash_context(self::user_agent()),
                ],
                ['id' => (int) $row->id],
                ['%s', '%s', '%s'],
                ['%d']
            );
        }

        wp_set_current_user((int) $user->ID);
        self::maybe_refresh_csrf_cookie($request, (string) $row->token_hash);

        return [
            'user' => $user,
            'token_row' => $row,
        ];
    }

    private static function issue_token(int $user_id, string $device_name): string
    {
        global $wpdb;

        if (self::REVOKE_SAME_DEVICE_SESSIONS) {
            self::revoke_device_tokens($user_id, $device_name);
        }

        $token = self::random_token();
        $created_at = self::now();
        $expires_at = gmdate('Y-m-d H:i:s', time() + self::TOKEN_TTL);

        $wpdb->insert(
            self::tokens_table(),
            [
                'user_id' => $user_id,
                'token_hash' => self::hash_token($token),
                'device_name' => $device_name,
                'ip_hash' => self::hash_context(self::client_ip()),
                'user_agent_hash' => self::hash_context(self::user_agent()),
                'created_at' => $created_at,
                'expires_at' => $expires_at,
            ],
            ['%d', '%s', '%s', '%s', '%s', '%s', '%s']
        );

        return $token;
    }

    private static function revoke_device_tokens(int $user_id, string $device_name): void
    {
        global $wpdb;

        $wpdb->query($wpdb->prepare(
            'UPDATE ' . self::tokens_table() . ' SET revoked_at = %s WHERE user_id = %d AND device_name = %s AND revoked_at IS NULL',
            self::now(),
            $user_id,
            $device_name
        ));
    }

    private static function revoke_user_tokens_except(int $user_id, int $token_id): void
    {
        global $wpdb;

        $wpdb->query($wpdb->prepare(
            'UPDATE ' . self::tokens_table() . ' SET revoked_at = %s WHERE user_id = %d AND id != %d AND revoked_at IS NULL',
            self::now(),
            $user_id,
            $token_id
        ));
    }

    private static function user_payload(WP_User $user): array
    {
        return [
            'id' => (int) $user->ID,
            'email' => $user->user_email,
            'first_name' => (string) get_user_meta($user->ID, 'first_name', true),
            'last_name' => (string) get_user_meta($user->ID, 'last_name', true),
            'display_name' => $user->display_name,
            'enabled' => true,
            'is_verified' => self::is_email_verified((int) $user->ID),
            'is_admin' => user_can($user, 'manage_options'),
            'is_shop_manager' => user_can($user, 'manage_woocommerce') || user_can($user, 'edit_products'),
            'can_access_backoffice' => user_can($user, 'manage_options') || user_can($user, 'manage_woocommerce') || user_can($user, 'edit_products'),
            'is_superadmin' => is_multisite() ? is_super_admin($user->ID) : false,
            'avatar_url' => get_avatar_url($user->ID),
            'created_at' => mysql_to_rfc3339($user->user_registered),
            'two_factor_enabled' => self::is_two_factor_enabled((int) $user->ID),
        ];
    }

    private static function validate_password(string $password): null|WP_Error
    {
        if (strlen($password) < 12) {
            return self::error('tcg_password_too_short', 'Password must contain at least 12 characters.', 422);
        }

        if (! preg_match('/[a-z]/', $password) || ! preg_match('/[A-Z]/', $password) || ! preg_match('/\d/', $password)) {
            return self::error('tcg_password_weak', 'Password must include uppercase, lowercase and number characters.', 422);
        }

        return null;
    }

    private static function register_args(): array
    {
        return [
            'email' => [
                'required' => true,
                'type' => 'string',
                'format' => 'email',
                'sanitize_callback' => 'sanitize_email',
            ],
            'password' => [
                'required' => true,
                'type' => 'string',
            ],
            'password_confirmation' => [
                'required' => true,
                'type' => 'string',
            ],
            'first_name' => [
                'required' => false,
                'type' => 'string',
                'sanitize_callback' => 'sanitize_text_field',
            ],
            'last_name' => [
                'required' => false,
                'type' => 'string',
                'sanitize_callback' => 'sanitize_text_field',
            ],
            'device_name' => [
                'required' => false,
                'type' => 'string',
                'sanitize_callback' => 'sanitize_text_field',
            ],
            'website' => [
                'required' => false,
                'type' => 'string',
                'sanitize_callback' => 'sanitize_text_field',
            ],
        ];
    }

    private static function login_args(): array
    {
        return [
            'email' => [
                'required' => true,
                'type' => 'string',
                'format' => 'email',
                'sanitize_callback' => 'sanitize_email',
            ],
            'password' => [
                'required' => true,
                'type' => 'string',
            ],
            'device_name' => [
                'required' => false,
                'type' => 'string',
                'sanitize_callback' => 'sanitize_text_field',
            ],
        ];
    }

    private static function random_token(): string
    {
        return rtrim(strtr(base64_encode(random_bytes(32)), '+/', '-_'), '=');
    }

    private static function hash_token(string $token): string
    {
        return hash_hmac('sha256', $token, wp_salt('auth'));
    }

    private static function hash_context(string $value): string
    {
        return $value === '' ? '' : hash_hmac('sha256', $value, wp_salt('nonce'));
    }

    private static function bearer_token(WP_REST_Request $request): string
    {
        $header = $request->get_header('authorization');
        if (! is_string($header) || ! preg_match('/^Bearer\s+(.+)$/i', $header, $matches)) {
            return '';
        }

        return trim($matches[1]);
    }

    private static function request_token(WP_REST_Request $request): string
    {
        $bearer = self::bearer_token($request);
        if ($bearer !== '') {
            return $bearer;
        }

        $cookie = $_COOKIE[self::SESSION_COOKIE] ?? '';

        return is_string($cookie) ? trim($cookie) : '';
    }

    private static function should_touch_token(object $row): bool
    {
        if (empty($row->last_used_at)) {
            return true;
        }

        $last_used_at = strtotime((string) $row->last_used_at);

        return $last_used_at === false || $last_used_at < (time() - MINUTE_IN_SECONDS);
    }

    private static function device_name(WP_REST_Request $request): string
    {
        return substr(sanitize_text_field((string) $request->get_param('device_name')), 0, 191) ?: 'unknown';
    }

    private static function send_session_cookie(string $token): void
    {
        if (headers_sent()) {
            return;
        }

        $secure = is_ssl();
        setcookie(self::SESSION_COOKIE, $token, [
            'expires' => time() + self::TOKEN_TTL,
            'path' => '/',
            'secure' => $secure,
            'httponly' => true,
            'samesite' => 'Lax',
        ]);
        self::send_csrf_cookie_for_hash(self::hash_token($token), $secure);
    }

    private static function clear_session_cookie(): void
    {
        if (headers_sent()) {
            return;
        }

        $secure = is_ssl();
        setcookie(self::SESSION_COOKIE, '', [
            'expires' => time() - HOUR_IN_SECONDS,
            'path' => '/',
            'secure' => $secure,
            'httponly' => true,
            'samesite' => 'Lax',
        ]);
        setcookie(self::CSRF_COOKIE, '', [
            'expires' => time() - HOUR_IN_SECONDS,
            'path' => '/',
            'secure' => $secure,
            'httponly' => false,
            'samesite' => 'Lax',
        ]);
    }

    private static function validate_state_change(WP_REST_Request $request, array $auth): true|WP_Error
    {
        if (in_array($request->get_method(), ['GET', 'HEAD', 'OPTIONS'], true)) {
            return true;
        }

        if (self::bearer_token($request) !== '') {
            return true;
        }

        $header = trim((string) $request->get_header(self::CSRF_HEADER));
        $cookie = isset($_COOKIE[self::CSRF_COOKIE]) && is_string($_COOKIE[self::CSRF_COOKIE])
            ? trim(wp_unslash($_COOKIE[self::CSRF_COOKIE]))
            : '';

        if ($header === '' || $cookie === '') {
            return self::error('tcg_csrf_missing', 'CSRF token is required.', 403);
        }

        $parts = explode(':', $cookie, 2);
        if (count($parts) !== 2) {
            return self::error('tcg_csrf_invalid', 'CSRF token is invalid.', 403);
        }

        [$raw, $signature] = $parts;
        if (! hash_equals($raw, $header)) {
            return self::error('tcg_csrf_mismatch', 'CSRF token does not match.', 403);
        }

        $expected = self::csrf_signature($raw, (string) $auth['token_row']->token_hash);

        return hash_equals($expected, $signature)
            ? true
            : self::error('tcg_csrf_invalid', 'CSRF token is invalid.', 403);
    }

    private static function maybe_refresh_csrf_cookie(WP_REST_Request $request, string $token_hash): void
    {
        if (self::bearer_token($request) !== '' || headers_sent()) {
            return;
        }

        $cookie = isset($_COOKIE[self::CSRF_COOKIE]) && is_string($_COOKIE[self::CSRF_COOKIE])
            ? trim(wp_unslash($_COOKIE[self::CSRF_COOKIE]))
            : '';
        $parts = explode(':', $cookie, 2);

        if (count($parts) === 2 && hash_equals(self::csrf_signature($parts[0], $token_hash), $parts[1])) {
            return;
        }

        self::send_csrf_cookie_for_hash($token_hash, is_ssl());
    }

    private static function send_csrf_cookie_for_hash(string $token_hash, bool $secure): void
    {
        $raw = self::random_token();
        $value = $raw . ':' . self::csrf_signature($raw, $token_hash);

        setcookie(self::CSRF_COOKIE, $value, [
            'expires' => time() + self::TOKEN_TTL,
            'path' => '/',
            'secure' => $secure,
            'httponly' => false,
            'samesite' => 'Lax',
        ]);
    }

    private static function csrf_signature(string $raw, string $token_hash): string
    {
        return hash_hmac('sha256', $raw . '|' . $token_hash, wp_salt('nonce'));
    }

    private static function is_allowed_origin(string|null $origin): bool
    {
        if (! $origin) {
            return false;
        }

        $allowed = [
            home_url(),
            'http://localhost:4321',
            'http://127.0.0.1:4321',
        ];

        return in_array(untrailingslashit($origin), array_map('untrailingslashit', $allowed), true);
    }

    private static function username_from_email(string $email): string
    {
        $base = sanitize_user((string) strstr($email, '@', true), true) ?: 'user';
        $username = $base;
        $index = 1;

        while (username_exists($username)) {
            $username = $base . $index;
            $index++;
        }

        return $username;
    }

    private static function rate_key(string $email): string
    {
        return 'tcg_login_' . md5(strtolower($email) . '|' . self::client_ip());
    }

    private static function action_rate_key(string $action, string $subject): string
    {
        return 'tcg_' . sanitize_key($action) . '_' . md5(strtolower($subject) . '|' . self::client_ip());
    }

    private static function is_rate_limited(string $key, int $limit = self::LOGIN_LIMIT): bool
    {
        $attempts = (int) get_transient($key);

        return $attempts >= $limit;
    }

    private static function increment_rate_limit(string $key, int $window = self::LOGIN_WINDOW): void
    {
        $attempts = (int) get_transient($key);
        set_transient($key, $attempts + 1, $window);
    }

    private static function is_two_factor_enabled(int $user_id): bool
    {
        return get_user_meta($user_id, self::TWO_FACTOR_ENABLED_META, true) === '1'
            && self::user_totp_secret($user_id) !== '';
    }

    private static function is_email_verified(int $user_id): bool
    {
        return get_user_meta($user_id, self::EMAIL_VERIFIED_META, true) === '1';
    }

    private static function send_email_verification(int $user_id): void
    {
        $user = get_user_by('id', $user_id);
        if (! $user instanceof WP_User) {
            return;
        }

        $token = self::issue_user_short_token($user_id, self::EMAIL_VERIFICATION_TOKEN_META, self::EMAIL_VERIFICATION_EXPIRES_META);
        $url = self::frontend_url('/verificar-email', [
            'email' => $user->user_email,
            'token' => $token,
        ]);

        wp_mail($user->user_email, 'Verifica tu email', "Puedes verificar tu email aqui:\n\n{$url}");
    }

    private static function issue_user_short_token(int $user_id, string $token_meta, string $expires_meta): string
    {
        $token = self::random_token();
        update_user_meta($user_id, $token_meta, self::hash_token($token));
        update_user_meta($user_id, $expires_meta, (string) (time() + self::SHORT_TOKEN_TTL));

        return $token;
    }

    private static function verify_user_short_token(int $user_id, string $token, string $token_meta, string $expires_meta): bool
    {
        $stored_hash = (string) get_user_meta($user_id, $token_meta, true);
        $expires = (int) get_user_meta($user_id, $expires_meta, true);

        return $token !== ''
            && $stored_hash !== ''
            && $expires >= time()
            && hash_equals($stored_hash, self::hash_token($token));
    }

    private static function sanitize_short_token(string $token): string
    {
        return substr(preg_replace('/[^A-Za-z0-9\-_]/', '', $token) ?? '', 0, 200);
    }

    private static function frontend_url(string $path, array $query = []): string
    {
        $base = getenv('PUBLIC_FRONTEND_URL') ?: 'http://localhost:4321';

        return add_query_arg($query, rtrim($base, '/') . '/' . ltrim($path, '/'));
    }

    private static function issue_two_factor_challenge(int $user_id, string $device_name): string
    {
        $challenge_token = self::random_token();
        set_transient(self::two_factor_challenge_key($challenge_token), [
            'user_id' => $user_id,
            'device_name' => $device_name,
            'ip_hash' => self::hash_context(self::client_ip()),
            'user_agent_hash' => self::hash_context(self::user_agent()),
        ], self::TWO_FACTOR_CHALLENGE_TTL);

        return $challenge_token;
    }

    private static function read_two_factor_challenge(string $challenge_token): array|null
    {
        if ($challenge_token === '') {
            return null;
        }

        $challenge = get_transient(self::two_factor_challenge_key($challenge_token));

        return is_array($challenge) ? $challenge : null;
    }

    private static function two_factor_challenge_key(string $challenge_token): string
    {
        return 'tcg_2fa_challenge_' . md5($challenge_token);
    }

    private static function user_totp_secret(int $user_id): string
    {
        return self::decrypt_secret((string) get_user_meta($user_id, self::TWO_FACTOR_SECRET_META, true));
    }

    private static function generate_totp_secret(): string
    {
        return self::base32_encode(random_bytes(20));
    }

    private static function totp_uri(WP_User $user, string $secret): string
    {
        $label = rawurlencode(self::TWO_FACTOR_ISSUER . ':' . $user->user_email);

        return sprintf(
            'otpauth://totp/%s?secret=%s&issuer=%s&algorithm=SHA1&digits=6&period=30',
            $label,
            $secret,
            rawurlencode(self::TWO_FACTOR_ISSUER)
        );
    }

    private static function verify_totp(string $secret, string $code): bool
    {
        if ($secret === '' || ! preg_match('/^\d{6}$/', $code)) {
            return false;
        }

        $time_slice = (int) floor(time() / 30);

        for ($offset = -1; $offset <= 1; $offset++) {
            if (hash_equals(self::totp_code($secret, $time_slice + $offset), $code)) {
                return true;
            }
        }

        return false;
    }

    private static function verify_two_factor_code(int $user_id, string $code): bool
    {
        $code = self::sanitize_totp_code($code);
        if (self::verify_totp(self::user_totp_secret($user_id), $code)) {
            return true;
        }

        return self::consume_recovery_code($user_id, $code);
    }

    private static function generate_recovery_codes(): array
    {
        $codes = [];

        for ($index = 0; $index < 8; $index++) {
            $codes[] = self::format_recovery_code(strtoupper(bin2hex(random_bytes(4))));
        }

        return $codes;
    }

    private static function format_recovery_code(string $code): string
    {
        return substr($code, 0, 4) . '-' . substr($code, 4, 4);
    }

    private static function hash_recovery_codes(array $codes): array
    {
        return array_map(static fn (string $code): string => self::hash_context(self::normalize_recovery_code($code)), $codes);
    }

    private static function consume_recovery_code(int $user_id, string $code): bool
    {
        $normalized = self::normalize_recovery_code($code);
        $hash = self::hash_context($normalized);
        $hashes = get_user_meta($user_id, self::TWO_FACTOR_RECOVERY_CODES_META, true);

        if (! is_array($hashes)) {
            return false;
        }

        foreach ($hashes as $index => $stored_hash) {
            if (is_string($stored_hash) && hash_equals($stored_hash, $hash)) {
                unset($hashes[$index]);
                update_user_meta($user_id, self::TWO_FACTOR_RECOVERY_CODES_META, array_values($hashes));

                return true;
            }
        }

        return false;
    }

    private static function normalize_recovery_code(string $code): string
    {
        return strtoupper(preg_replace('/[^A-F0-9]/', '', $code) ?? '');
    }

    private static function totp_code(string $secret, int $time_slice): string
    {
        $secret_key = self::base32_decode($secret);
        $time = pack('N*', 0) . pack('N*', $time_slice);
        $hash = hash_hmac('sha1', $time, $secret_key, true);
        $offset = ord(substr($hash, -1)) & 0x0F;
        $value = unpack('N', substr($hash, $offset, 4))[1] & 0x7FFFFFFF;

        return str_pad((string) ($value % 1000000), 6, '0', STR_PAD_LEFT);
    }

    private static function base32_encode(string $value): string
    {
        $alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
        $bits = '';
        $encoded = '';

        foreach (str_split($value) as $char) {
            $bits .= str_pad(decbin(ord($char)), 8, '0', STR_PAD_LEFT);
        }

        foreach (str_split($bits, 5) as $chunk) {
            if (strlen($chunk) < 5) {
                $chunk = str_pad($chunk, 5, '0', STR_PAD_RIGHT);
            }

            $encoded .= $alphabet[bindec($chunk)];
        }

        return $encoded;
    }

    private static function base32_decode(string $value): string
    {
        $alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
        $value = strtoupper(preg_replace('/[^A-Z2-7]/', '', $value) ?? '');
        $bits = '';
        $decoded = '';

        foreach (str_split($value) as $char) {
            $index = strpos($alphabet, $char);
            if ($index === false) {
                continue;
            }

            $bits .= str_pad(decbin($index), 5, '0', STR_PAD_LEFT);
        }

        foreach (str_split($bits, 8) as $byte) {
            if (strlen($byte) === 8) {
                $decoded .= chr(bindec($byte));
            }
        }

        return $decoded;
    }

    private static function encrypt_secret(string $secret): string
    {
        if ($secret === '' || ! function_exists('openssl_encrypt')) {
            return $secret;
        }

        $iv = random_bytes(16);
        $key = hash('sha256', wp_salt('auth'), true);
        $ciphertext = openssl_encrypt($secret, 'aes-256-cbc', $key, OPENSSL_RAW_DATA, $iv);

        return $ciphertext === false ? $secret : base64_encode($iv . $ciphertext);
    }

    private static function decrypt_secret(string $payload): string
    {
        if ($payload === '' || ! function_exists('openssl_decrypt')) {
            return $payload;
        }

        $decoded = base64_decode($payload, true);
        if ($decoded === false || strlen($decoded) <= 16) {
            return $payload;
        }

        $iv = substr($decoded, 0, 16);
        $ciphertext = substr($decoded, 16);
        $key = hash('sha256', wp_salt('auth'), true);
        $secret = openssl_decrypt($ciphertext, 'aes-256-cbc', $key, OPENSSL_RAW_DATA, $iv);

        return is_string($secret) ? $secret : '';
    }

    private static function sanitize_totp_code(string $code): string
    {
        $digits = substr(preg_replace('/\D+/', '', $code) ?? '', 0, 6);

        return $digits !== '' ? $digits : self::normalize_recovery_code($code);
    }

    private static function sanitize_challenge_token(string $token): string
    {
        return substr(preg_replace('/[^A-Za-z0-9\-_]/', '', $token) ?? '', 0, 200);
    }

    private static function client_ip(): string
    {
        $ip = $_SERVER['REMOTE_ADDR'] ?? '';

        return is_string($ip) ? sanitize_text_field($ip) : '';
    }

    private static function user_agent(): string
    {
        $user_agent = $_SERVER['HTTP_USER_AGENT'] ?? '';

        return is_string($user_agent) ? substr(sanitize_text_field($user_agent), 0, 500) : '';
    }

    public static function now(): string
    {
        return current_time('mysql', true);
    }

    private static function tokens_table(): string
    {
        global $wpdb;

        return $wpdb->prefix . 'tcg_api_tokens';
    }

    private static function wordpress_tables_exist(): bool
    {
        global $wpdb, $table_prefix;

        $table = esc_sql($table_prefix . 'options');
        $result = $wpdb->get_var($wpdb->prepare('SHOW TABLES LIKE %s', $table));

        return $result === $table;
    }

    private static function error(string $code, string $message, int $status): WP_Error
    {
        return new WP_Error($code, $message, ['status' => $status]);
    }
}

TCG_Platform_API::boot();
