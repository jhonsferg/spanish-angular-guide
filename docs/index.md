# Angular: La Guía en Español

La guía de Angular en español. Cubre Angular 17–22 desde los fundamentos hasta arquitecturas de nivel enterprise, con Signals, NgRx, SSR, micro-frontends y todo lo nuevo en Angular 20, 21 y 22.

Esta guía está escrita para desarrolladores hispanohablantes que quieren dominar Angular de verdad - no solo aprender la sintaxis, sino entender el _por qué_ detrás de cada decisión de diseño del framework. No es un tutorial de "hola mundo" ni una traducción de la documentación oficial: es una guía de referencia progresiva que construye conocimiento de forma acumulativa, partiendo de los fundamentos y llegando a patrones avanzados de arquitectura, rendimiento y despliegue en producción.

**Todo el código es Angular 17+** con TypeScript estricto, componentes standalone y la nueva sintaxis de control de flujo (`@if`, `@for`, `@defer`).

## Requisitos previos

- Conocimientos básicos de **HTML y CSS**
- Familiaridad con **JavaScript moderno** (ES2020+, async/await, módulos)
- Conocimiento básico de **TypeScript** (tipos, interfaces, clases, generics)
- No se requiere experiencia previa con Angular ni con otros frameworks

## Versiones cubiertas

| Versión    | Fecha    | Lo que se cubre en esta guía                                               |
| ---------- | -------- | -------------------------------------------------------------------------- |
| Angular 15 | Nov 2022 | Guards y resolvers funcionales, interceptores funcionales                  |
| Angular 16 | May 2023 | Signals (developer preview), `takeUntilDestroyed`                          |
| Angular 17 | Nov 2023 | Standalone default, `@if/@for/@defer`, Signals estables                    |
| Angular 18 | May 2024 | `linkedSignal`, `resource` (experimental)                                  |
| Angular 19 | Nov 2024 | `httpResource`, hydratación incremental (experimental)                     |
| Angular 20 | May 2025 | `@let`, signal queries, Zoneless dev preview, SSR por ruta                 |
| Angular 21 | Nov 2025 | Zoneless estable, Signal Forms dev preview, `@angular/build`               |
| Angular 22 | Jun 2026 | `OnPush` por defecto, Signal Forms estables, `@Service()`, `injectAsync()` |

## Cómo navegar la guía

La guía está organizada en **16 partes temáticas** con **37 capítulos** y **148 archivos**. Cada archivo cubre una parte de un capítulo (entre 3 y 7 páginas de contenido denso).

**Si eres principiante:** empieza por [Historia, versiones y el renacimiento de Angular](01-historia-y-primeros-pasos/1-historia-versiones-y-el-renacimiento-de-angular.md) y avanza en orden - cada capítulo asume el conocimiento de los anteriores.

**Si tienes experiencia con Angular:** usa el menú lateral para ir directamente a la parte que necesitas. Los capítulos avanzados (XI en adelante) son relativamente autónomos.

**Como referencia:** la tabla de contenidos completa, con descripción archivo por archivo, está en el [`README.md`](https://github.com/jhonsferg/spanish-angular-guide#tabla-de-contenidos-completa) del repositorio.

## Resumen de la guía

| Métrica               | Valor                                     |
| --------------------- | ----------------------------------------- |
| Partes                | 16                                        |
| Capítulos             | 37                                        |
| Archivos de contenido | 148                                       |
| Versiones cubiertas   | Angular 15 → 22                           |
| Idioma                | Español neutro latinoamericano            |
| Estilo de código      | TypeScript strict, Angular 17+ standalone |
| Diagramas             | Mermaid (sin ASCII art)                   |

---

_Esta guía es un documento vivo. Las secciones de Angular 20, 21 y 22 reflejan las APIs estables y developer preview documentadas en la documentación oficial (angular.dev) y el changelog del repositorio [angular/angular](https://github.com/angular/angular) en GitHub._
