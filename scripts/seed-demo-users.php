<?php
/**
 * Seed: usuarios demo (admin_demo, vendedor_demo, cliente_demo).
 * Ejecutar con: wp eval-file scripts/seed-demo-users.php --allow-root
 */

$demo_password = 'PasswordDemo123!';

$users = [
    [
        'user_login'   => 'admin_demo',
        'user_email'   => 'admin.demo@example.test',
        'user_pass'    => $demo_password,
        'role'         => 'administrator',
        'display_name' => 'Admin Demo',
        'first_name'   => 'Admin',
        'last_name'    => 'Demo',
    ],
    [
        'user_login'   => 'vendedor_demo',
        'user_email'   => 'vendedor.demo@example.test',
        'user_pass'    => $demo_password,
        'role'         => 'shop_manager',
        'display_name' => 'Vendedor Demo',
        'first_name'   => 'Vendedor',
        'last_name'    => 'Demo',
    ],
    [
        'user_login'   => 'cliente_demo',
        'user_email'   => 'cliente.demo@example.test',
        'user_pass'    => $demo_password,
        'role'         => 'customer',
        'display_name' => 'Cliente Demo',
        'first_name'   => 'Cliente',
        'last_name'    => 'Demo',
    ],
];

foreach ( $users as $data ) {
    $existing = get_user_by( 'login', $data['user_login'] );
    if ( $existing ) {
        WP_CLI::log( "  · {$data['user_login']} ya existe, omitiendo." );
        continue;
    }

    $id = wp_insert_user( $data );

    if ( is_wp_error( $id ) ) {
        WP_CLI::warning( "Error creando {$data['user_login']}: " . $id->get_error_message() );
    } else {
        WP_CLI::success( "Usuario {$data['user_login']} ({$data['role']}) creado — ID {$id}." );
    }
}
