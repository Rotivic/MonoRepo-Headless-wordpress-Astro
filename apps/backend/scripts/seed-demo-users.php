<?php

$users = [
    [
        'user_login' => 'admin_demo',
        'user_email' => 'admin.demo@example.test',
        'user_pass' => 'PasswordDemo123!',
        'first_name' => 'Admin',
        'last_name' => 'Demo',
        'role' => 'administrator',
    ],
    [
        'user_login' => 'vendedor_demo',
        'user_email' => 'vendedor.demo@example.test',
        'user_pass' => 'PasswordDemo123!',
        'first_name' => 'Vendedor',
        'last_name' => 'Demo',
        'role' => 'shop_manager',
    ],
    [
        'user_login' => 'cliente_demo',
        'user_email' => 'cliente.demo@example.test',
        'user_pass' => 'PasswordDemo123!',
        'first_name' => 'Cliente',
        'last_name' => 'Demo',
        'role' => 'customer',
    ],
];

foreach ($users as $data) {
    $existing_id = username_exists($data['user_login']) ?: email_exists($data['user_email']);

    if ($existing_id) {
        $user = new WP_User((int) $existing_id);
        $user->set_role($data['role']);
        update_user_meta((int) $existing_id, 'tcg_email_verified', '1');
        WP_CLI::log("Updated existing user role: {$data['user_login']} -> {$data['role']}");
        continue;
    }

    $user_id = wp_insert_user($data);

    if (is_wp_error($user_id)) {
        WP_CLI::warning($user_id->get_error_message());
        continue;
    }

    update_user_meta((int) $user_id, 'tcg_email_verified', '1');
    WP_CLI::success("Created user: {$data['user_login']} ({$data['role']})");
}
