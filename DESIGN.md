# TCG Platform Design System

Version: alpha

TCG Platform debe sentirse como una herramienta de confianza para coleccionistas, vendedores y jugadores: clara, rapida y sobria. La referencia visual inicial toma una direccion financiera/editorial: superficies blancas, tinta casi negra, azul como color de accion, grises frios para estructura y estados semanticos para mercado.

## Principios

- La interfaz debe priorizar accion y lectura, no decoracion.
- El azul se reserva para acciones principales, enlaces clave y foco.
- Las pantallas autenticadas deben ser mas densas que las publicas: listas, estados, tablas y filtros antes que bloques de marketing.
- Web y app mobile deben compartir lenguaje: login, registro, perfil y futuros flujos de wishlist, compras y ventas beben del mismo backend WordPress.
- Las rutas publicas pueden consumir WordPress REST API nativa; las rutas privadas usan `/wp-json/tcg/v1`.

## Tokens

### Color

| Token | Valor | Uso |
| --- | --- | --- |
| `primary` | `#0052ff` | CTA principal, foco, enlaces importantes |
| `primary-active` | `#003ecc` | Estado activo/hover |
| `ink` | `#0a0b0d` | Titulos y texto fuerte |
| `body` | `#5b616e` | Texto secundario |
| `muted` | `#7c828a` | Ayudas, captions |
| `hairline` | `#dee1e6` | Bordes suaves |
| `canvas` | `#ffffff` | Fondo base |
| `surface-soft` | `#f7f7f7` | Bandas y fondos secundarios |
| `surface-strong` | `#eef0f3` | Controles secundarios |
| `surface-dark` | `#0a0b0d` | Bandas oscuras y paneles destacados |
| `success` | `#05b169` | Estados positivos |
| `danger` | `#cf202f` | Errores y estados negativos |

### Tipografia

Usar `Inter` como familia base, con fallback del sistema. Los pesos principales son 400 para titulares calmados, 500 para navegacion y 600 para botones/labels.

| Token | Tamano | Peso | Uso |
| --- | --- | --- | --- |
| `display-lg` | 56px | 400 | Heroes y encabezados principales |
| `title-lg` | 32px | 400 | Encabezados de vista |
| `title-md` | 20px | 600 | Titulos de seccion |
| `body-md` | 16px | 400 | Texto general |
| `body-sm` | 14px | 400 | Ayudas y tablas |
| `button` | 15px | 600 | Botones |

### Forma y espacio

- Botones: pill (`999px`).
- Inputs: radio `12px`.
- Paneles de herramienta: radio `24px`.
- Items repetidos: radio `8px`.
- Contenedor maximo: `1180px`.
- Padding de vista: `32px` desktop, `20px` mobile.

## Componentes Base

### Header

Barra superior blanca con marca, enlaces principales y acciones de sesion. Debe mantenerse compacta y predecible.

### Botones

- Primario: fondo azul, texto blanco.
- Secundario: fondo gris frio, texto tinta.
- Texto: sin fondo, azul o tinta segun jerarquia.

### Formularios

Inputs de 48px minimo, label visible, foco azul y errores en rojo. Login y registro deben compartir estructura para que web y app se sientan parte del mismo producto.

### Perfil

La vista de perfil debe ser una pantalla de producto, no una landing: resumen de cuenta, estado de token y proximas areas de dominio como wishlist, ventas y compras.

## Rutas Web Iniciales

| Ruta | Uso |
| --- | --- |
| `/` | Estado del stack y modulos iniciales |
| `/login` | Inicio de sesion contra `/wp-json/tcg/v1/login` |
| `/registro` | Alta de usuario WordPress contra `/wp-json/tcg/v1/register` |
| `/perfil` | Vista privada usando `/wp-json/tcg/v1/me` |

## Seguridad de Sesion

El backend emite tokens opacos. El token se muestra una vez al cliente mobile como Bearer y se guarda hasheado en WordPress. En web, el backend tambien lo entrega como cookie `HttpOnly`, `SameSite=Lax` y `Secure` cuando el entorno usa HTTPS.

La configuracion actual revoca sesiones anteriores del mismo `device_name`. Esto permite que web y app convivan, pero evita acumular sesiones web antiguas si el usuario vuelve a entrar desde el navegador.

Ventaja: un nuevo login web invalida sesiones web anteriores sin cerrar la app mobile.

Coste: si el usuario inicia sesion en dos navegadores que declaran el mismo `device_name`, el mas reciente invalida al anterior. Mas adelante se puede exponer una lista de dispositivos/sesiones para revocar manualmente.

## Pendientes

- Definir comportamiento final de "recordarme" para web.
- Añadir refresh tokens o rotacion de token si el producto necesita sesiones muy largas.
- Exponer gestion de dispositivos/sesiones en perfil.
- Disenar 2FA, reset de password y verificacion de email.
- Crear componentes de dominio: wishlist, ordenes, ventas, inventario y transacciones.
