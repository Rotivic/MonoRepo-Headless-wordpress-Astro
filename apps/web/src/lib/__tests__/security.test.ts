import { describe, it, expect, beforeEach } from 'vitest';
import { csrfHeaders } from '../security';

describe('csrfHeaders', () => {
  beforeEach(() => {
    Object.defineProperty(document, 'cookie', { writable: true, value: '' });
  });

  it('returns original headers when no CSRF cookie is present', () => {
    document.cookie = '';
    const base = { 'Content-Type': 'application/json' };
    const result = csrfHeaders(base);
    expect(result).toEqual(base);
  });

  it('adds X-TCG-CSRF header when CSRF cookie is present', () => {
    document.cookie = 'tcg_platform_csrf=abc123%3Asignature; other=value';
    const result = csrfHeaders({ 'Content-Type': 'application/json' });
    expect(result).toHaveProperty('X-TCG-CSRF', 'abc123');
  });

  it('extracts only the raw token before the colon from the cookie value', () => {
    document.cookie = 'tcg_platform_csrf=mytoken%3Ahash456';
    const result = csrfHeaders({});
    expect(result).toHaveProperty('X-TCG-CSRF', 'mytoken');
  });

  it('preserves all provided base headers', () => {
    document.cookie = 'tcg_platform_csrf=tok%3Asig';
    const base = { 'Content-Type': 'application/json', Authorization: 'Bearer xyz' };
    const result = csrfHeaders(base) as Record<string, string>;
    expect(result['Content-Type']).toBe('application/json');
    expect(result['Authorization']).toBe('Bearer xyz');
    expect(result['X-TCG-CSRF']).toBe('tok');
  });

  it('returns headers without X-TCG-CSRF if cookie value has no colon', () => {
    document.cookie = 'tcg_platform_csrf=nocolon';
    const result = csrfHeaders({}) as Record<string, string>;
    // token is the full value; CSRF header is added
    expect(result['X-TCG-CSRF']).toBe('nocolon');
  });

  it('works with an empty base headers object', () => {
    document.cookie = 'tcg_platform_csrf=t%3As';
    const result = csrfHeaders({}) as Record<string, string>;
    expect(result['X-TCG-CSRF']).toBe('t');
  });
});
