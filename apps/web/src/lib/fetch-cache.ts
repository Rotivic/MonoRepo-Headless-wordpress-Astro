/**
 * In-flight request deduplication.
 * If the exact same URL+method is already being fetched, returns the same
 * Promise instead of firing a duplicate network request.
 *
 * Usage: replace `fetch(url, init)` with `dedupFetch(url, init)`.
 * The response is shared across callers, so each caller must call
 * `.clone()` before reading the body if multiple readers are needed.
 */
const _inflight = new Map<string, Promise<Response>>();

export function dedupFetch(url: string, init?: RequestInit): Promise<Response> {
  const key = `${init?.method ?? 'GET'}:${url}`;

  const existing = _inflight.get(key);
  if (existing) return existing;

  const promise = fetch(url, init).finally(() => _inflight.delete(key));
  _inflight.set(key, promise);
  return promise;
}

/**
 * Tiny in-memory response cache with TTL.
 * Stores parsed JSON payloads (not raw Response objects).
 * Use for GET requests whose data is safe to serve stale for a few seconds.
 */
interface CacheEntry<T> {
  data: T;
  expiresAt: number;
}

const _mem = new Map<string, CacheEntry<unknown>>();

export function memGet<T>(key: string): T | undefined {
  const entry = _mem.get(key) as CacheEntry<T> | undefined;
  if (!entry) return undefined;
  if (Date.now() > entry.expiresAt) {
    _mem.delete(key);
    return undefined;
  }
  return entry.data;
}

export function memSet<T>(key: string, data: T, ttlMs: number): void {
  _mem.set(key, { data, expiresAt: Date.now() + ttlMs });
}

export function memDelete(key: string): void {
  _mem.delete(key);
}

export function memClear(): void {
  _mem.clear();
}

interface JsonCacheEntry<T> {
  data: T;
  headers: Record<string, string>;
  time: number;
  ttlMs: number;
}

export interface CachedJsonResult<T> {
  data: T;
  headers: Record<string, string>;
  fromCache: boolean;
}

const _jsonInflight = new Map<string, Promise<CachedJsonResult<unknown>>>();
const _jsonMemory = new Map<string, JsonCacheEntry<unknown>>();
const _storedHeaders = ['x-wp-total', 'x-wp-totalpages'];

function storageKey(key: string): string {
  return `tcg.fetch:${key}`;
}

function readStored<T>(key: string): CachedJsonResult<T> | null {
  try {
    const entry = JSON.parse(sessionStorage.getItem(storageKey(key)) || 'null') as JsonCacheEntry<T> | null;
    if (!entry || Date.now() - entry.time > entry.ttlMs) return null;
    return { data: entry.data, headers: entry.headers || {}, fromCache: true };
  } catch {
    return null;
  }
}

function writeStored<T>(key: string, data: T, headers: Headers, ttlMs: number): void {
  try {
    const pickedHeaders = Object.fromEntries(
      _storedHeaders.map((name) => [name, headers.get(name) || ''])
    );
    sessionStorage.setItem(storageKey(key), JSON.stringify({
      data,
      headers: pickedHeaders,
      time: Date.now(),
      ttlMs,
    }));
  } catch {}
}

export async function cachedJson<T>(
  url: string,
  init: RequestInit = {},
  ttlMs = 60_000,
): Promise<CachedJsonResult<T>> {
  const method = (init.method || 'GET').toUpperCase();
  const key = `${method}:${url}`;
  const shouldPersist = method === 'GET' && ttlMs > 0 && isPublicCacheUrl(url);

  if (method === 'GET' && ttlMs > 0) {
    const memory = readMemory<T>(key);
    if (memory) return memory;
  }

  if (shouldPersist) {
    const cached = readStored<T>(key);
    if (cached) return cached;
  }

  const existing = _jsonInflight.get(key) as Promise<CachedJsonResult<T>> | undefined;
  if (existing) return existing;

  const promise = fetch(url, init)
    .then(async (response) => {
      const data = await response.json();
      if (!response.ok) {
        throw new Error(data?.message || `Request failed with ${response.status}`);
      }
      if (method === 'GET' && ttlMs > 0) writeMemory(key, data, response.headers, ttlMs);
      if (shouldPersist) writeStored(key, data, response.headers, ttlMs);
      return {
        data,
        headers: Object.fromEntries(_storedHeaders.map((name) => [name, response.headers.get(name) || ''])),
        fromCache: false,
      };
    })
    .finally(() => _jsonInflight.delete(key));

  _jsonInflight.set(key, promise as Promise<CachedJsonResult<unknown>>);
  return promise;
}

export function invalidateCachedJson(urlPrefix = ''): void {
  Array.from(_jsonMemory.keys())
    .filter((key) => key.includes(urlPrefix))
    .forEach((key) => _jsonMemory.delete(key));

  try {
    Object.keys(sessionStorage)
      .filter((key) => key.startsWith('tcg.fetch:') && key.includes(urlPrefix))
      .forEach((key) => sessionStorage.removeItem(key));
  } catch {}
}

function isPublicCacheUrl(url: string): boolean {
  try {
    const parsed = new URL(url, window.location.origin);
    return parsed.pathname.includes('/wc/store/') || parsed.pathname.includes('/wp/v2/');
  } catch {
    return false;
  }
}

function readMemory<T>(key: string): CachedJsonResult<T> | null {
  const entry = _jsonMemory.get(key) as JsonCacheEntry<T> | undefined;
  if (!entry) return null;
  if (Date.now() - entry.time > entry.ttlMs) {
    _jsonMemory.delete(key);
    return null;
  }
  return { data: entry.data, headers: entry.headers || {}, fromCache: true };
}

function writeMemory<T>(key: string, data: T, headers: Headers, ttlMs: number): void {
  const pickedHeaders = Object.fromEntries(
    _storedHeaders.map((name) => [name, headers.get(name) || ''])
  );
  _jsonMemory.set(key, { data, headers: pickedHeaders, time: Date.now(), ttlMs });
}
