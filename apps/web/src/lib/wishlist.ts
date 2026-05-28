const wishlistKey = 'tcg.wishlist.items';

export interface WishlistItem {
  id: number;
  slug: string;
  name: string;
  price?: string;
  image?: string;
}

export function readWishlist(): WishlistItem[] {
  try {
    const raw = window.localStorage.getItem(wishlistKey);
    return raw ? JSON.parse(raw) : [];
  } catch {
    return [];
  }
}

export function writeWishlist(items: WishlistItem[]) {
  window.localStorage.setItem(wishlistKey, JSON.stringify(items));
  window.dispatchEvent(new CustomEvent('tcg:wishlist-updated'));
}

export function toggleWishlistItem(item: WishlistItem) {
  const items = readWishlist();
  const exists = items.some((current) => current.id === item.id);
  writeWishlist(exists ? items.filter((current) => current.id !== item.id) : [...items, item]);
}
