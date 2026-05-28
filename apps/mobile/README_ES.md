# TCG Platform Mobile

ðŸ“– Leer en: [InglÃ©s](README.md) | EspaÃ±ol

---

## ðŸš€ Inicio rÃ¡pido

DespuÃ©s de clonar el repositorio, ejecuta:

```bash
flutter pub get
flutter run
```

---

## ðŸ› ï¸ Comandos comunes

### Instalar / Actualizar dependencias

DespuÃ©s de aÃ±adir o modificar paquetes en `pubspec.yaml`:

```bash
flutter pub get
```

Actualizar todas las dependencias:

```bash
flutter pub upgrade
```

Ver dependencias desactualizadas:

```bash
flutter pub outdated
```

---

### Comprobar entorno

Verifica Flutter:

```bash
flutter doctor
```

---

### Generar localizaciones

Si modificas los `.arb`:

```bash
flutter gen-l10n --arb-dir="lib/l10n/arb"
```

---

### Generar cÃ³digo (build_runner)

Si modificas modelos anotados:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

### Limpiar proyecto

Si hay problemas:

```bash
flutter clean
flutter pub get
```

---

### Ejecutar tests

Ejecutar tests:

```bash
flutter test
```

Con cobertura:

```bash
flutter test --coverage
```

---

![coverage][coverage_badge]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![Licencia: MIT][license_badge]][license_link]

Proyecto generado con [Very Good CLI][very_good_cli_link] ðŸ¤–

---

## Primeros pasos ðŸš€

Este proyecto incluye tres entornos:

- development
- staging
- production

Para ejecutar un entorno:

```sh
# Development
flutter run --flavor development --target lib/main_development.dart

# Staging
flutter run --flavor staging --target lib/main_staging.dart

# Production
flutter run --flavor production --target lib/main_production.dart
```

Funciona en iOS, Android, Web y Windows.

---

## Android Release

Este proyecto usa entrypoints Flutter por entorno, asi que para generar builds Android de release hay que usar `--flavor` y `--target` de forma explicita.

### 1. Generar la keystore

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkeypair -v -keystore C:\Workspace\APPS\keystores\tcg-platform-mobile.p12 -storetype PKCS12 -keyalg RSA -keysize 4096 -validity 10000 -alias key0
```

### 2. Configurar `android/key.properties`

Despues de generar la keystore, configura `android/key.properties` con:

- `storePassword`
- `keyPassword`
- `keyAlias`
- `storeFile`

`storeFile` debe apuntar al archivo `.p12` generado.

### 3. Generar el app bundle de produccion

```powershell
flutter build appbundle --release --flavor production --target lib/main_production.dart
```

### 4. Generar APKs de produccion separados por ABI

```powershell
flutter build apk --release --split-per-abi --flavor production --target lib/main_production.dart
```

Salidas habituales:

- `build/app/outputs/bundle/productionRelease/`
- `build/app/outputs/apk/production/release/`
- `build/app/outputs/flutter-apk/`

---

## iOS Release

Para generar la release de iOS en macOS, usa la terminal de VS Code desde la raiz del proyecto y deja que Flutter prepare el proyecto iOS antes de abrir Xcode.

### 1. Clonar el repositorio y abrirlo en VS Code en macOS

Abre la raiz del proyecto y usa la terminal integrada.

### 2. Comprobar el entorno Flutter

```bash
flutter doctor
```

### 3. Descargar dependencias

```bash
flutter pub get
```

### 4. Ejecutar una vez el flavor de produccion

```bash
flutter run --flavor production --target lib/main_production.dart
```

Este primer arranque es importante porque Flutter puede migrar y preparar automaticamente el proyecto iOS, incluyendo actualizaciones de compatibilidad con Xcode e integracion con Swift Package Manager.

### 5. Abrir el workspace de iOS en Xcode

```bash
open ios/Runner.xcworkspace
```

### 6. Revisar signing y configuracion Apple en Xcode

En Xcode, revisar:

- `Signing & Capabilities`
- `Team` de Apple
- version de la app
- el scheme `production` seleccionado arriba

### 7. Archivar, validar y subir desde Xcode

En Xcode:

- `Product > Archive`
- `Validate App`
- `Distribute App / Upload`

### 8. Subir al repositorio los cambios de configuracion iOS

Despues del primer arranque o migracion exitosa en iOS, revisa los cambios de configuracion generados y haz commit en el repositorio.

---

## Ejecutar tests

```sh
very_good test --coverage --test-randomize-ordering-seed random
```

```sh
genhtml coverage/lcov.info -o coverage/
open coverage/index.html
```

---

## Internacionalizacion

Archivos en:

```text
lib/l10n/arb/
```

---

[coverage_badge]: coverage_badge.svg
[flutter_localizations_link]: https://api.flutter.dev/flutter/flutter_localizations/flutter_localizations-library.html
[internationalization_link]: https://flutter.dev/docs/development/accessibility-and-localization/internationalization
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_cli_link]: https://github.com/VeryGoodOpenSource/very_good_cli
