import { siteConfig } from '../config/site';

export interface StoreProductImage {
  src: string;
  alt: string;
}

export interface StoreProductPrice {
  price: string;
  regular_price: string;
  sale_price?: string;
  currency_code: string;
  currency_symbol: string;
  currency_minor_unit: number;
}

export interface StoreProductCategory {
  id: number;
  name: string;
  slug: string;
}

export interface StoreProductVariation {
  id: number;
  attributes: { name: string; value: string }[];
}

export interface StoreProductAttributeTerm {
  id: number;
  name: string;
  slug: string;
  default: boolean;
}

export interface StoreProductAttribute {
  id: number;
  name: string;
  taxonomy: string;
  has_variations: boolean;
  terms: StoreProductAttributeTerm[];
}

export interface StoreProduct {
  id: number;
  name: string;
  slug: string;
  type: 'simple' | 'variable' | 'grouped' | 'external';
  description: string;
  short_description: string;
  permalink: string;
  images: StoreProductImage[];
  prices: StoreProductPrice;
  is_in_stock: boolean;
  on_sale: boolean;
  is_featured: boolean;
  low_stock_remaining: number | null;
  stock_quantity: number | null;
  stock_status: 'instock' | 'outofstock' | 'onbackorder';
  categories: StoreProductCategory[];
  tags: { id: number; name: string; slug: string }[];
  attributes: StoreProductAttribute[];
  variations: StoreProductVariation[];
  add_to_cart: { text: string };
}

export interface StoreCategory {
  id: number;
  name: string;
  slug: string;
  count: number;
}

export interface ShopQueryParams {
  search?: string;
  category?: string;
  featured?: boolean;
  on_sale?: boolean;
  stock_status?: string;
  min_price?: number;
  max_price?: number;
  orderby?: string;
  order?: string;
  page?: number;
  per_page?: number;
}

export interface ShopProductsResult {
  products: StoreProduct[];
  total: number;
  totalPages: number;
}

export const shopApi = {
  products: `${siteConfig.apiUrl}/wc/store/v1/products`,
  categories: `${siteConfig.apiUrl}/wc/store/v1/products/categories`,
  productBySlug: (slug: string) =>
    `${siteConfig.apiUrl}/wc/store/v1/products?slug=${encodeURIComponent(slug)}`,
};

export const shopApiInternal = {
  products: `${siteConfig.internalApiUrl}/wc/store/v1/products`,
};

export function formatStorePrice(prices?: StoreProductPrice): string {
  if (!prices) return '-';
  const value = Number(prices.price) / 10 ** prices.currency_minor_unit;
  return new Intl.NumberFormat('es-ES', {
    style: 'currency',
    currency: prices.currency_code,
  }).format(value);
}

/**
 * Returns HTML for the price, including a strikethrough regular price
 * when the product is on sale (price < regular_price).
 */
export function formatStorePriceHtml(prices?: StoreProductPrice, onSale = false): string {
  if (!prices) return '-';

  const divisor       = 10 ** prices.currency_minor_unit;
  const priceValue    = Number(prices.price) / divisor;
  const regularValue  = Number(prices.regular_price) / divisor;

  const fmt = new Intl.NumberFormat('es-ES', {
    style: 'currency',
    currency: prices.currency_code,
  });

  const currentFormatted  = fmt.format(priceValue);

  if (onSale && regularValue > priceValue) {
    const regularFormatted = fmt.format(regularValue);
    return `<del class="price-regular">${regularFormatted}</del> <ins class="price-sale">${currentFormatted}</ins>`;
  }

  return currentFormatted;
}

export function buildProductsUrl(params: ShopQueryParams = {}): string {
  const url = new URL(shopApi.products);
  const {
    page = 1,
    per_page = 12,
    search,
    category,
    featured,
    on_sale,
    stock_status,
    min_price,
    max_price,
    orderby = 'date',
    order = 'desc',
  } = params;

  url.searchParams.set('page', String(page));
  url.searchParams.set('per_page', String(per_page));
  url.searchParams.set('orderby', orderby);
  url.searchParams.set('order', order);
  if (search) url.searchParams.set('search', search);
  if (category) url.searchParams.set('category', category);
  if (featured) url.searchParams.set('featured', 'true');
  if (on_sale) url.searchParams.set('on_sale', 'true');
  if (stock_status) url.searchParams.set('stock_status', stock_status);
  if (min_price !== undefined) url.searchParams.set('min_price', String(Math.round(min_price * 100)));
  if (max_price !== undefined) url.searchParams.set('max_price', String(Math.round(max_price * 100)));

  return url.toString();
}
