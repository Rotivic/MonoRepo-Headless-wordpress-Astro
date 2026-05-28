# Seguridad del starter

Este proyecto separa dos modos de autenticacion:

- Web Astro: cookie `HttpOnly` para la sesion y cookie CSRF firmada para acciones con estado.
- Mobile/API: token `Authorization: Bearer`, sin dependencia de cookies ni CSRF.

## Controles aplicados

- Tokens opacos de alta entropia, guardados en base de datos solo como HMAC SHA-256.
- Revocacion de tokens en logout y cambio de contrasena.
- Cookie de sesion `HttpOnly`, `SameSite=Lax` y `Secure` cuando hay HTTPS.
- Proteccion CSRF para rutas autenticadas con cookie mediante header `X-TCG-CSRF`.
- CORS limitado a origenes permitidos y con credenciales solo para esos origenes.
- Rutas admin protegidas con `manage_options`.
- `wp-admin` reservado a administradores; usuarios finales se redirigen al frontend.
- Frontend publico de WordPress redirigido al frontend Astro; WordPress queda como CMS/API headless.
- Comentarios, pingbacks, trackbacks, XML-RPC y endpoints REST de comentarios/usuarios desactivados.
- Honeypot basico en registro web para cortar bots simples antes de crear usuarios.
- Rate limit en login, registro, recuperacion de contrasena, reset y verificacion 2FA.
- Reset/verificacion por tokens temporales hasheados.
- 2FA TOTP opcional con codigos de recuperacion hasheados.
- Cabeceras basicas en Nginx: `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy` y `Permissions-Policy`.
- Politica minima de contrasena: 12 caracteres con mayusculas, minusculas y numeros.

## Reglas para nuevas features

- Toda ruta REST privada debe usar `require_auth`.
- Toda ruta REST admin debe usar `require_admin`.
- Las vistas de backoffice frontend deben comprobar `can_access_backoffice`; los datos sensibles siempre deben estar protegidos tambien en backend.
- Las rutas publicas no deben revelar si un email existe salvo que sea estrictamente necesario.
- Las acciones con estado desde Astro deben enviar `X-TCG-CSRF` usando `csrfHeaders()`.
- Las acciones desde mobile deben usar `Authorization: Bearer`.
- No exponer datos internos de WordPress si el frontend solo necesita un subconjunto.
- No crear edicion sensible en Astro si WordPress ya la gestiona mejor.

## Antes de desplegar

- Usar HTTPS real para que la cookie se marque como `Secure`.
- Cambiar credenciales demo.
- Revisar `AUTH_KEY`, salts y variables `.env`.
- Desactivar debug en produccion.
- Revisar origenes permitidos en CORS.
- Ejecutar build y pruebas basicas de endpoints protegidos.
