export interface ProductBadgeInfo {
  on_sale: boolean;
  is_featured: boolean;
  is_in_stock: boolean;
  stock_status: string;
  low_stock_remaining: number | null;
}

export interface ProductBadge {
  key: string;
  label: string;
  variant: 'sale' | 'featured' | 'outofstock' | 'lowstock' | 'backorder';
}

export function getProductBadges(product: ProductBadgeInfo): ProductBadge[] {
  const badges: ProductBadge[] = [];

  if (!product.is_in_stock || product.stock_status === 'outofstock') {
    badges.push({ key: 'outofstock', label: 'Agotado', variant: 'outofstock' });
  } else if (product.stock_status === 'onbackorder') {
    badges.push({ key: 'backorder', label: 'Reserva', variant: 'backorder' });
  } else if (product.low_stock_remaining !== null && product.low_stock_remaining > 0) {
    badges.push({ key: 'lowstock', label: 'Bajo stock', variant: 'lowstock' });
  }

  if (product.on_sale) {
    badges.push({ key: 'sale', label: 'Oferta', variant: 'sale' });
  }
  if (product.is_featured) {
    badges.push({ key: 'featured', label: 'Destacado', variant: 'featured' });
  }

  return badges;
}

export function getProductBadgesHtml(product: ProductBadgeInfo): string {
  const badges = getProductBadges(product);
  if (!badges.length) return '';
  const items = badges.map((b) => `<span class="badge badge-${b.variant}">${b.label}</span>`).join('');
  return `<div class="product-badges">${items}</div>`;
}
