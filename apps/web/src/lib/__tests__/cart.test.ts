import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';

// Minimal localStorage mock (jsdom provides it, but we control the store explicitly)
const localStorageMock = (() => {
  let store: Record<string, string> = {};
  return {
    getItem: (key: string) => store[key] ?? null,
    setItem: (key: string, value: string) => { store[key] = value; },
    removeItem: (key: string) => { delete store[key]; },
    clear: () => { store = {}; },
  };
})();

Object.defineProperty(globalThis, 'localStorage', { value: localStorageMock, writable: true });
Object.defineProperty(globalThis, 'window', { value: globalThis, writable: true });

// Prevent CustomEvent dispatch from crashing in jsdom
globalThis.dispatchEvent = vi.fn();

// Mock fetch globally (cart.ts calls it for authenticated paths)
const mockFetch = vi.fn();
globalThis.fetch = mockFetch;

// Import after globals are set up
const { readCart, writeCart } = await import('../cart');

const cartKey = 'tcg.cart.items';

describe('readCart (local cart)', () => {
  beforeEach(() => localStorage.clear());

  it('returns empty array when localStorage is empty', () => {
    const result = readCart();
    expect(result).toEqual([]);
  });

  it('returns items stored in localStorage', () => {
    const items = [{ id: 1, product_id: 1, slug: 'test', name: 'Prod', price: '10,00 €', quantity: 2 }];
    localStorage.setItem(cartKey, JSON.stringify(items));
    const result = readCart();
    expect(result).toHaveLength(1);
    expect(result[0].id).toBe(1);
    expect(result[0].quantity).toBe(2);
  });

  it('returns empty array when localStorage contains invalid JSON', () => {
    localStorage.setItem(cartKey, 'not-json{{{');
    const result = readCart();
    expect(result).toEqual([]);
  });
});

describe('writeCart (local cart)', () => {
  beforeEach(() => localStorage.clear());
  afterEach(() => vi.clearAllMocks());

  it('writes items to localStorage', () => {
    const items = [{ id: 5, product_id: 5, slug: 'a', name: 'A', price: '5 €', quantity: 1 }];
    writeCart(items);
    const stored = JSON.parse(localStorage.getItem(cartKey) ?? '[]');
    expect(stored).toHaveLength(1);
    expect(stored[0].id).toBe(5);
  });

  it('overwrites existing cart in localStorage', () => {
    const first = [{ id: 1, product_id: 1, slug: 'a', name: 'A', price: '1 €', quantity: 1 }];
    const second = [{ id: 2, product_id: 2, slug: 'b', name: 'B', price: '2 €', quantity: 3 }];
    writeCart(first);
    writeCart(second);
    const stored = JSON.parse(localStorage.getItem(cartKey) ?? '[]');
    expect(stored).toHaveLength(1);
    expect(stored[0].id).toBe(2);
  });

  it('normalizes item id and product_id to numbers', () => {
    const items = [{ id: '7' as unknown as number, product_id: '7' as unknown as number, slug: 'x', name: 'X', price: '7 €', quantity: 1 }];
    writeCart(items);
    const stored = JSON.parse(localStorage.getItem(cartKey) ?? '[]');
    expect(stored[0].id).toBe(7);
    expect(stored[0].product_id).toBe(7);
  });

  it('writes empty array to clear the cart', () => {
    const items = [{ id: 1, product_id: 1, slug: 'a', name: 'A', price: '1 €', quantity: 1 }];
    writeCart(items);
    writeCart([]);
    const stored = JSON.parse(localStorage.getItem(cartKey) ?? '[1]');
    expect(stored).toEqual([]);
  });
});
