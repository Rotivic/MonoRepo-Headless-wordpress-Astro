const cartKey = 'tcg.cart.items';

export interface CartItem {
  id: number;
  slug: string;
  name: string;
  price: string;
  image?: string;
  quantity: number;
}

export function readCart(): CartItem[] {
  try {
    const raw = window.localStorage.getItem(cartKey);
    return raw ? JSON.parse(raw) : [];
  } catch {
    return [];
  }
}

export function writeCart(items: CartItem[]) {
  window.localStorage.setItem(cartKey, JSON.stringify(items));
  window.dispatchEvent(new CustomEvent('tcg:cart-updated'));
}

export function addCartItem(item: CartItem) {
  const items = readCart();
  const existing = items.find((current) => current.id === item.id);

  if (existing) {
    existing.quantity += item.quantity;
  } else {
    items.push(item);
  }

  writeCart(items);
}

export function removeCartItem(id: number) {
  writeCart(readCart().filter((item) => item.id !== id));
}

export function clearCart() {
  writeCart([]);
}
