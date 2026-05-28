<?php
/**
 * Seed: productos TCG demo en WooCommerce.
 * Ejecutar con: wp eval-file scripts/seed-demo-products.php --allow-root
 */

if ( ! class_exists( 'WooCommerce' ) ) {
    WP_CLI::warning( 'WooCommerce no está activo. Omitiendo seed de productos.' );
    return;
}

$products = [
    [
        'name'              => 'Dragón de Fuego — Holo Rare',
        'price'             => '12.99',
        'stock'             => 15,
        'short_description' => 'Carta holográfica rara. Alta velocidad de ataque y resistencia al fuego.',
        'description'       => 'El Dragón de Fuego es una de las cartas más codiciadas del set de lanzamiento. Su efecto especial permite destruir una carta del oponente al ser invocado. Versión holo con acabado premium.',
        'category'          => 'Cartas Raras',
        'sku'               => 'TCG-DR-HOLO-001',
    ],
    [
        'name'              => 'Guerrero de Hielo — Uncommon',
        'price'             => '3.49',
        'stock'             => 40,
        'short_description' => 'Carta de tipo guerrero con habilidad de congelar al enemigo durante un turno.',
        'description'       => 'El Guerrero de Hielo es una pieza de apoyo versátil. Su habilidad de congelación puede cambiar el rumbo de una partida. Ideal para mazos de control.',
        'category'          => 'Cartas Uncommon',
        'sku'               => 'TCG-GH-UNCO-002',
    ],
    [
        'name'              => 'Hechicero de las Sombras — Rare',
        'price'             => '7.99',
        'stock'             => 20,
        'short_description' => 'Carta mágica que duplica el efecto del siguiente hechizo jugado.',
        'description'       => 'El Hechicero de las Sombras potencia cualquier mazo centrado en hechizos. Rara vez aparece en sobres estándar. Muy valorada en torneos.',
        'category'          => 'Cartas Raras',
        'sku'               => 'TCG-HS-RARE-003',
    ],
    [
        'name'              => 'Espíritu del Bosque — Common',
        'price'             => '0.99',
        'stock'             => 100,
        'short_description' => 'Carta básica de soporte con regeneración de puntos de vida.',
        'description'       => 'Una de las cartas más accesibles del juego. Su capacidad de regeneración la convierte en una inclusión frecuente en mazos de resistencia.',
        'category'          => 'Cartas Common',
        'sku'               => 'TCG-EB-COMM-004',
    ],
    [
        'name'              => 'Roca Elemental — Common',
        'price'             => '0.75',
        'stock'             => 120,
        'short_description' => 'Criatura de tierra con alta defensa. Bloquea ataques durante 2 turnos.',
        'description'       => 'La Roca Elemental es esencial para estrategias defensivas. Con 8 puntos de defensa base, resiste la mayoría de ataques directos del juego básico.',
        'category'          => 'Cartas Common',
        'sku'               => 'TCG-RE-COMM-005',
    ],
    [
        'name'              => 'Sobre Iniciación TCG — 10 cartas',
        'price'             => '4.99',
        'stock'             => 50,
        'short_description' => 'Sobre sellado con 10 cartas aleatorias. Incluye al menos 1 carta Uncommon.',
        'description'       => 'El sobre de iniciación es el punto de entrada perfecto para nuevos jugadores. Contiene 10 cartas aleatorias del set base, con garantía de al menos 1 Uncommon y posibilidad de obtener Rares o Holos.',
        'category'          => 'Sobres',
        'sku'               => 'TCG-SOBRE-INIT-001',
    ],
];

// Obtener o crear categorías
function tcg_get_or_create_category( string $name ): int {
    $term = get_term_by( 'name', $name, 'product_cat' );
    if ( $term ) {
        return (int) $term->term_id;
    }
    $result = wp_insert_term( $name, 'product_cat' );
    if ( is_wp_error( $result ) ) {
        return 0;
    }
    return (int) $result['term_id'];
}

$created = 0;
$skipped = 0;

foreach ( $products as $data ) {
    // Comprobar si ya existe por SKU
    $existing_id = wc_get_product_id_by_sku( $data['sku'] );
    if ( $existing_id ) {
        WP_CLI::log( "  · {$data['name']} ya existe (SKU {$data['sku']}), omitiendo." );
        $skipped++;
        continue;
    }

    $cat_id = tcg_get_or_create_category( $data['category'] );

    $product = new WC_Product_Simple();
    $product->set_name( $data['name'] );
    $product->set_status( 'publish' );
    $product->set_catalog_visibility( 'visible' );
    $product->set_description( $data['description'] );
    $product->set_short_description( $data['short_description'] );
    $product->set_sku( $data['sku'] );
    $product->set_regular_price( $data['price'] );
    $product->set_price( $data['price'] );
    $product->set_manage_stock( true );
    $product->set_stock_quantity( $data['stock'] );
    $product->set_stock_status( 'instock' );

    if ( $cat_id ) {
        $product->set_category_ids( [ $cat_id ] );
    }

    $id = $product->save();

    if ( $id ) {
        WP_CLI::success( "Producto '{$data['name']}' creado — ID {$id}." );
        $created++;
    } else {
        WP_CLI::warning( "No se pudo crear '{$data['name']}'." );
    }
}

WP_CLI::log( "Productos: {$created} creados, {$skipped} ya existían." );
