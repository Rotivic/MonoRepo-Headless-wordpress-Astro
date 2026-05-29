import { csrfHeaders } from './security';
import { tcgApi } from './tcg-api';

export interface WishlistItem {
  product_id: number;
  slug: string;
  name: string;
  price?: string;
  image?: string;
  is_in_stock?: boolean;
  permalink?: string;
  created_at?: string;
}

export type WishlistEventAction = 'added' | 'removed';

export function dispatchWishlistUpdated(productId: number, action: WishlistEventAction) {
  window.dispatchEvent(new CustomEvent('tcg:wishlist-updated', {
    detail: { productId, action },
  }));
}

async function wishlistJson<T>(url: string, options: RequestInit = {}): Promise<T> {
  const response = await fetch(url, {
    credentials: 'include',
    headers: csrfHeaders({ 'Content-Type': 'application/json', ...(options.headers || {}) }),
    ...options,
  });
  const data = await response.json().catch(() => ({}));

  if (!response.ok) {
    throw new Error(data.message || 'No se pudo actualizar la wishlist.');
  }

  return data;
}

export async function readWishlist(): Promise<WishlistItem[]> {
  const payload = await wishlistJson<{ data: WishlistItem[] }>(tcgApi.wishlist);
  return payload.data || [];
}

export async function addWishlistItem(productId: number): Promise<WishlistItem> {
  const payload = await wishlistJson<{ data: WishlistItem }>(tcgApi.wishlist, {
    method: 'POST',
    body: JSON.stringify({ product_id: productId }),
  });

  dispatchWishlistUpdated(productId, 'added');
  return payload.data;
}

export async function removeWishlistItem(productId: number): Promise<void> {
  await wishlistJson(tcgApi.wishlistItem(productId), { method: 'DELETE' });
  dispatchWishlistUpdated(productId, 'removed');
}
