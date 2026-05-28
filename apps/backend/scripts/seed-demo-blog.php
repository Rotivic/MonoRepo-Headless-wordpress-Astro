<?php

$posts = [
    [
        'post_title' => 'Primer articulo demo',
        'post_name' => 'primer-articulo-demo',
        'post_excerpt' => 'Articulo de ejemplo para validar un proyecto tipo blog headless.',
        'post_content' => 'Contenido demo creado por el starter kit. Puedes editarlo desde WordPress o sustituirlo por contenido real.',
    ],
    [
        'post_title' => 'Guia de catalogo demo',
        'post_name' => 'guia-catalogo-demo',
        'post_excerpt' => 'Entrada pensada para probar listados de contenido y consumo REST.',
        'post_content' => 'Esta entrada sirve como contenido semilla para vistas de blog, noticias o documentacion.',
    ],
];

foreach ($posts as $data) {
    $existing = get_page_by_path($data['post_name'], OBJECT, 'post');

    if ($existing) {
        WP_CLI::log("Skipped existing post: {$data['post_title']}");
        continue;
    }

    $post_id = wp_insert_post([
        'post_type' => 'post',
        'post_status' => 'publish',
        'post_title' => $data['post_title'],
        'post_name' => $data['post_name'],
        'post_excerpt' => $data['post_excerpt'],
        'post_content' => $data['post_content'],
    ], true);

    if (is_wp_error($post_id)) {
        WP_CLI::warning($post_id->get_error_message());
        continue;
    }

    WP_CLI::success("Created post: {$data['post_title']}");
}
