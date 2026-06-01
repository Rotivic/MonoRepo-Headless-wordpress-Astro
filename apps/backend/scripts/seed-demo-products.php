<?php

if (! class_exists('WC_Product_Simple')) {
    WP_CLI::error('WooCommerce is not active.');
}

function tcg_demo_log(string $message): void
{
    WP_CLI::log($message);
}

function tcg_demo_term_id(string $taxonomy, string $name, string $slug = ''): int
{
    $term = $slug ? get_term_by('slug', $slug, $taxonomy) : get_term_by('name', $name, $taxonomy);

    if ($term && ! is_wp_error($term)) {
        return (int) $term->term_id;
    }

    $args = [];

    if ($slug !== '') {
        $args['slug'] = $slug;
    }

    $created = wp_insert_term($name, $taxonomy, $args);

    if (is_wp_error($created)) {
        $existing = $created->get_error_data('term_exists');

        return $existing ? (int) $existing : 0;
    }

    return (int) $created['term_id'];
}

function tcg_demo_term_slug(string $taxonomy, string $name): string
{
    $term = get_term_by('name', $name, $taxonomy);

    return $term && ! is_wp_error($term) ? $term->slug : sanitize_title($name);
}

function tcg_demo_ensure_attribute(string $slug, string $label, array $terms): string
{
    $slug = wc_sanitize_taxonomy_name($slug);
    $taxonomy = wc_attribute_taxonomy_name($slug);

    if (! wc_attribute_taxonomy_id_by_name($slug)) {
        wc_create_attribute([
            'name' => $label,
            'slug' => $slug,
            'type' => 'select',
            'order_by' => 'menu_order',
            'has_archives' => false,
        ]);

        delete_transient('wc_attribute_taxonomies');
    }

    if (! taxonomy_exists($taxonomy)) {
        register_taxonomy($taxonomy, ['product'], [
            'hierarchical' => false,
            'label' => $label,
            'query_var' => true,
            'rewrite' => false,
            'show_ui' => false,
        ]);
    }

    foreach ($terms as $term) {
        tcg_demo_term_id($taxonomy, $term);
    }

    return $taxonomy;
}

function tcg_demo_product_attribute(string $taxonomy, array $term_names, bool $visible = true, bool $variation = false, int $position = 0): WC_Product_Attribute
{
    $term_ids = array_values(array_filter(array_map(
        static fn (string $term): int => tcg_demo_term_id($taxonomy, $term),
        $term_names
    )));

    $attribute_slug = str_replace('pa_', '', $taxonomy);
    $attribute = new WC_Product_Attribute();
    $attribute->set_id((int) wc_attribute_taxonomy_id_by_name($attribute_slug));
    $attribute->set_name($taxonomy);
    $attribute->set_options($term_ids);
    $attribute->set_position($position);
    $attribute->set_visible($visible);
    $attribute->set_variation($variation);

    return $attribute;
}

function tcg_demo_assign_terms(int $product_id, array $names, string $taxonomy): array
{
    $term_ids = array_values(array_filter(array_map(
        static fn (string $name): int => tcg_demo_term_id($taxonomy, $name),
        $names
    )));

    if ($term_ids) {
        wp_set_object_terms($product_id, $term_ids, $taxonomy);
    }

    return $term_ids;
}

function tcg_demo_assign_brand(int $product_id, string $brand): void
{
    if (taxonomy_exists('product_brand')) {
        $brand_id = tcg_demo_term_id('product_brand', $brand);

        if ($brand_id) {
            wp_set_object_terms($product_id, [$brand_id], 'product_brand');
        }
    }
}

function tcg_demo_simple_product(array $data, array $taxonomies): int
{
    $existing_id = wc_get_product_id_by_sku($data['sku']);
    $product = $existing_id ? wc_get_product($existing_id) : new WC_Product_Simple();

    if (! $product instanceof WC_Product_Simple) {
        WP_CLI::warning("SKU {$data['sku']} exists but is not a simple product. Skipping.");

        return 0;
    }

    $product->set_name($data['name']);
    $product->set_slug($data['slug']);
    $product->set_status('publish');
    $product->set_catalog_visibility('visible');
    $product->set_featured(! empty($data['featured']));
    $product->set_description($data['description']);
    $product->set_short_description($data['short_description']);
    $product->set_sku($data['sku']);
    $product->set_regular_price((string) $data['regular_price']);
    $product->set_sale_price(isset($data['sale_price']) ? (string) $data['sale_price'] : '');
    $product->set_manage_stock(true);
    $product->set_stock_quantity((int) $data['stock']);
    $product->set_stock_status($data['stock_status'] ?? ((int) $data['stock'] > 0 ? 'instock' : 'outofstock'));
    $product->set_backorders($data['backorders'] ?? 'no');
    $product->set_category_ids(array_map(
        static fn (string $category): int => $taxonomies['categories'][$category] ?? 0,
        $data['categories']
    ));
    $product->set_tag_ids(array_map(
        static fn (string $tag): int => $taxonomies['tags'][$tag] ?? 0,
        $data['tags']
    ));

    $attributes = [
        tcg_demo_product_attribute($taxonomies['attributes']['marca'], [$data['brand']], true, false, 0),
        tcg_demo_product_attribute($taxonomies['attributes']['idioma'], [$data['language']], true, false, 1),
        tcg_demo_product_attribute($taxonomies['attributes']['condicion'], [$data['condition']], true, false, 2),
    ];

    $product->set_attributes($attributes);

    $id = $product->save();

    if (! empty($data['low_stock_amount'])) {
        update_post_meta($id, '_low_stock_amount', (int) $data['low_stock_amount']);
    }

    tcg_demo_assign_brand($id, $data['brand']);
    wc_delete_product_transients($id);

    tcg_demo_log(($existing_id ? 'Updated' : 'Created') . " simple product: {$data['name']}");

    return $id;
}

function tcg_demo_variation(int $parent_id, array $data, array $taxonomies): int
{
    $existing_id = wc_get_product_id_by_sku($data['sku']);
    $variation = $existing_id ? wc_get_product($existing_id) : new WC_Product_Variation();

    if (! $variation instanceof WC_Product_Variation) {
        WP_CLI::warning("SKU {$data['sku']} exists but is not a variation. Skipping.");

        return 0;
    }

    $variation->set_parent_id($parent_id);
    $variation->set_sku($data['sku']);
    $variation->set_regular_price((string) $data['regular_price']);
    $variation->set_sale_price(isset($data['sale_price']) ? (string) $data['sale_price'] : '');
    $variation->set_manage_stock(true);
    $variation->set_stock_quantity((int) $data['stock']);
    $variation->set_stock_status($data['stock_status'] ?? ((int) $data['stock'] > 0 ? 'instock' : 'outofstock'));
    $variation->set_backorders($data['backorders'] ?? 'no');

    $attributes = [];

    foreach ($data['attributes'] as $attribute_key => $term_name) {
        $taxonomy = $taxonomies['attributes'][$attribute_key];
        $attributes[$taxonomy] = tcg_demo_term_slug($taxonomy, $term_name);
    }

    $variation->set_attributes($attributes);
    $id = $variation->save();

    if (! empty($data['low_stock_amount'])) {
        update_post_meta($id, '_low_stock_amount', (int) $data['low_stock_amount']);
    }

    return $id;
}

function tcg_demo_variable_product(array $data, array $taxonomies): int
{
    $existing_id = wc_get_product_id_by_sku($data['sku']);
    $product = $existing_id ? wc_get_product($existing_id) : new WC_Product_Variable();

    if (! $product instanceof WC_Product_Variable) {
        WP_CLI::warning("SKU {$data['sku']} exists but is not a variable product. Skipping.");

        return 0;
    }

    $product->set_name($data['name']);
    $product->set_slug($data['slug']);
    $product->set_status('publish');
    $product->set_catalog_visibility('visible');
    $product->set_featured(! empty($data['featured']));
    $product->set_description($data['description']);
    $product->set_short_description($data['short_description']);
    $product->set_sku($data['sku']);
    $product->set_category_ids(array_map(
        static fn (string $category): int => $taxonomies['categories'][$category] ?? 0,
        $data['categories']
    ));
    $product->set_tag_ids(array_map(
        static fn (string $tag): int => $taxonomies['tags'][$tag] ?? 0,
        $data['tags']
    ));
    $product->set_manage_stock(false);
    $product->set_stock_status('instock');

    $attributes = [];
    $position = 0;

    foreach ($data['variation_attributes'] as $attribute_key => $terms) {
        $attributes[] = tcg_demo_product_attribute($taxonomies['attributes'][$attribute_key], $terms, true, true, $position);
        $position++;
    }

    $attributes[] = tcg_demo_product_attribute($taxonomies['attributes']['marca'], [$data['brand']], true, false, $position);
    $product->set_attributes($attributes);

    $id = $product->save();

    foreach ($data['variations'] as $variation) {
        tcg_demo_variation($id, $variation, $taxonomies);
    }

    tcg_demo_assign_brand($id, $data['brand']);
    WC_Product_Variable::sync($id);
    wc_delete_product_transients($id);

    tcg_demo_log(($existing_id ? 'Updated' : 'Created') . " variable product: {$data['name']}");

    return $id;
}

function tcg_demo_coupon(array $data): void
{
    $existing_id = wc_get_coupon_id_by_code($data['code']);
    $coupon = $existing_id ? new WC_Coupon($existing_id) : new WC_Coupon();

    $coupon->set_code($data['code']);
    $coupon->set_discount_type($data['discount_type']);
    $coupon->set_amount((string) $data['amount']);
    $coupon->set_description($data['description']);
    $coupon->set_individual_use(false);
    $coupon->set_usage_limit($data['usage_limit'] ?? 0);
    $coupon->save();

    tcg_demo_log(($existing_id ? 'Updated' : 'Created') . " coupon: {$data['code']}");
}

$categories = [
    'Sobres',
    'Cartas individuales',
    'Accesorios',
    'Sellado',
    'Coleccionista',
    'Preventa',
];

$tags = [
    'Destacado',
    'Rebajas',
    'Bajo stock',
    'Sin stock',
    'Nuevo',
    'Premium',
    'Bundle',
    'Variable',
];

$taxonomies = [
    'categories' => [],
    'tags' => [],
    'attributes' => [
        'marca' => tcg_demo_ensure_attribute('marca', 'Marca', ['Arcana Forge', 'Mythic Mint', 'Dragon Shield', 'Vault Pro']),
        'idioma' => tcg_demo_ensure_attribute('idioma', 'Idioma', ['Espanol', 'Ingles', 'Japones']),
        'condicion' => tcg_demo_ensure_attribute('condicion', 'Condicion', ['Nuevo', 'Near Mint', 'Played']),
        'color' => tcg_demo_ensure_attribute('color', 'Color', ['Rojo', 'Azul', 'Verde', 'Negro']),
        'tamano' => tcg_demo_ensure_attribute('tamano', 'Tamano', ['Standard', 'Premium']),
    ],
];

foreach ($categories as $category) {
    $taxonomies['categories'][$category] = tcg_demo_term_id('product_cat', $category);
}

foreach ($tags as $tag) {
    $taxonomies['tags'][$tag] = tcg_demo_term_id('product_tag', $tag);
}

$simple_products = [
    [
        'name' => 'Caja de sobres Arcana Forge - Set Base',
        'slug' => 'caja-sobres-arcana-forge-set-base',
        'sku' => 'TCG-DEMO-BOX-ARCANA-001',
        'regular_price' => '119.90',
        'stock' => 12,
        'low_stock_amount' => 3,
        'featured' => true,
        'brand' => 'Arcana Forge',
        'language' => 'Espanol',
        'condition' => 'Nuevo',
        'categories' => ['Sobres', 'Sellado'],
        'tags' => ['Destacado', 'Nuevo', 'Premium'],
        'short_description' => 'Caja sellada demo con 24 sobres para validar destacados y productos premium.',
        'description' => 'Producto demo con stock sano, marcado como destacado y preparado para probar bloques de home, filtros y badges de catalogo.',
    ],
    [
        'name' => 'Pack coleccionista Mythic Mint',
        'slug' => 'pack-coleccionista-mythic-mint',
        'sku' => 'TCG-DEMO-PACK-SALE-002',
        'regular_price' => '89.00',
        'sale_price' => '69.90',
        'stock' => 8,
        'brand' => 'Mythic Mint',
        'language' => 'Ingles',
        'condition' => 'Nuevo',
        'categories' => ['Coleccionista', 'Sellado'],
        'tags' => ['Rebajas', 'Bundle'],
        'short_description' => 'Pack en rebaja con sobres, carta promocional y caja guardacartas.',
        'description' => 'Incluye una seleccion demo de sobres, carta promocional y caja guardacartas. Pensado para contrastar productos con precio rebajado.',
    ],
    [
        'name' => 'Carta individual Dragon Warden',
        'slug' => 'carta-individual-dragon-warden',
        'sku' => 'TCG-DEMO-CARD-LOW-003',
        'regular_price' => '14.50',
        'stock' => 2,
        'low_stock_amount' => 3,
        'brand' => 'Arcana Forge',
        'language' => 'Espanol',
        'condition' => 'Near Mint',
        'categories' => ['Cartas individuales'],
        'tags' => ['Bajo stock', 'Destacado'],
        'short_description' => 'Carta individual con pocas unidades disponibles.',
        'description' => 'Stock configurado por debajo del umbral demo para que la tienda pueda mostrar badge de ultimas unidades.',
    ],
    [
        'name' => 'Carta promo Eclipse Sentinel',
        'slug' => 'carta-promo-eclipse-sentinel',
        'sku' => 'TCG-DEMO-CARD-OOS-004',
        'regular_price' => '22.00',
        'stock' => 0,
        'stock_status' => 'outofstock',
        'brand' => 'Mythic Mint',
        'language' => 'Japones',
        'condition' => 'Near Mint',
        'categories' => ['Cartas individuales', 'Coleccionista'],
        'tags' => ['Sin stock', 'Premium'],
        'short_description' => 'Carta promocional actualmente agotada.',
        'description' => 'Carta promocional demo sin stock. Debe aparecer como no disponible y no permitir compra si el frontend respeta WooCommerce.',
    ],
    [
        'name' => 'Reserva sobre especial Vault Pro',
        'slug' => 'reserva-sobre-especial-vault-pro',
        'sku' => 'TCG-DEMO-PREORDER-005',
        'regular_price' => '6.99',
        'stock' => 0,
        'stock_status' => 'onbackorder',
        'backorders' => 'notify',
        'brand' => 'Vault Pro',
        'language' => 'Espanol',
        'condition' => 'Nuevo',
        'categories' => ['Preventa', 'Sobres'],
        'tags' => ['Nuevo'],
        'short_description' => 'Producto en reserva para validar estados distintos a stock disponible y agotado.',
        'description' => 'Articulo demo con backorders permitidos con aviso. Sirve para decidir como se mostraran preventas en Sprint 6/7.',
    ],
];

$variable_products = [
    [
        'name' => 'Fundas Dragon Shield Demo',
        'slug' => 'fundas-dragon-shield-demo',
        'sku' => 'TCG-DEMO-SLEEVES-VAR-006',
        'brand' => 'Dragon Shield',
        'featured' => true,
        'categories' => ['Accesorios'],
        'tags' => ['Variable', 'Destacado'],
        'short_description' => 'Producto variable por color y tamano para validar soporte basico de variaciones.',
        'description' => 'Fundas demo con combinaciones de color y tamano. Algunas variaciones tienen rebaja, bajo stock o estan agotadas.',
        'variation_attributes' => [
            'color' => ['Rojo', 'Azul', 'Negro'],
            'tamano' => ['Standard', 'Premium'],
        ],
        'variations' => [
            [
                'sku' => 'TCG-DEMO-SLEEVES-RED-STD-006-A',
                'regular_price' => '9.99',
                'stock' => 18,
                'attributes' => ['color' => 'Rojo', 'tamano' => 'Standard'],
            ],
            [
                'sku' => 'TCG-DEMO-SLEEVES-BLUE-STD-006-B',
                'regular_price' => '9.99',
                'sale_price' => '7.99',
                'stock' => 9,
                'attributes' => ['color' => 'Azul', 'tamano' => 'Standard'],
            ],
            [
                'sku' => 'TCG-DEMO-SLEEVES-BLACK-PREMIUM-006-C',
                'regular_price' => '14.99',
                'stock' => 1,
                'low_stock_amount' => 2,
                'attributes' => ['color' => 'Negro', 'tamano' => 'Premium'],
            ],
            [
                'sku' => 'TCG-DEMO-SLEEVES-RED-PREMIUM-006-D',
                'regular_price' => '14.99',
                'stock' => 0,
                'stock_status' => 'outofstock',
                'attributes' => ['color' => 'Rojo', 'tamano' => 'Premium'],
            ],
        ],
    ],
    [
        'name' => 'Caja sobres Mythic Mint por idioma',
        'slug' => 'caja-sobres-mythic-mint-por-idioma',
        'sku' => 'TCG-DEMO-BOX-LANG-VAR-007',
        'brand' => 'Mythic Mint',
        'categories' => ['Sobres', 'Sellado'],
        'tags' => ['Variable', 'Rebajas'],
        'short_description' => 'Caja variable por idioma para contrastar atributos globales y variaciones con oferta.',
        'description' => 'Producto demo con variaciones por idioma. Permite probar selectores de ficha y filtros por atributos mas adelante.',
        'variation_attributes' => [
            'idioma' => ['Espanol', 'Ingles', 'Japones'],
        ],
        'variations' => [
            [
                'sku' => 'TCG-DEMO-BOX-LANG-ES-007-A',
                'regular_price' => '109.90',
                'stock' => 7,
                'attributes' => ['idioma' => 'Espanol'],
            ],
            [
                'sku' => 'TCG-DEMO-BOX-LANG-EN-007-B',
                'regular_price' => '109.90',
                'sale_price' => '99.90',
                'stock' => 5,
                'attributes' => ['idioma' => 'Ingles'],
            ],
            [
                'sku' => 'TCG-DEMO-BOX-LANG-JP-007-C',
                'regular_price' => '129.90',
                'stock' => 2,
                'low_stock_amount' => 3,
                'attributes' => ['idioma' => 'Japones'],
            ],
        ],
    ],
];

$coupons = [
    [
        'code' => 'SPRINT6-DEMO',
        'discount_type' => 'percent',
        'amount' => '10',
        'description' => 'Cupon demo del 10% para validar futura aplicacion de cupones.',
    ],
    [
        'code' => 'REBAJAS15',
        'discount_type' => 'percent',
        'amount' => '15',
        'description' => 'Cupon demo para campanas de rebajas.',
    ],
    [
        'code' => 'ENVIOLOCAL',
        'discount_type' => 'fixed_cart',
        'amount' => '5',
        'description' => 'Cupon demo de descuento fijo para checkout local.',
    ],
];

foreach ($simple_products as $product_data) {
    tcg_demo_simple_product($product_data, $taxonomies);
}

foreach ($variable_products as $product_data) {
    tcg_demo_variable_product($product_data, $taxonomies);
}

foreach ($coupons as $coupon_data) {
    tcg_demo_coupon($coupon_data);
}

WP_CLI::success('Demo shop catalog seeded: categories, tags, attributes, coupons, simple products and variable products are ready.');
