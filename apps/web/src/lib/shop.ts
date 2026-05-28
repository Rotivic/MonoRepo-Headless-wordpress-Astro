import { siteConfig } from '../config/site';

export interface StoreProductImage {
  src: string;
  alt: string;
}

export interface StoreProductPrice {
  price: string;
  regular_price: string;
  currency_code: string;
  currency_symbol: string;
  currency_minor_unit: number;
}

export interface StoreProduct {
  id: number;
  name: string;
  slug: string;
  description: string;
  short_description: string;
  permalink: string;
  images: StoreProductImage[];
  prices: StoreProductPrice;
  is_in_stock: boolean;
  add_to_cart: {
    text: string;
  };
}

export const shopApi = {
  products: `${siteConfig.apiUrl}/wc/store/v1/products`,
  productBySlug: (slug: string) =>
    `${siteConfig.apiUrl}/wc/store/v1/products?slug=${encodeURIComponent(slug)}`,
};

export const shopApiInternal = {
  products: `${siteConfig.internalApiUrl}/wc/store/v1/products`,
};

export function formatStorePrice(prices?: StoreProductPrice) {
  if (!prices) {
    return '-';
  }

  const value = Number(prices.price) / 10 ** prices.currency_minor_unit;

  return new Intl.NumberFormat('es-ES', {
    style: 'currency',
    currency: prices.currency_code,
  }).format(value);
}
