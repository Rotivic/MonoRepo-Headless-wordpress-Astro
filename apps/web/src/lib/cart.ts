import { csrfHeaders } from './security';
import { tcgApi } from './tcg-api';

const cartKey = 'tcg.cart.items';
const pendingMergeKey = 'tcg.cart.pending-merge';
const authKey = 'tcg.authenticated';

export interface CartItem {
  id: number;
  product_id?: number;
  slug: string;
  name: string;
  price: string;
  image?: string;
  quantity: number;
  is_in_stock?: boolean;
  stock_quantity?: number | null;
  max_quantity?: number | null;
}

interface CartPayload {
  data?: CartItem[];
}

function isAuthenticated() {
  try {
    return window.localStorage.getItem(authKey) === '1';
  } catch {
    return false;
  }
}

function normalizeItem(item: CartItem): CartItem {
  const id = Number(item.product_id || item.id);

  return {
    ...item,
    id,
    product_id: id,
    quantity: Number(item.quantity || 1),
  };
}

function readLocalCart(): CartItem[] {
  try {
    const raw = window.localStorage.getItem(cartKey);
    const items = raw ? JSON.parse(raw) : [];
    return Array.isArray(items) ? items.map(normalizeItem) : [];
  } catch {
    return [];
  }
}

function writeLocalCart(items: CartItem[], notify = true) {
  window.localStorage.setItem(cartKey, JSON.stringify(items));
  if (notify) {
    window.dispatchEvent(new CustomEvent('tcg:cart-updated', { detail: { items } }));
  }
}

async function cartJson<T>(url: string, options: RequestInit = {}): Promise<T> {
  const response = await fetch(url, {
    credentials: 'include',
    headers: csrfHeaders({ 'Content-Type': 'application/json', ...(options.headers || {}) }),
    ...options,
  });
  const data = await response.json().catch(() => ({}));

  if (!response.ok) {
    throw new Error(data.message || 'No se pudo actualizar el carrito.');
  }

  return data;
}

function dispatchCartUpdated(items?: CartItem[]) {
  window.dispatchEvent(new CustomEvent('tcg:cart-updated', { detail: { items } }));
}

export function readCart(): CartItem[] {
  return readLocalCart();
}

export function writeCart(items: CartItem[]) {
  writeLocalCart(items.map(normalizeItem));
}

export async function readAccountCart(): Promise<CartItem[]> {
  const payload = await cartJson<CartPayload>(tcgApi.cart);
  const items = (payload.data || []).map(normalizeItem);
  writeLocalCart(items, false);
  return items;
}

export async function readActiveCart(): Promise<CartItem[]> {
  if (!isAuthenticated()) return readLocalCart();

  try {
    return await readAccountCart();
  } catch {
    return readLocalCart();
  }
}

export async function addCartItem(item: CartItem): Promise<CartItem[]> {
  const normalized = normalizeItem(item);

  if (isAuthenticated()) {
    const payload = await cartJson<CartPayload>(tcgApi.cart, {
      method: 'POST',
      body: JSON.stringify({ product_id: normalized.id, quantity: normalized.quantity }),
    });
    const items = (payload.data || []).map(normalizeItem);
    writeLocalCart(items, false);
    dispatchCartUpdated(items);
    return items;
  }

  const items = readLocalCart();
  const existing = items.find((current) => current.id === normalized.id);

  if (existing) {
    existing.quantity += normalized.quantity;
  } else {
    items.push(normalized);
  }

  writeLocalCart(items);
  return items;
}

export async function updateCartItem(id: number, quantity: number): Promise<CartItem[]> {
  if (isAuthenticated()) {
    const payload = await cartJson<CartPayload>(tcgApi.cartItem(id), {
      method: 'PATCH',
      body: JSON.stringify({ quantity }),
    });
    const items = (payload.data || []).map(normalizeItem);
    writeLocalCart(items, false);
    dispatchCartUpdated(items);
    return items;
  }

  const next = readLocalCart()
    .map((item) => item.id === id ? { ...item, quantity } : item)
    .filter((item) => item.quantity > 0);
  writeLocalCart(next);
  return next;
}

export async function removeCartItem(id: number): Promise<CartItem[]> {
  if (isAuthenticated()) {
    const payload = await cartJson<CartPayload>(tcgApi.cartItem(id), { method: 'DELETE' });
    const items = (payload.data || []).map(normalizeItem);
    writeLocalCart(items, false);
    dispatchCartUpdated(items);
    return items;
  }

  const next = readLocalCart().filter((item) => item.id !== id);
  writeLocalCart(next);
  return next;
}

export async function clearCart(): Promise<CartItem[]> {
  if (isAuthenticated()) {
    const payload = await cartJson<CartPayload>(tcgApi.cart, { method: 'DELETE' });
    const items = (payload.data || []).map(normalizeItem);
    writeLocalCart(items, false);
    dispatchCartUpdated(items);
    return items;
  }

  writeLocalCart([]);
  return [];
}

export async function mergePendingCart(): Promise<CartItem[]> {
  const guestItems = readLocalCart();

  if (!isAuthenticated() || guestItems.length === 0) {
    try {
      window.localStorage.removeItem(pendingMergeKey);
    } catch {}
    return isAuthenticated() ? readAccountCart() : guestItems;
  }

  const payload = await cartJson<CartPayload>(tcgApi.cartMerge, {
    method: 'POST',
    body: JSON.stringify({
      items: guestItems.map((item) => ({
        product_id: item.product_id || item.id,
        quantity: item.quantity,
      })),
    }),
  });
  const items = (payload.data || []).map(normalizeItem);
  writeLocalCart(items, false);
  try {
    window.localStorage.removeItem(pendingMergeKey);
  } catch {}
  dispatchCartUpdated(items);
  return items;
}
