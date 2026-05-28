export function csrfHeaders(headers: HeadersInit = {}): HeadersInit {
  const csrf = document.cookie
    .split('; ')
    .find((row) => row.startsWith('tcg_platform_csrf='))
    ?.split('=')[1];

  if (!csrf) {
    return headers;
  }

  const token = decodeURIComponent(csrf).split(':')[0];

  return {
    ...headers,
    'X-TCG-CSRF': token,
  };
}
