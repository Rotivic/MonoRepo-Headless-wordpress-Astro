# AGENTS.md

## Cambios mínimos

- Mantén el diff lo más pequeño posible.
- No reformatees archivos completos si solo necesitas cambiar unas líneas.
- No cambies imports, nombres, comentarios, orden de métodos o estructura del archivo si no es necesario para la tarea.
- No hagas refactors oportunistas.
- No corrijas problemas no relacionados salvo que bloqueen la tarea.
- Si detectas una mejora no relacionada, menciónala al final en vez de aplicarla directamente.

## Objetivo
Este archivo define como debe trabajar una IA dentro de este proyecto Flutter para crear nuevas pantallas, nuevas features y nuevas integraciones con backend sin romper la coherencia del proyecto.

La prioridad no es "hacer que funcione de cualquier manera", sino mantener:
- la arquitectura existente
- el estilo visual definido en `DESIGN.md`
- el sistema de tema en `lib/theme`
- el flujo de traducciones en `lib/l10n`
- el patron de repositorios, DTOs, mappers, modelos, cubits y states
- la consistencia con Very Good CLI y `very_good_analysis`

Si en algun proyecto concreto hay diferencias respecto a este documento, manda siempre el codigo existente del proyecto sobre esta guia. La IA debe adaptarse al repositorio real, no forzar una arquitectura nueva.

## Regla principal
Antes de crear una pantalla o feature nueva:
1. revisa una feature existente similar
2. revisa `DESIGN.md` si hay decisiones visuales relevantes
3. revisa `lib/theme/*`
4. revisa `lib/l10n/arb/*`
5. sigue el patron ya presente en el proyecto

No inventes estructuras nuevas si ya existe una convencion valida.

## Stack y filosofia del proyecto
- Flutter + Material 3
- `flutter_bloc` para estado de presentacion
- `dio` + `retrofit` para networking
- `json_serializable` / `json_annotation` para DTOs
- `very_good_analysis` para linting
- estructura feature-first
- localizacion con `gen-l10n`
- soporte explicito para tema claro, oscuro y modo sistema

## Estructura estandar por feature
Cada feature debe vivir dentro de `lib/features/<feature_name>/`.

Estructura base recomendada:

```text
lib/features/<feature_name>/
  data/
    <feature>_repository.dart
    dtos/
      ...
    mappers/
      ...
  domain/
    models/
      ...
  presentation/
    cubit/
      <feature>_cubit.dart
      <feature>_state.dart
    view/
      <feature>_page.dart
      widgets/
        ...
```

Reglas:
- `data/` habla con el backend
- `dtos/` representa payloads y respuestas del backend
- `mappers/` convierte DTOs a modelos de dominio y viceversa
- `domain/models/` representa entidades limpias usadas por UI y logica
- `presentation/cubit/` orquesta la interaccion entre UI y repositorio
- `presentation/view/` contiene paginas y widgets propios de la feature

No metas logica de red en la UI.
No metas parsing JSON en cubits.
No metas widgets reutilizables de app dentro de una feature si realmente pertenecen a `core/ui/widgets`.

## Flujo para una nueva pantalla con backend
Cuando se cree una pantalla nueva con llamada al servidor, seguir este orden:

1. definir o localizar endpoint en `ApiClient`
2. crear DTOs necesarios en `data/dtos`
3. crear mappers en `data/mappers`
4. crear o ajustar modelo de dominio en `domain/models`
5. implementar repositorio de feature
6. implementar `Cubit` y `State`
7. crear la pagina y widgets auxiliares
8. registrar navegacion si aplica
9. Añadir textos a `app_es.arb` y `app_en.arb`
10. generar codigo si hay DTOs o l10n nuevos
11. Añadir tests minimos

## Networking
Todo acceso a API debe pasar por `ApiClient` y por un repositorio.

Reglas:
- usa `ApiClient` para declarar endpoints
- usa DTOs anotados con `@JsonSerializable()`
- usa `@JsonKey(name: 'backend_key')` cuando la API no siga naming Dart
- el repositorio transforma DTOs a modelos de dominio mediante mappers
- captura `DioException` en repositorio y traducelo a `NetworkException`
- la UI no debe conocer `DioException`
- el cubit no debe construir bodies HTTP directamente salvo casos triviales ya alineados con el proyecto

Patron esperado en repositorios:

```dart
try {
  final response = await apiClient.someCall(...);
  return response.toDomain();
} on DioException catch (e) {
  throw NetworkException.fromDioException(e);
}
```

Si una feature requiere sesion:
- usa `SessionStore`
- no dupliques almacenamiento de token o usuario
- no leas `FlutterSecureStorage` directamente desde la feature

## Modelos, DTOs y mappers
Separacion obligatoria:

- DTO: refleja el backend, incluso si el naming o nullability no es ideal
- Model: refleja lo que la app necesita realmente
- Mapper: traduce entre ambas capas

Reglas:
- nombres de DTO con sufijo `Dto`
- nombres de mapper como extensiones del tipo `XxxDtoX` o equivalentes ya usados
- evita usar DTOs directamente en widgets o cubits
- los modelos de dominio deben ser lo mas limpios posible
- usa `copyWith` en modelos cuando la pantalla lo necesite

Si el backend devuelve estructuras paginadas:
- reutiliza el patron existente de `Paginated<T>`
- manten el patron de `loadInitial`, `refresh`, `loadMore`
- evita reemplazar toda la pantalla por loading global durante paginacion

## Estado de presentacion
El estado de pantalla se resuelve con `Cubit` + `State`.

Reglas:
- un cubit por responsabilidad de pantalla o flujo
- states simples, explicitos y legibles
- nombres tipicos: `Initial`, `Loading`, `Loaded`, `Empty`, `Success`, `Error`
- si hay paginacion, usa una variante `Loaded` con `isLoadingMore`
- si hay acciones puntuales, usa estados o listeners especificos segun el flujo

No introduzcas `ViewModel` si el proyecto usa `Cubit/State`.
Solo usa otra capa intermedia si el repositorio ya tiene esa convencion en ese proyecto.

Patron esperado:
- el cubit llama al repositorio
- transforma errores en estados consumibles por UI
- la vista escucha con `BlocListener` o `BlocConsumer`
- la vista renderiza con `BlocBuilder`

## UI y diseno
La UI debe respetar `DESIGN.md`, `brand_colors.dart`, `theme_tokens.dart`, `app_theme.dart`, `app_spacing.dart` y `app_shadows.dart`.

Reglas:
- usa `Theme.of(context)` y `theme.colorScheme`
- usa `theme.textTheme`
- usa `theme.spacing` para espaciados
- usa sombras desde `AppShadows` cuando aplique
- respeta claro y oscuro automaticamente
- no hardcodees colores, tamanos o tipografias si ya existe token o estilo equivalente
- prioriza widgets ya existentes en `core/ui/widgets`

Preferencias visuales del proyecto:
- look premium, limpio y sobrio
- superficies claras y estructura muy cuidada
- brand principal purpura `BrandColors.brand`
- bordes sutiles
- radios contenidos
- tipografia consistente con el tema
- fondos y contraste correctos tanto en light como dark

Si una pantalla es de autenticacion o comparte ese lenguaje visual:
- reutiliza `AuthBackground` si encaja con el patron real

Si necesitas spacing:
- no pongas numeros arbitrarios repetidos
- usa `theme.spacing.x8`, `x12`, `x16`, `x24`, `sectionGap`, etc.

## Tema claro y oscuro
Toda pantalla nueva debe verse bien en:
- `ThemeMode.light`
- `ThemeMode.dark`
- `ThemeMode.system`

Reglas:
- nunca asumas fondo blanco o texto negro
- usa `colorScheme.surface`, `onSurface`, `onSurfaceVariant`, `outline`, etc.
- evita colores fijos salvo branding o casos justificados
- si anades un componente custom, valida contraste en ambos modos

Si algo no encaja con dark mode:
- corrigelo desde tokens o desde el widget, no metiendo excepciones visuales aisladas sin criterio

## Traducciones y l10n
Toda string visible al usuario debe pasar por l10n.

Reglas:
- no hardcodees textos en widgets, snackbars, dialogs, empty states o botones
- anade claves nuevas en `lib/l10n/arb/app_es.arb` y `app_en.arb`
- usa nombres de clave por pantalla y proposito
- incluye `@description` cuando aporte contexto
- usa placeholders si el texto es dinamico
- consume traducciones con `context.l10n`

Convencion recomendada de claves:
- `<screen><Element><Purpose>`
- ejemplos:
  - `loginHeaderTitle`
  - `profileLabelTheme`
  - `documentsSignSubmit`

Tambien deben ir por l10n:
- errores de validacion
- mensajes de empty state
- CTA
- titulos de modal o bottom sheet
- mensajes de exito o error si son visibles al usuario

## Formularios
Para pantallas con formularios:
- usa `Form` con `GlobalKey<FormState>`
- usa `TextEditingController` y `FocusNode` si el flujo lo requiere
- valida en la UI antes de llamar al cubit
- usa widgets comunes como `CustomTextField` cuando encajen
- pon `Key` en campos y acciones importantes para facilitar tests
- deshabilita acciones mientras hay loading
- oculta teclado antes de enviar si mejora UX

Si hay reglas de validacion reutilizables en varias pantallas, extraerlas a `core` en vez de duplicarlas.

## Navegacion
Si la pantalla entra en el flujo principal:
- registra ruta en `lib/app/routes.dart`
- registra builder en `lib/app/view/app.dart`

Reglas:
- pasa argumentos tipados o claramente estructurados
- evita mapas ad hoc si un objeto o argumento explicito mejora claridad
- usa `pushReplacementNamed` o `pushNamedAndRemoveUntil` cuando el flujo lo requiera realmente

## Widgets reutilizables
Antes de crear un widget nuevo:
1. comprueba si ya existe en `core/ui/widgets`
2. comprueba si ya existe un patron similar en otra feature

Ubicacion:
- si solo sirve a una pantalla o feature: `presentation/view/widgets`
- si sirve a varias features: `core/ui/widgets`

Reglas:
- widgets pequenos y con una responsabilidad clara
- nombres explicitos
- evita paginas gigantes con mucho layout inline si se puede dividir de forma natural

## Tests

Cuando la tarea añada una feature completa, lógica de negocio, validaciones, llamadas a backend o cambios relevantes de estado, añade o actualiza tests siguiendo el patrón existente.

Prioridad:
- test del cubit para flujo feliz
- test del cubit para error de red
- test de widget para render básico
- test de widget para validación o interacción principal cuando aplique

No añadas tests artificiales o de poco valor solo por cumplir checklist.

Seguir el patron existente en `test/features/authentication/...`.

Reglas:
- usa `bloc_test`
- usa `mocktail`
- anade `Key`s a inputs y botones relevantes
- valida navegacion solo cuando sea parte del comportamiento principal
- usa l10n real en tests cuando el widget la consuma

## Generacion de codigo
Si se tocan DTOs o clases anotadas:
- ejecutar `dart run build_runner build --delete-conflicting-outputs`

Si se tocan ARB:
- ejecutar `flutter gen-l10n --arb-dir="lib/l10n/arb"`

La IA no debe editar archivos generados manualmente salvo necesidad muy justificada.

## Convenciones de implementacion
- sigue naming consistente con el proyecto
- usa imports claros
- manten widgets y metodos privados cuando no necesiten exposicion publica
- prefiere composicion frente a widgets monoliticos
- usa `const` cuando aplique
- evita comentarios obvios
- evita codigo "listo para todo" si la pantalla solo necesita un flujo claro

## Lo que no debe hacer la IA
- no introducir otra arquitectura porque "parece mejor"
- no usar Provider, Riverpod, MVVM o Clean Architecture completa si el proyecto no lo usa ya
- no hardcodear strings visibles
- no meter colores sueltos ignorando el tema
- no llamar a la API directamente desde la vista
- no usar DTOs directamente en UI
- no duplicar widgets ya existentes
- no crear helpers genericos innecesarios
- no mezclar logica de sesion con logica de presentacion
- no tocar codigo generado a mano si puede regenerarse

## Checklist para crear una pantalla nueva
Antes de dar una tarea por terminada, comprobar:

- la feature esta en la carpeta correcta
- la UI usa theme y spacing del proyecto
- funciona en modo claro y oscuro
- todas las strings visibles usan l10n
- la pantalla sigue el patron `repository -> cubit -> state -> view`
- los DTOs y mappers estan separados de los modelos
- los errores de red se transforman con `NetworkException`
- la navegacion esta registrada si aplica
- hay tests minimos
- no hay codigo inventado que rompa la coherencia del proyecto

## Instruccion final para la IA
Al crear una nueva pantalla en este proyecto:
- copia el patron de la feature mas cercana
- manten el estilo visual y arquitectonico existente
- resuelve el problema con el menor numero de decisiones nuevas posible
- si dudas entre dos enfoques, elige el que mas se parezca al codigo ya escrito
