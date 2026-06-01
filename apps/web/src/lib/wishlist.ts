import { csrfHeaders } from './security';
import { tcgApi } from './tcg-api';

const wishlistCacheKey = 'tcg.wishlist.items';
const wishlistIdsCacheKey = 'tcg.wishlist.ids';
const cacheTtl = 300_000;

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

function readCache<T>(key: string): T | null {
  try {
    const value = JSON.parse(window.localStorage.getItem(key) || 'null');
    if (!value || Date.now() - Number(value.time || 0) > cacheTtl) return null;
    return value.data as T;
  } catch {
    return null;
  }
}

function writeCache<T>(key: string, data: T) {
  try {
    window.localStorage.setItem(key, JSON.stringify({ time: Date.now(), data }));
  } catch {}
}

function updateIdsCache(productId: number, action: WishlistEventAction) {
  const ids = readCache<number[]>(wishlistIdsCacheKey) || [];
  const next = action === 'added'
    ? Array.from(new Set([...ids, productId]))
    : ids.filter((id) => Number(id) !== productId);
  writeCache(wishlistIdsCacheKey, next);

  const items = readCache<WishlistItem[]>(wishlistCacheKey);
  if (items && action === 'removed') {
    writeCache(wishlistCacheKey, items.filter((item) => Number(item.product_id) !== productId));
  }
}

export async function readWishlist(): Promise<WishlistItem[]> {
  const cached = readCache<WishlistItem[]>(wishlistCacheKey);
  if (cached) return cached;

  const payload = await wishlistJson<{ data: WishlistItem[] }>(tcgApi.wishlist);
  writeCache(wishlistCacheKey, payload.data || []);
  writeCache(wishlistIdsCacheKey, (payload.data || []).map((item) => Number(item.product_id)));
  return payload.data || [];
}

export async function readWishlistIds(): Promise<number[]> {
  const cached = readCache<number[]>(wishlistIdsCacheKey);
  if (cached) return cached;

  const payload = await wishlistJson<{ data: number[] }>(`${tcgApi.wishlist}?ids_only=1`);
  const ids = (payload.data || []).map(Number);
  writeCache(wishlistIdsCacheKey, ids);
  return ids;
}

export async function refreshWishlist(): Promise<WishlistItem[]> {
  const payload = await wishlistJson<{ data: WishlistItem[] }>(tcgApi.wishlist);
  writeCache(wishlistCacheKey, payload.data || []);
  writeCache(wishlistIdsCacheKey, (payload.data || []).map((item) => Number(item.product_id)));
  return payload.data || [];
}

export async function addWishlistItem(productId: number): Promise<WishlistItem> {
  const payload = await wishlistJson<{ data: WishlistItem }>(tcgApi.wishlist, {
    method: 'POST',
    body: JSON.stringify({ product_id: productId }),
  });

  updateIdsCache(productId, 'added');
  dispatchWishlistUpdated(productId, 'added');
  return payload.data;
}

export async function removeWishlistItem(productId: number): Promise<void> {
  await wishlistJson(tcgApi.wishlistItem(productId), { method: 'DELETE' });
  updateIdsCache(productId, 'removed');
  dispatchWishlistUpdated(productId, 'removed');
}
