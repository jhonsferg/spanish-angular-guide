# Capítulo 2 - Parte 2: Angular CLI a fondo: comandos esenciales y schematics

> **Parte 2 de 4** · Capítulo 2 · PARTE I - Primeros Pasos con Angular

Angular CLI es mucho más que un generador de proyectos. Es el sistema nervioso del flujo de trabajo diario con Angular: crea, compila, sirve, prueba, analiza y migra. Conocer bien sus comandos y flags no es un lujo; es la diferencia entre un flujo de trabajo fluido y uno lento y manual. Vamos a cubrir todos los comandos que usarás en el día a día.

## El comando `ng generate`: creando bloques con un comando

`ng generate` (abreviado `ng g`) es el comando que más usarás después de `ng serve`. Crea los archivos de cada bloque de Angular siguiendo las convenciones de nombres del framework: kebab-case para los nombres de archivo, PascalCase para los nombres de clase.

**Componentes:**

```bash
# Crea src/app/features/productos/lista-productos/lista-productos.component.ts
ng generate component features/productos/lista-productos

# Atajo equivalente
ng g c features/productos/lista-productos

# Con flags útiles
ng g c features/productos/lista-productos --skip-tests --inline-style
```

La CLI crea cuatro archivos por defecto: `.ts`, `.html`, `.scss` y `.spec.ts`. Los flags `--skip-tests` omite el spec y `--inline-style` escribe los estilos directamente en el decorador en lugar de un archivo separado.

**Servicios:**

```bash
# Crea src/app/core/services/auth.service.ts
ng generate service core/services/auth

# El flag --skip-tests omite el archivo spec
ng g s core/services/auth --skip-tests
```

**Pipes:**

```bash
# Crea src/app/shared/pipes/formato-precio.pipe.ts
ng generate pipe shared/pipes/formato-precio
ng g p shared/pipes/formato-precio
```

**Directivas:**

```bash
# Crea src/app/shared/directives/resaltar.directive.ts
ng generate directive shared/directives/resaltar
ng g d shared/directives/resaltar
```

**Guards:**

```bash
# Crea src/app/core/guards/auth.guard.ts
ng generate guard core/guards/auth

# La CLI preguntará qué tipo de guard: canActivate, canDeactivate, canMatch, canLoad
ng g guard core/guards/auth --functional
```

**Interfaces y enums:**

```bash
# Crea src/app/core/interfaces/producto.interface.ts
ng generate interface core/interfaces/producto

# Crea src/app/core/enums/estado-pedido.enum.ts
ng generate enum core/enums/estado-pedido
ng g e core/enums/estado-pedido
```

## El flag `--dry-run`: simular antes de ejecutar

Cualquier comando de `ng generate` acepta el flag `--dry-run` (o `-d`), que simula la operación sin crear ningún archivo. Es extremadamente útil para verificar que los archivos se crearán en la ubicación correcta antes de ejecutar el comando de verdad:

```bash
# Simular la creación de un componente sin escribir nada
ng g c features/usuarios/perfil-usuario --dry-run

# Salida típica:
# CREATE src/app/features/usuarios/perfil-usuario/perfil-usuario.component.ts (300 bytes)
# CREATE src/app/features/usuarios/perfil-usuario/perfil-usuario.component.html (35 bytes)
# CREATE src/app/features/usuarios/perfil-usuario/perfil-usuario.component.scss (0 bytes)
# CREATE src/app/features/usuarios/perfil-usuario/perfil-usuario.component.spec.ts (680 bytes)
# NOTE: The "dryRun" flag means no changes were made.
```

La última línea confirma que nada fue modificado. Cuando estés satisfecho con la ruta, ejecuta el mismo comando sin `--dry-run`.

## `ng build`: compilando para producción

```bash
# Build de producción (optimizado, minificado, tree-shaken)
ng build

# Build de desarrollo (más rápido, con source maps)
ng build --configuration development

# Analizar el tamaño del bundle (requiere source-map-explorer)
ng build --source-map
```

La salida de `ng build` va al directorio `dist/nombre-del-proyecto/browser/`. En producción, Angular aplica múltiples optimizaciones: tree shaking para eliminar código no usado, minificación, compresión de assets y división del bundle en chunks para carga diferida.

Una salida típica de `ng build` muestra algo así:

```
Initial chunk files   | Names         |  Raw size | Estimated transfer size
main-XXXXXXXX.js      | main          | 217.45 kB |                56.84 kB
polyfills-YYYYYYYY.js | polyfills     |  32.69 kB |                10.64 kB
styles-ZZZZZZZZ.css   | styles        |   0 bytes |                 0 bytes

Application bundle generation complete. [3.241 seconds]
```

## `ng test`: ejecutando las pruebas

```bash
# Ejecutar todas las pruebas en modo watch
ng test

# Ejecutar pruebas una sola vez (útil en CI/CD)
ng test --watch=false

# Ejecutar pruebas con cobertura de código
ng test --coverage
```

Por defecto, Angular configura Jasmine como framework de testing y Karma como runner. Si prefieres Jest (más rápido, sin necesidad de navegador), se puede configurar con un schematic de la comunidad.

## `ng lint`: analizando la calidad del código

```bash
# Analizar el proyecto completo
ng lint

# Corregir automáticamente los problemas que tengan solución automática
ng lint --fix
```

Angular CLI no incluye ESLint por defecto en Angular 17+, pero puedes añadirlo con:

```bash
ng add @angular-eslint/schematics
```

Esto configura ESLint con las reglas recomendadas para proyectos Angular y añade el comando `ng lint` al workspace.

## ¿Qué son los schematics?

Los schematics son programas que describen transformaciones sobre un árbol de archivos. Cuando ejecutas `ng generate component`, estás usando un schematic: un programa que sabe cómo crear los archivos correctos en las ubicaciones correctas, con el contenido apropiado para un componente Angular.

Los schematics no son exclusivos del equipo de Angular. Cualquier librería puede publicar sus propios schematics. Por ejemplo, cuando instalas Angular Material (`ng add @angular/material`), se ejecuta un schematic que modifica `angular.json`, añade los estilos globales necesarios y configura el tema automáticamente. Todo eso ocurre sin que tengas que editar manualmente un solo archivo.

```bash
# ng add ejecuta el schematic de instalación de una librería
ng add @angular/material
ng add @ngrx/store
ng add @angular-eslint/schematics

# ng update ejecuta los schematics de migración de una librería
ng update @angular/core @angular/cli
```

`ng update` es especialmente poderoso: no solo actualiza las dependencias en `package.json`, sino que ejecuta schematics de migración que modifican tu código fuente para adaptarlo a las APIs nuevas o deprecadas de la nueva versión. Este es el mecanismo que hace que las actualizaciones de Angular sean manejables incluso en proyectos grandes.

## Resumen de comandos diarios

| Comando | Atajo | Propósito |
|---|---|---|
| `ng generate component ruta/nombre` | `ng g c` | Crear componente |
| `ng generate service ruta/nombre` | `ng g s` | Crear servicio |
| `ng generate pipe ruta/nombre` | `ng g p` | Crear pipe |
| `ng generate directive ruta/nombre` | `ng g d` | Crear directiva |
| `ng generate guard ruta/nombre` | `ng g guard` | Crear guard |
| `ng generate interface ruta/nombre` | `ng g i` | Crear interfaz |
| `ng generate enum ruta/nombre` | `ng g e` | Crear enum |
| `ng serve` | - | Servidor de desarrollo |
| `ng build` | - | Compilar para producción |
| `ng test` | - | Ejecutar pruebas |
| `ng lint` | - | Analizar calidad del código |
| `ng add librería` | - | Instalar y configurar una librería |
| `ng update` | - | Actualizar Angular y migrar código |

## Puntos clave

- `ng generate` crea todos los bloques de Angular con convenciones de nombres correctas automáticamente
- `--dry-run` simula cualquier comando sin escribir archivos: úsalo siempre que tengas dudas sobre la ruta de destino
- `ng build` genera un bundle optimizado para producción con tree shaking y minificación integrados
- Los schematics son los programas que ejecutan `ng generate`, `ng add` y `ng update`; cualquier librería puede publicar los suyos
- `ng update` no solo actualiza versiones: ejecuta migraciones de código automáticas

## ¿Qué sigue?

En la Parte 3 definimos la estructura de carpetas recomendada para proyectos Angular reales: cómo organizar por features, qué va en `core`, qué va en `shared` y qué convenciones de nombres aplicar en todo el proyecto.
