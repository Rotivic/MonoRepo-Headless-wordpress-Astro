<?php

$users = [
    [
        'user_login' => 'cliente_demo',
        'user_email' => 'cliente.demo@example.test',
        'user_pass' => 'PasswordDemo123!',
        'first_name' => 'Cliente',
        'last_name' => 'Demo',
        'role' => 'subscriber',
    ],
];

foreach ($users as $data) {
    if (username_exists($data['user_login']) || email_exists($data['user_email'])) {
        WP_CLI::log("Skipped existing user: {$data['user_login']}");
        continue;
    }

    $user_id = wp_insert_user($data);

    if (is_wp_error($user_id)) {
        WP_CLI::warning($user_id->get_error_message());
        continue;
    }

    WP_CLI::success("Created user: {$data['user_login']}");
}
