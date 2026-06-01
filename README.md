# TCG Platform

Backend headless con WordPress Bedrock, frontend Astro y app mobile Flutter en estructura monorepo.

El objetivo del proyecto es tener una base reproducible para una plataforma TCG: WordPress funciona como CMS/API headless, Astro como frontend web y Flutter como cliente mobile.

## Stack

- WordPress Bedrock en `apps/backend`
- PHP 8.3 FPM con Composer, WP-CLI y extensiones necesarias
- MySQL 8.0
- Nginx como servidor del backend
- Astro 6 con Node 22 para el frontend
- Flutter en `apps/mobile`
- Docker Compose como orquestador local

## Servicios

| Servicio | Contenedor | Puerto | Uso |
| --- | --- | --- | --- |
| `db` | `tcg_db` | interno | Base de datos MySQL |
| `php` | `tcg_php` | interno `9000` | PHP-FPM, Bedrock, Composer, WP-CLI |
| `nginx` | `tcg_nginx` | `8080` | Backend WordPress |
| `web` | `tcg_web` | `4321` | Frontend Astro |
| `redis` | `tcg_redis` | interno | Object cache persistente para WordPress |
| `mailpit` | `tcg_mailpit` | `8025` | Captura de emails locales |
| `db-admin` | `tcg_db_admin` | `8081` | Adminer opcional para revisar MySQL |
| `mobile-tools` | `tcg_mobile_tools` | ninguno | Tooling Flutter/Dart opcional |

La app Flutter no se ejecuta como servidor desde Docker Compose. Para emulador o dispositivo real sigue siendo recomendable usar el SDK de Flutter local. El servicio `mobile-tools` existe solo para comandos reproducibles como `flutter pub get`, `flutter analyze`, `flutter test` o `dart run build_runner`.

El servicio `db-admin` esta bajo el perfil `tools`; no se levanta por defecto con el stack normal.

Los servicios principales incluyen healthchecks para ordenar el arranque local:

- `db`: comprueba MySQL con `mysqladmin ping`
- `redis`: comprueba Redis con `redis-cli ping`
- `php`: comprueba que PHP-FPM escucha en el puerto `9000`
- `nginx`: valida la configuracion activa con `nginx -t`
- `web`: comprueba HTTP interno en Astro

## URLs locales

- Frontend Astro: <http://localhost:4321>
- Estado del starter: <http://localhost:4321/admin/estado>
- WordPress REST API: <http://localhost:8080/wp-json/>
- API health: <http://localhost:8080/wp-json/tcg/v1/health>
- WordPress admin: <http://localhost:8080/wp/wp-admin/>
- Mailpit: <http://localhost:8025>
- Adminer MySQL opcional: <http://localhost:8081>

Credenciales locales iniciales de WordPress:

```text
Usuario: admin
Password: admin
Email: admin@test.com
```

Estas credenciales solo son para desarrollo local.

## Requisitos

- Docker Desktop instalado y en ejecucion para backend/web
- Docker Compose disponible desde terminal para backend/web
- Flutter SDK instalado si vas a ejecutar `apps/mobile` en emulador o dispositivo real
- En Windows, puede ser necesario ejecutar la terminal con permisos suficientes para acceder al Docker Engine

Para backend y web no hace falta instalar PHP, Composer, MySQL, Node ni Astro en la maquina local. Todo eso corre dentro de contenedores.

Para comandos de analisis/test de Flutter puedes usar Docker con el perfil `mobile`, sin instalar Flutter localmente. Para ejecutar la app en Android/iOS, el SDK local sigue siendo la opcion mas practica.

## Arranque rapido

Desde la raiz del proyecto:

```sh
docker compose up -d --build
```

Tambien puedes usar los scripts utilitarios de la raiz:

```sh
npm run start
npm run status
npm run logs
npm run web:build
npm run backend:plugins
npm run db:ui
```

La primera ejecucion puede tardar porque descarga imagenes Docker, instala dependencias de Node dentro del volumen `web_node_modules` y prepara las dependencias Composer del backend dentro de volumenes Docker.

Para ver el estado:

```sh
docker compose ps
```

Para ver logs:

```sh
docker compose logs -f
```

Logs de un servicio concreto:

```sh
docker compose logs -f php
docker compose logs -f web
```

Para parar el entorno:

```sh
docker compose down
```

Para borrar tambien volumenes de datos:

```sh
docker compose down -v
```

Esto elimina la base de datos MySQL, Redis, `node_modules` del frontend, las caches de mobile y los volumenes internos `vendor`/`web/wp` del backend. Usarlo solo si quieres reiniciar el entorno desde cero.

## Estructura del proyecto

```text
tcg-platform/
  apps/
    backend/          WordPress Bedrock
    web/              Frontend Astro
    mobile/           App Flutter
  docker/
    nginx/            Configuracion Nginx
    php/              Imagen PHP personalizada e init.sh
  docker-compose.yml
  README.md
```

## Backend WordPress Bedrock

Ruta principal:

```text
apps/backend
```

Configuracion local de Bedrock:

```text
apps/backend/.env
```

Valores actuales:

```text
DB_NAME=wordpress
DB_USER=wordpress
DB_PASSWORD=wordpress
DB_HOST=db

WP_REDIS_HOST=redis
WP_REDIS_PORT=6379
WP_REDIS_DATABASE=0
WP_REDIS_PREFIX=tcg-platform

WP_MAIL_SMTP_HOST=mailpit
WP_MAIL_SMTP_PORT=1025
WP_MAIL_FROM=no-reply@tcg-platform.local
WP_MAIL_FROM_NAME=TCG Platform

WP_HOME=http://localhost:8080
WP_SITEURL=${WP_HOME}/wp
WP_LOCALE=es_ES
```

El servicio `php` usa una imagen propia definida en:

```text
docker/php/Dockerfile
```

Incluye:

- PHP 8.3 FPM
- Composer
- WP-CLI
- Extensiones `pdo`, `pdo_mysql`, `mysqli`, `zip`, `intl`, `redis`
- Cliente MySQL
- OPcache configurado para desarrollo local

Plugins gestionados por Composer:

- Redis Object Cache
- WooCommerce
- Advanced Custom Fields
- Fluent Forms

El entrypoint del contenedor PHP es:

```text
docker/php/init.sh
```

Ese script:

- Entra en `/var/www/html`
- Instala dependencias Composer si el volumen `vendor` esta vacio
- Espera a que MySQL acepte conexiones
- Comprueba con WP-CLI si WordPress esta instalado en la base de datos
- Instala WordPress si la base esta vacia
- Configura permalinks para que `/wp-json` y las rutas REST funcionen correctamente
- Activa los plugins base si estan disponibles
- Instala traducciones del core y plugins para `WP_LOCALE`
- Ejecuta la semilla demo inicial si `WP_DEMO_SEED` no esta desactivado
- Crea el marcador local `.initialized`
- Arranca `php-fpm`

El marcador `.initialized` es solo una pista local de runtime y esta ignorado por Git. El bootstrap real no depende de ese archivo: siempre pregunta a WordPress si la base esta instalada. Esto evita que un clon nuevo arranque contra una base vacia pensando que ya estaba inicializada.

### Montaje optimizado en Windows

Para evitar que WordPress lea miles de ficheros PHP directamente desde el bind mount de Windows, Docker Compose monta `apps/backend` y despues superpone dos volumenes Linux internos:

```text
backend_vendor -> /var/www/html/vendor
backend_wp_core -> /var/www/html/web/wp
backend_plugins -> /var/www/html/web/app/plugins
```

El motivo es que WordPress y Bedrock hacen muchas lecturas pequenas durante cada bootstrap: Composer autoload, core, plugins, mu-plugins, configuracion y comprobaciones de archivos. En Docker Desktop sobre Windows, leer esas carpetas desde un bind mount puede ser mucho mas lento que leerlas desde un volumen Linux interno. Mantener `vendor`, `web/wp` y los plugins gestionados por Composer dentro de Docker reduce ese coste sin perder edicion en caliente del codigo propio.

Asi el codigo editable sigue en el host, pero las carpetas mas pesadas para el bootstrap de WordPress viven dentro de Docker:

- `apps/backend/web/app`: contenido editable de Bedrock, excepto `plugins`, que queda superpuesto por volumen Docker
- `apps/backend/config`: configuracion de Bedrock
- `apps/backend/.env`: variables locales
- `vendor`: volumen Docker, instalado por Composer dentro del contenedor
- `web/wp`: volumen Docker, WordPress core instalado por Composer dentro del contenedor
- `web/app/plugins`: volumen Docker, plugins instalados por Composer dentro del contenedor

Si cambias `apps/backend/composer.json` o `apps/backend/composer.lock`, actualiza el volumen desde el contenedor:

```sh
docker compose exec php composer install --no-interaction --prefer-dist --optimize-autoloader
```

No edites `vendor`, `web/wp` ni `web/app/plugins` desde Windows esperando que afecte al runtime: en Docker quedan tapadas por los volumenes internos. Esta separacion mejora mucho los tiempos locales en Windows y se parece mas a como funcionara en un servidor Linux real.

### Plugins WordPress

En Bedrock los plugins se instalan por Composer, no desde el instalador visual de WordPress. Esto hace que cualquier persona pueda reconstruir el proyecto con las mismas versiones desde `composer.json` y `composer.lock`.

Plugins base instalados:

```text
wpackagist-plugin/redis-cache
wpackagist-plugin/woocommerce
wpackagist-plugin/advanced-custom-fields
wpackagist-plugin/fluentform
```

Para instalar un plugin nuevo:

```sh
docker compose exec php composer require wpackagist-plugin/nombre-del-plugin
docker compose exec php wp plugin activate nombre-del-plugin --allow-root
```

Para actualizar dependencias ya definidas:

```sh
docker compose exec php composer install --no-interaction --prefer-dist --optimize-autoloader
```

WooCommerce queda disponible para catalogo y productos desde el admin de WordPress y desde endpoints REST como:

```text
http://localhost:8080/wp-json/wp/v2/product
http://localhost:8080/wp-json/wc/store/v1/products
```

ACF permite definir campos personalizados desde WordPress. Para consumir esos campos desde Astro o Flutter, marca los grupos/campos necesarios como visibles en REST cuando corresponda. Si en el futuro necesitas ACF Pro, no se instala desde WPackagist publico: requiere licencia y repositorio Composer privado o un flujo privado equivalente.

Fluent Forms queda disponible para formularios gestionados desde WordPress. En una implementacion real conviene exponer solo los formularios necesarios al frontend y validar cada envio con permisos, rate limit, captcha/honeypot o doble opt-in segun el caso.

### Hardening headless

El starter incluye un mu-plugin de endurecimiento en `apps/backend/web/app/mu-plugins/tcg-hardening.php`:

- Redirige el frontend publico de WordPress hacia Astro.
- Reserva `wp-admin` para administradores y gestores de tienda.
- Limita al `shop_manager` a gestion operativa de WooCommerce/productos/pedidos.
- Oculta menus internos como temas, plugins, ajustes, usuarios y ACF para gestores de tienda.
- Desactiva comentarios, pingbacks, trackbacks, XML-RPC y endpoints REST de comentarios.
- Mantiene plugins/temas gestionados por Composer, no desde el panel.

La regla base es que WordPress sea fuente de datos y gestion interna, mientras que la experiencia publica viva en Astro/Flutter.

El idioma por defecto es `es_ES`. El core y las traducciones disponibles de plugins se instalan desde WP-CLI durante el arranque. Los ficheros descargados en `web/app/languages` no se versionan porque son artefactos regenerables.

La plantilla incluye seeds demo para dejar un entorno util desde el primer arranque:

```sh
npm run backend:seed
```

El primer `docker compose up -d --build` ejecuta `scripts/seed-demo-all.php` por defecto. Esto crea contenido de ejemplo, un catalogo demo de WooCommerce y usuarios base si no existen.

El seed de tienda crea categorias, etiquetas, atributos globales, marcas como atributo, cupones y productos simples/variables. El catalogo incluye casos pensados para probar la tienda: productos destacados, en rebaja, con stock, bajo stock, agotados y en reserva/backorder.

Usuarios base:

```text
admin_demo      admin.demo@example.test       administrator
vendedor_demo   vendedor.demo@example.test    shop_manager
cliente_demo    cliente.demo@example.test     customer
```

Password demo:

```text
PasswordDemo123!
```

Para arrancar una instalacion limpia sin contenido demo, define:

```env
WP_DEMO_SEED=false
```

Puedes volver a lanzar los seeds manualmente con `npm run backend:seed` o con los comandos separados `npm run seed:shop`, `npm run seed:blog` y `npm run seed:users`.

## Frontend Astro

Ruta principal:

```text
apps/web
```

El servicio `web` usa `node:22-alpine`, monta `apps/web` en `/app`, instala dependencias y ejecuta:

```sh
npm run dev -- --host 0.0.0.0
```

Variable expuesta al frontend:

```text
PUBLIC_WORDPRESS_API_URL=http://localhost:8080/wp-json
PUBLIC_ENABLE_SHOP=true
PUBLIC_ENABLE_BLOG=true
```

La web esta preparada como plantilla modular. Puedes ocultar tienda o blog por entorno sin quitar WordPress/WooCommerce del backend:

```text
PUBLIC_ENABLE_SHOP=false
PUBLIC_ENABLE_BLOG=false
```

Scripts disponibles:

```sh
docker compose exec web npm run dev
docker compose exec web npm run build
docker compose exec web npm run preview
```

Normalmente no hace falta ejecutar `npm run dev` a mano porque Compose ya lo arranca.

## App mobile Flutter

Ruta principal:

```text
apps/mobile
```

Nombre tecnico del paquete:

```text
tcg_platform_mobile
```

Identificador nativo Android:

```text
com.tcgplatform.mobile
```

La app vive dentro del monorepo porque forma parte del mismo producto y consume el mismo backend WordPress. Esto permite mantener juntos:

- Backend/API
- Frontend web
- Cliente mobile
- Documentacion de desarrollo
- Contratos de endpoints y modelos futuros

Flutter se ejecuta fuera de Docker Compose:

```sh
cd apps/mobile
flutter pub get
flutter run --flavor development --target lib/main_development.dart
```

Tambien existe un contenedor opcional de herramientas Flutter/Dart:

```sh
docker compose --profile mobile run --rm mobile-tools flutter --version
docker compose --profile mobile run --rm mobile-tools flutter pub get
docker compose --profile mobile run --rm mobile-tools flutter analyze
docker compose --profile mobile run --rm mobile-tools flutter test
```

Generar codigo con `build_runner` desde Docker:

```sh
docker compose --profile mobile run --rm mobile-tools dart run build_runner build --delete-conflicting-outputs
```

El servicio usa por defecto:

```text
ghcr.io/cirruslabs/flutter:stable
```

Puedes cambiar la imagen sin tocar Compose:

```sh
FLUTTER_DOCKER_IMAGE=ghcr.io/cirruslabs/flutter:3.38.3 docker compose --profile mobile run --rm mobile-tools flutter --version
```

La app mobile ya esta renombrada desde la plantilla original a `tcg_platform_mobile`. Los imports Dart usan `package:tcg_platform_mobile/...` y Android usa `com.tcgplatform.mobile`.

### API local desde Flutter

La app usa `NetworkConstants.baseUrlDev`, configurado por defecto para Android Emulator:

```text
http://10.0.2.2:8080/wp-json
```

Equivalencias habituales:

- Android Emulator: `http://10.0.2.2:8080/wp-json`
- iOS Simulator: `http://localhost:8080/wp-json`
- Dispositivo fisico: `http://IP_LOCAL_DEL_PC:8080/wp-json`

Puedes sobrescribir la URL al lanzar Flutter:

```sh
flutter run \
  --flavor development \
  --target lib/main_development.dart \
  --dart-define=TCG_API_URL=http://192.168.1.50:8080/wp-json
```

La app mobile usa una API propia de WordPress bajo `/wp-json/tcg/v1`. Esa capa vive como mu-plugin en `apps/backend/web/app/mu-plugins/tcg-api/tcg-api.php` y usa usuarios nativos de WordPress como fuente comun para web y app.

Endpoints iniciales:

```text
GET  /wp-json/tcg/v1/health
POST /wp-json/tcg/v1/register
POST /wp-json/tcg/v1/login
GET  /wp-json/tcg/v1/me
POST /wp-json/tcg/v1/me
POST /wp-json/tcg/v1/me/password
POST /wp-json/tcg/v1/logout
GET  /wp-json/tcg/v1/sessions
DELETE /wp-json/tcg/v1/sessions/{id}
POST /wp-json/tcg/v1/2fa/setup
POST /wp-json/tcg/v1/2fa/enable
POST /wp-json/tcg/v1/2fa/disable
POST /wp-json/tcg/v1/2fa/verify
POST /wp-json/tcg/v1/password/forgot
POST /wp-json/tcg/v1/password/reset
POST /wp-json/tcg/v1/email/verify
POST /wp-json/tcg/v1/email/resend
GET  /wp-json/tcg/v1/wishlist
POST /wp-json/tcg/v1/wishlist
DELETE /wp-json/tcg/v1/wishlist/{product_id}
GET  /wp-json/tcg/v1/cart
POST /wp-json/tcg/v1/cart
PATCH /wp-json/tcg/v1/cart/{product_id}
DELETE /wp-json/tcg/v1/cart/{product_id}
DELETE /wp-json/tcg/v1/cart
POST /wp-json/tcg/v1/cart/merge
POST /wp-json/tcg/v1/checkout
GET  /wp-json/tcg/v1/orders
GET  /wp-json/tcg/v1/admin/sales
```

El 2FA usa TOTP compatible con aplicaciones autenticadoras. Al activarlo, la web muestra QR, secreto manual y codigos de recuperacion de un solo uso. Los codigos solo se muestran al activar y se guardan hasheados.

La autenticacion no usa `wp-login.php` directamente. La API valida credenciales contra usuarios de WordPress y emite tokens opacos. El token solo se muestra una vez al cliente; en base de datos se guarda hasheado en la tabla `wp_tcg_api_tokens`, con expiracion y revocacion.

Para Flutter se usa `Authorization: Bearer ...`. Para Astro, el backend establece una cookie `tcg_platform_session` con `HttpOnly`, `SameSite=Lax` y `Secure` cuando el entorno usa HTTPS. Asi el navegador no necesita guardar el token en `localStorage`.

Por defecto se mantiene una sesion activa por `device_name`. Cada nuevo login o registro revoca tokens anteriores del mismo dispositivo, pero no cierra otros dispositivos. Por ejemplo, un login web no invalida la app mobile, pero un nuevo login web invalida la sesion web anterior.

Esta API debe ser tambien la base para Astro cuando necesite trabajar con usuario autenticado. La web puede consumir contenido publico con endpoints nativos de WordPress (`/wp-json/wp/v2/...`) y usar `/wp-json/tcg/v1/...` para login, cuenta, wishlist, compras, ventas o cualquier dato privado compartido con la app.

La API propia vive como mu-plugin de aplicacion y se puede ampliar por modulos de dominio dentro de `apps/backend/web/app/mu-plugins/tcg-api/modules`. Wishlist usa este patron con `TCG_Platform_API_Wishlist`: guarda relaciones `user_id` + `product_id` en la tabla `wp_tcg_wishlist_items`, mientras que nombre, precio, imagen, enlace y stock se leen desde WooCommerce al responder. Cart usa `TCG_Platform_API_Cart` con la tabla `wp_tcg_cart_items`, guarda `user_id` + `product_id` + `quantity`, valida producto/stock antes de persistir y expone `/cart/merge` para fusionar el carrito invitado al iniciar sesion o registrarse. Checkout usa `TCG_Platform_API_Checkout` para convertir el carrito autenticado en un pedido real de WooCommerce en entorno local de pruebas. Orders usa `TCG_Platform_API_Orders` para exponer pedidos del usuario y resumen de ventas backoffice desde WooCommerce.

Buenas practicas aplicadas en la capa inicial:

- Usuarios reales de WordPress mediante `wp_insert_user()` y `wp_authenticate()`.
- Tokens opacos de alta entropia con `random_bytes()`.
- Tokens guardados como HMAC SHA-256, nunca en claro.
- Expiracion de token y revocacion en logout.
- Cookie `HttpOnly` para Astro, evitando exponer el token al JavaScript de navegador.
- Doble factor TOTP opcional por usuario, con challenge temporal antes de emitir sesion.
- Codigos de recuperacion 2FA de un solo uso y comando WP-CLI para reset administrativo.
- Rate limit basico por email + IP en login.
- Errores genericos de login para no facilitar enumeracion.
- Rutas REST namespaced bajo `tcg/v1` y con `permission_callback`.

Rutas Astro iniciales para autenticacion:

```text
/login
/registro
/perfil
/recuperar
/verificar-email
```

La vista `/perfil` funciona como area de cuenta base con pestanas:

```text
Resumen
Datos personales
Seguridad
Sesiones
```

Permite editar nombre/apellidos/nombre visible, cambiar contrasena, activar/desactivar 2FA, ver codigos de recuperacion al activar y cerrar sesiones activas.

Las rutas `/recuperar` y `/verificar-email` completan el flujo base de cuenta con recuperacion de contrasena por email y verificacion de email local mediante Mailpit.

Rutas Astro iniciales para tienda:

```text
/tienda
/producto?slug=...
/carrito
/checkout
/compra-realizada
/wishlist
/mis-pedidos
/inventario
/ventas
/admin
/usuarios
```

Estas rutas son una base visual y funcional ligera. La tienda lee productos desde WooCommerce Store API, el producto usa `slug` por query string para no depender de rutas generadas en build, y el carrito guarda una seleccion local temporal solo para invitados. Al iniciar sesion o registrarse, el carrito invitado se fusiona contra `/wp-json/tcg/v1/cart/merge` y pasa a quedar vinculado a la cuenta. Wishlist requiere sesion y se persiste en WordPress mediante `/wp-json/tcg/v1/wishlist`. Checkout crea un pedido real de WooCommerce mediante `/wp-json/tcg/v1/checkout` usando el metodo local `tcg_local_test`, deja el pedido en estado `on-hold`, reduce stock y muestra la confirmacion con el pedido devuelto por WooCommerce. El checkout local recoge telefono, direccion completa, notas y metodo de entrega local/recogida; despues guarda esos datos en billing/shipping meta del usuario para precargar futuras compras. Mis pedidos consume `/wp-json/tcg/v1/orders`; ventas consume `/wp-json/tcg/v1/admin/sales` con permisos backoffice.

Regla de stock para el carrito persistente: el carrito representa intencion, no reserva inventario. La API valida disponibilidad/cantidad al guardar y vuelve a validar justo antes de crear pedido. En el checkout local de pruebas se reduce stock al crear el pedido WooCommerce; si mas adelante se usa reserva temporal o pasarela real, debe ocurrir en pedido pendiente/draft o durante checkout, no al anadir al carrito.

`/inventario`, `/ventas`, `/admin` y `/usuarios` son vistas de backoffice frontend. Estan pensadas como lectura, resumen o lanzadera hacia WordPress, no como sustituto completo de `wp-admin`. La regla de la plantilla es: WordPress gestiona contenido, productos, stock, pedidos, usuarios y configuracion; Astro muestra datos utiles, flujos de usuario y acciones controladas que tengan sentido fuera del panel. El listado de usuarios es solo para administradores y enlaza cada fila al editor real de WordPress.

## Estructura Astro

```text
apps/web/src/
  assets/             Imagenes, fuentes y recursos importables
  components/         Componentes reutilizables
  config/             Configuracion compartida del sitio
  content/            Contenido local en Markdown
  layouts/            Layouts de pagina
  lib/                Funciones auxiliares y clientes de API
  pages/              Rutas del sitio
  scripts/            Scripts de navegador reutilizables
  styles/             CSS global
  types/              Tipos TypeScript compartidos
  content.config.ts   Configuracion de colecciones Astro
```

Astro reserva especialmente:

- `src/pages`: rutas basadas en archivos
- `src/content` y `src/content.config.ts`: colecciones de contenido

El resto son carpetas convencionales para mantener el proyecto ordenado.

Ejemplos actuales:

- `src/layouts/BaseLayout.astro`: HTML base, metadata y estilos globales
- `src/components/ApiStatus.astro`: comprueba la REST API de WordPress
- `src/components/FeatureCard.astro`: tarjeta reutilizable
- `src/components/Pagination.astro`: controles reutilizables de paginacion
- `src/content/modules/*.md`: contenido local usado en la home
- `src/config/site.ts`: nombre del sitio y URL de API
- `src/lib/wordpress.ts`: ejemplo de cliente para WordPress
- `src/lib/pagination.ts`: helper de paginacion local para listados ya renderizados

## Comandos utiles

Scripts desde la raiz:

```sh
npm run start
npm run stop
npm run status
npm run logs
npm run logs:php
npm run logs:web
npm run backend:composer
npm run backend:plugins
npm run backend:seed
npm run backend:redis
npm run backend:2fa-reset -- admin
npm run db:ui
npm run mail:ui
npm run setup:demo
npm run db:backup
npm run db:restore -- backups/archivo.sql
npm run doctor
npm run web:build
npm run mobile:analyze
npm run mobile:test
```

Mailpit captura emails locales enviados por WordPress:

```sh
npm run mail:ui
```

Interfaz:

```text
http://localhost:8025
```

Resetear 2FA de un usuario desde WP-CLI:

```sh
npm run backend:2fa-reset -- admin
npm run backend:2fa-reset -- admin@test.com
```

Backups locales de base de datos:

```sh
npm run db:backup
npm run db:restore -- backups/tcg-platform-YYYYMMDD-HHMMSS.sql
```

`db:restore` pide escribir `RESTORE` antes de tocar la base de datos local.

Chequeo general del starter:

```sh
npm run doctor
```

Seeds separados:

```sh
npm run seed
npm run seed:shop
npm run seed:blog
npm run seed:users
```

Adminer se arranca solo cuando hace falta:

```sh
npm run db:ui
```

Credenciales locales:

```text
Servidor: db
Usuario: wordpress
Password: wordpress
Base de datos: wordpress
```

Entrar al contenedor PHP:

```sh
docker compose exec php bash
```

Ejecutar WP-CLI:

```sh
docker compose exec php wp option get siteurl --allow-root
docker compose exec php wp user list --allow-root
docker compose exec php wp redis status --allow-root
```

Validar build de Astro:

```sh
docker compose exec web npm run build
```

Trabajar con Flutter:

```sh
cd apps/mobile
flutter pub get
flutter analyze
flutter test
flutter run --flavor development --target lib/main_development.dart
```

Trabajar con Flutter desde Docker:

```sh
docker compose --profile mobile run --rm mobile-tools flutter pub get
docker compose --profile mobile run --rm mobile-tools flutter analyze
docker compose --profile mobile run --rm mobile-tools flutter test
```

Comprobar endpoints:

```sh
curl http://localhost:8080/wp-json/
curl http://localhost:4321/
```

En PowerShell:

```powershell
Invoke-WebRequest -UseBasicParsing http://localhost:8080/wp-json/
Invoke-WebRequest -UseBasicParsing http://localhost:4321/
```

## Datos persistentes

Docker Compose define estos volumenes:

- `db_data`: datos de MySQL
- `redis_data`: datos persistentes de Redis
- `backend_vendor`: dependencias Composer del backend
- `backend_wp_core`: WordPress core de Bedrock
- `backend_plugins`: plugins WordPress instalados por Composer
- `web_node_modules`: dependencias instaladas del frontend
- `mobile_pub_cache`: cache de paquetes Pub para el contenedor Flutter
- `mobile_gradle_cache`: cache Gradle para builds Android desde el contenedor

Esto permite reiniciar contenedores sin perder la base de datos ni reinstalar paquetes en cada arranque. En Windows tambien evita que el bootstrap de WordPress dependa de leer `vendor`, `web/wp` y plugins grandes como WooCommerce desde el sistema de archivos del host.

## Notas de desarrollo

- El frontend se sirve en modo desarrollo con hot reload.
- El backend se sirve mediante Nginx + PHP-FPM.
- Bedrock vive montado desde el host, pero `vendor`, `web/wp` y `web/app/plugins` se superponen con volumenes Docker para mejorar el rendimiento en Windows.
- Los cambios en `apps/backend/web/app`, `apps/backend/config` y `apps/backend/.env` se reflejan en el contenedor.
- Astro vive montado desde el host, por lo que los cambios en `apps/web/src` se reflejan en el navegador.
- Flutter vive en `apps/mobile`. El SDK local se usa para ejecutar en emulador/dispositivo; Docker queda como tooling opcional.
- `npm audit` puede mostrar vulnerabilidades moderadas en dependencias del frontend. No bloquea el entorno local, pero conviene revisarlo antes de produccion.
- La guia de hardening y reglas para nuevas rutas vive en `SECURITY.md`.

## Estado actual

El entorno ha sido verificado con:

```sh
docker compose up -d --build
docker compose ps
docker compose exec web npm run build
docker compose --profile mobile run --rm mobile-tools flutter --version
docker compose --profile mobile run --rm mobile-tools flutter pub get
docker compose --profile mobile run --rm mobile-tools flutter analyze
docker compose --profile mobile run --rm mobile-tools flutter test
docker compose config
```

Y responde correctamente en:

```text
http://localhost:4321
http://localhost:8080/wp-json/
```

`flutter analyze` y `flutter test` pasan correctamente desde `mobile-tools`.
