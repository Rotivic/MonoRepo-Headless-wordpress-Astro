<?php

if (! class_exists('WC_Product_Simple')) {
    WP_CLI::error('WooCommerce is not active.');
}

$products = [
    [
        'name' => 'Caja de sobres demo',
        'slug' => 'caja-sobres-demo',
        'price' => '49.90',
        'description' => 'Producto demo para validar catalogo, carrito local y consumo desde Astro.',
    ],
    [
        'name' => 'Carta individual demo',
        'slug' => 'carta-individual-demo',
        'price' => '7.50',
        'description' => 'Ficha base para probar productos simples dentro de WooCommerce.',
    ],
    [
        'name' => 'Pack coleccionista demo',
        'slug' => 'pack-coleccionista-demo',
        'price' => '89.00',
        'description' => 'Articulo de ejemplo para maquetar landings, tienda o catalogos sin checkout.',
    ],
];

foreach ($products as $data) {
    $existing = get_page_by_path($data['slug'], OBJECT, 'product');

    if ($existing) {
        WP_CLI::log("Skipped existing product: {$data['name']}");
        continue;
    }

    $product = new WC_Product_Simple();
    $product->set_name($data['name']);
    $product->set_slug($data['slug']);
    $product->set_regular_price($data['price']);
    $product->set_description($data['description']);
    $product->set_short_description($data['description']);
    $product->set_catalog_visibility('visible');
    $product->set_status('publish');
    $product->set_manage_stock(false);
    $product->set_stock_status('instock');
    $product->save();

    WP_CLI::success("Created product: {$data['name']}");
}
