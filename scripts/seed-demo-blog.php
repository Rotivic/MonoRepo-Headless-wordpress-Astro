<?php
/**
 * Seed: entradas de blog demo.
 * Ejecutar con: wp eval-file scripts/seed-demo-blog.php --allow-root
 */

$admin = get_user_by( 'login', 'admin' );
$author_id = $admin ? $admin->ID : 1;

$posts = [
    [
        'title'   => 'Bienvenido a TCG Platform',
        'slug'    => 'bienvenido-tcg-platform',
        'content' => '<p>TCG Platform es una plataforma para jugadores y coleccionistas de cartas. Aquí encontrarás los últimos lanzamientos, guías de estrategia y la tienda donde conseguir tus cartas favoritas.</p><p>Explora el catálogo de productos, construye tu mazo y conecta con la comunidad.</p>',
        'excerpt' => 'Descubre TCG Platform, la plataforma para jugadores y coleccionistas de cartas TCG.',
    ],
    [
        'title'   => 'Guía de iniciación: cómo construir tu primer mazo',
        'slug'    => 'guia-primer-mazo',
        'content' => '<p>Construir un mazo equilibrado es el primer paso para disfrutar del juego competitivo. Un mazo estándar consta de 40 cartas distribuidas entre criaturas, hechizos y cartas de soporte.</p><h2>Proporciones recomendadas para empezar</h2><ul><li>20 cartas de criatura</li><li>12 cartas de hechizo</li><li>8 cartas de soporte o trampa</li></ul><p>Empieza con cartas Common y Uncommon antes de incorporar Rares. La consistencia del mazo es más importante que la rareza de las cartas.</p>',
        'excerpt' => 'Aprende a construir tu primer mazo TCG con esta guía paso a paso para principiantes.',
    ],
    [
        'title'   => 'Novedades del set base: cartas destacadas',
        'slug'    => 'novedades-set-base',
        'content' => '<p>El set base de TCG Platform incluye más de 100 cartas únicas. Estas son las más destacadas de cada rareza:</p><h2>Holo Rare</h2><p>El <strong>Dragón de Fuego</strong> lidera el ranking de búsquedas. Su habilidad de destrucción al invocar lo convierte en una pieza clave para mazos agresivos.</p><h2>Rare</h2><p>El <strong>Hechicero de las Sombras</strong> está redefiniendo los mazos de control. Duplicar efectos de hechizo en el momento adecuado puede decidir una partida.</p><h2>Common y Uncommon</h2><p>No subestimes el <strong>Guerrero de Hielo</strong>. La congelación durante un turno completo es más poderosa de lo que parece en papel.</p>',
        'excerpt' => 'Repaso a las cartas más destacadas del set base: Dragón de Fuego, Hechicero de las Sombras y más.',
    ],
    [
        'title'   => 'Cómo funciona la tienda: comprar y vender cartas',
        'slug'    => 'como-funciona-la-tienda',
        'content' => '<p>La tienda de TCG Platform funciona como un marketplace donde compradores y vendedores pueden intercambiar cartas de forma segura.</p><h2>Para compradores</h2><p>Explora el catálogo, añade al carrito y completa el pago. Recibirás confirmación por email y seguimiento de tu pedido desde <em>Mis pedidos</em>.</p><h2>Para vendedores</h2><p>Los usuarios con rol Vendedor pueden gestionar su inventario desde el panel de control. Cada carta listada pasa por una revisión antes de publicarse.</p><p>Crea tu cuenta, verifica tu email y empieza a comprar o vender hoy mismo.</p>',
        'excerpt' => 'Aprende a comprar y vender cartas en TCG Platform de forma sencilla y segura.',
    ],
];

$created = 0;
$skipped = 0;

foreach ( $posts as $data ) {
    $existing = get_page_by_path( $data['slug'], OBJECT, 'post' );
    if ( $existing ) {
        WP_CLI::log( "  · '{$data['title']}' ya existe, omitiendo." );
        $skipped++;
        continue;
    }

    $id = wp_insert_post( [
        'post_title'   => $data['title'],
        'post_name'    => $data['slug'],
        'post_content' => $data['content'],
        'post_excerpt' => $data['excerpt'],
        'post_status'  => 'publish',
        'post_type'    => 'post',
        'post_author'  => $author_id,
    ], true );

    if ( is_wp_error( $id ) ) {
        WP_CLI::warning( "Error creando '{$data['title']}': " . $id->get_error_message() );
    } else {
        WP_CLI::success( "Entrada '{$data['title']}' creada — ID {$id}." );
        $created++;
    }
}

WP_CLI::log( "Blog: {$created} entradas creadas, {$skipped} ya existían." );
