# Angular: La Guía en Español

> La guía de Angular en español. Cubre Angular 17–22 desde los fundamentos hasta arquitecturas de nivel enterprise, con Signals, NgRx, SSR, micro-frontends y todo lo nuevo en Angular 20, 21 y 22.
>
> 🌐 Navegable como sitio en **[jhonsferg.github.io/spanish-angular-guide](https://jhonsferg.github.io/spanish-angular-guide/)** o como Markdown plano directamente en `docs/`.

---

## ¿Qué es esta guía?

Esta guía está escrita para desarrolladores hispanohablantes que quieren dominar Angular de verdad - no solo aprender la sintaxis, sino entender el _por qué_ detrás de cada decisión de diseño del framework. Cada concepto se explica como lo haría un senior a un colega: directo, honesto y con ejemplos que resuelven problemas reales.

No es un tutorial de "hola mundo" ni una traducción de la documentación oficial. Es una guía de referencia progresiva que construye conocimiento de forma acumulativa, partiendo de los fundamentos y llegando a patrones avanzados de arquitectura, rendimiento y despliegue en producción.

**Todo el código es Angular 17+** con TypeScript estricto, componentes standalone y la nueva sintaxis de control de flujo (`@if`, `@for`, `@defer`). Los capítulos finales cubren las novedades de **Angular 20, 21 y 22**.

---

## Requisitos previos

- Conocimientos básicos de **HTML y CSS**
- Familiaridad con **JavaScript moderno** (ES2020+, async/await, módulos)
- Conocimiento básico de **TypeScript** (tipos, interfaces, clases, generics)
- No se requiere experiencia previa con Angular ni con otros frameworks

---

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

---

## Sitio web y desarrollo local

El contenido vive en `docs/` como Markdown plano (legible directamente en GitHub) y se publica además como sitio navegable con [MkDocs Material](https://squidfunk.github.io/mkdocs-material/) vía GitHub Actions en cada push a `main`.

Para levantar el sitio localmente (requiere [uv](https://docs.astral.sh/uv/)):

```bash
uv sync
uv run mkdocs serve
# Sitio disponible en http://127.0.0.1:8000
```

La navegación y agrupación por partes/capítulos está definida en [`mkdocs.yml`](mkdocs.yml).

---

## Cómo navegar la guía

La guía está organizada en **16 partes temáticas** con **37 capítulos** y **148 archivos**, agrupados en carpetas por tema dentro de `docs/`. Cada archivo cubre una parte de un capítulo (entre 3 y 7 páginas de contenido denso).

**Si eres principiante:** lee en orden desde la Parte I. Cada capítulo asume el conocimiento de los anteriores.

**Si tienes experiencia con Angular:** puedes ir directamente a la parte que necesitas. Los capítulos avanzados (XI en adelante) son relativamente autónomos.

**Como referencia:** usa la tabla de contenidos abajo para ir directamente al tema específico.

---

## Tabla de contenidos completa

### PARTE I - Primeros Pasos con Angular

_Capítulos 1–2 · 8 archivos_

Cubre la historia del framework, el ecosistema de herramientas, la estructura de un proyecto y el proceso de arranque. Ideal para quien nunca ha tocado Angular.

| Archivo                                                                                                                                                                                          | Título                                                 | Descripción breve                                                                      |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------ | -------------------------------------------------------------------------------------- |
| [docs/01-historia-y-primeros-pasos/1-historia-versiones-y-el-renacimiento-de-angular.md](docs/01-historia-y-primeros-pasos/1-historia-versiones-y-el-renacimiento-de-angular.md)                 | Historia, versiones y el renacimiento de Angular       | De AngularJS a Angular 2+, el ciclo de releases semver, la era Ivy y Standalone        |
| [docs/01-historia-y-primeros-pasos/2-angular-vs-react-vs-vue-cuando-elegir-cada-uno.md](docs/01-historia-y-primeros-pasos/2-angular-vs-react-vs-vue-cuando-elegir-cada-uno.md)                   | Angular vs React vs Vue: cuándo elegir cada uno        | Comparativa sin favoritismos; casos donde Angular brilla (enterprise, tipado estricto) |
| [docs/01-historia-y-primeros-pasos/3-instalacion-de-node-angular-cli-y-vs-code.md](docs/01-historia-y-primeros-pasos/3-instalacion-de-node-angular-cli-y-vs-code.md)                             | Instalación de Node, Angular CLI y VS Code             | Setup completo del entorno con extensiones recomendadas y diagrama del toolchain       |
| [docs/01-historia-y-primeros-pasos/4-tu-primera-aplicacion-ng-new-al-primer-ng-serve.md](docs/01-historia-y-primeros-pasos/4-tu-primera-aplicacion-ng-new-al-primer-ng-serve.md)                 | Tu primera aplicación: ng new al primer ng serve       | Crear un proyecto, explorar la estructura y hacer el primer cambio con live reload     |
| [docs/02-cli-y-estructura-de-proyecto/1-vision-general-modulos-componentes-servicios.md](docs/02-cli-y-estructura-de-proyecto/1-vision-general-modulos-componentes-servicios.md)                 | Visión general: módulos, componentes, servicios        | Diagrama de cómo se relacionan los bloques principales de Angular                      |
| [docs/02-cli-y-estructura-de-proyecto/2-angular-cli-a-fondo-comandos-esenciales-y-schematics.md](docs/02-cli-y-estructura-de-proyecto/2-angular-cli-a-fondo-comandos-esenciales-y-schematics.md) | Angular CLI a fondo: comandos esenciales y schematics  | `ng generate`, `ng build`, `ng test`, `ng lint`, flags útiles como `--dry-run`         |
| [docs/02-cli-y-estructura-de-proyecto/3-estructura-de-carpetas-y-convenciones-de-proyecto.md](docs/02-cli-y-estructura-de-proyecto/3-estructura-de-carpetas-y-convenciones-de-proyecto.md)       | Estructura de carpetas y convenciones de proyecto      | Feature-based structure, barrel exports, convenciones de nombres kebab-case/PascalCase |
| [docs/02-cli-y-estructura-de-proyecto/4-el-proceso-de-arranque-main-ts-appmodule-y-bootstrap.md](docs/02-cli-y-estructura-de-proyecto/4-el-proceso-de-arranque-main-ts-appmodule-y-bootstrap.md) | El proceso de arranque: main.ts, AppModule y bootstrap | `bootstrapApplication()`, `APP_INITIALIZER`, `provideRouter`, `provideHttpClient`      |

---

### PARTE II - Componentes: El Alma de Angular

_Capítulos 3–4 · 8 archivos_

Todo lo que necesitas saber sobre componentes: desde la anatomía básica hasta técnicas avanzadas de proyección de contenido y carga diferida de UI.

| Archivo                                                                                                                                                                                                      | Título                                                    | Descripción breve                                                                          |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| [docs/03-fundamentos-de-componentes/1-anatomia-de-un-componente-clase-decorador-y-template.md](docs/03-fundamentos-de-componentes/1-anatomia-de-un-componente-clase-decorador-y-template.md)                 | Anatomía de un componente: clase, decorador y template    | Las tres partes de un componente, el decorador `@Component` y sus propiedades              |
| [docs/03-fundamentos-de-componentes/2-ciclo-de-vida-oninit-onchanges-ondestroy-y-los-demas.md](docs/03-fundamentos-de-componentes/2-ciclo-de-vida-oninit-onchanges-ondestroy-y-los-demas.md)                 | Ciclo de vida: OnInit, OnChanges, OnDestroy y los demás   | Los 8 hooks en orden de ejecución con casos de uso y diagrama Mermaid                      |
| [docs/03-fundamentos-de-componentes/3-comunicacion-con-input-y-output.md](docs/03-fundamentos-de-componentes/3-comunicacion-con-input-y-output.md)                                                           | Comunicación con @Input y @Output                         | `@Input()` con alias y transformaciones, `@Output()` con `EventEmitter`, patrón padre-hijo |
| [docs/03-fundamentos-de-componentes/4-estilos-en-componentes-encapsulacion-y-viewencapsulation.md](docs/03-fundamentos-de-componentes/4-estilos-en-componentes-encapsulacion-y-viewencapsulation.md)         | Estilos en componentes: encapsulación y ViewEncapsulation | `Emulated`, `None`, `ShadowDom`, `:host`, variables CSS, theming                           |
| [docs/04-composicion-y-carga-de-componentes/1-viewchild-viewchildren-y-elementref.md](docs/04-composicion-y-carga-de-componentes/1-viewchild-viewchildren-y-elementref.md)                                   | ViewChild, ViewChildren y ElementRef                      | `@ViewChild` con tipos de referencia, `QueryList`, `static: true` vs `false`               |
| [docs/04-composicion-y-carga-de-componentes/2-ng-content-proyeccion-de-contenido-simple-y-multiple.md](docs/04-composicion-y-carga-de-componentes/2-ng-content-proyeccion-de-contenido-simple-y-multiple.md) | ng-content: proyección de contenido simple y múltiple     | `<ng-content>`, proyección con `select`, `ContentChild`, componente card reutilizable      |
| [docs/04-composicion-y-carga-de-componentes/3-componentes-standalone-el-futuro-de-angular.md](docs/04-composicion-y-carga-de-componentes/3-componentes-standalone-el-futuro-de-angular.md)                   | Componentes Standalone: el futuro de Angular              | `standalone: true`, `imports` en el decorador, bootstrap sin NgModule                      |
| [docs/04-composicion-y-carga-de-componentes/4-deferrable-views-con-defer-carga-diferida-de-ui.md](docs/04-composicion-y-carga-de-componentes/4-deferrable-views-con-defer-carga-diferida-de-ui.md)           | Deferrable Views con @defer: carga diferida de UI         | `@defer`, `@loading`, `@error`, triggers de viewport/interacción/timer, impacto en LCP     |

---

### PARTE III - Templates y Directivas

_Capítulos 5–6 · 8 archivos_

Data binding en todas sus formas, la nueva sintaxis de control de flujo y cómo crear directivas personalizadas de atributo y estructurales.

| Archivo                                                                                                                                                                                        | Título                                                       | Descripción breve                                                                               |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------ | ----------------------------------------------------------------------------------------------- |
| [docs/05-data-binding-y-control-de-flujo/1-interpolacion-y-property-binding.md](docs/05-data-binding-y-control-de-flujo/1-interpolacion-y-property-binding.md)                                 | Interpolación y Property Binding                             | `{{ }}`, `[prop]`, attribute vs property binding, `[class.x]`, `[style.y]`                      |
| [docs/05-data-binding-y-control-de-flujo/2-event-binding-y-two-way-binding.md](docs/05-data-binding-y-control-de-flujo/2-event-binding-y-two-way-binding.md)                                   | Event Binding y Two-way Binding                              | `(evento)`, `$event`, `[(ngModel)]`, two-way con Signal inputs                                  |
| [docs/05-data-binding-y-control-de-flujo/3-template-reference-variables-y-viewchild.md](docs/05-data-binding-y-control-de-flujo/3-template-reference-variables-y-viewchild.md)                 | Template Reference Variables y @ViewChild                    | `#refVar` en templates, pasar refs a métodos, diferencias entre enfoques                        |
| [docs/05-data-binding-y-control-de-flujo/4-nueva-sintaxis-de-control-de-flujo-if-for-switch.md](docs/05-data-binding-y-control-de-flujo/4-nueva-sintaxis-de-control-de-flujo-if-for-switch.md) | Nueva sintaxis de control de flujo: @if, @for, @switch       | `@if/@else if/@else`, `@for` con `track` obligatorio, `@switch`, diferencias con `*ngIf` legacy |
| [docs/06-directivas/1-directivas-estructurales-built-in-ngif-ngfor-ngswitch.md](docs/06-directivas/1-directivas-estructurales-built-in-ngif-ngfor-ngswitch.md)                                 | Directivas estructurales built-in: ngIf, ngFor, ngSwitch     | `*ngIf`, `ngIfThen`, `*ngFor` con `index/first/last`, cuándo migrar a nueva sintaxis            |
| [docs/06-directivas/2-directivas-de-atributo-built-in-ngclass-ngstyle.md](docs/06-directivas/2-directivas-de-atributo-built-in-ngclass-ngstyle.md)                                             | Directivas de atributo built-in: ngClass, ngStyle            | `[ngClass]` con objeto/array/string, `[ngStyle]`, diferencias con bindings directos             |
| [docs/06-directivas/3-creando-directivas-de-atributo-personalizadas.md](docs/06-directivas/3-creando-directivas-de-atributo-personalizadas.md)                                                 | Creando directivas de atributo personalizadas                | `@Directive`, `Renderer2`, directiva `appResaltado` con `@HostListener`                         |
| [docs/06-directivas/4-hostlistener-hostbinding-y-directivas-estructurales-propias.md](docs/06-directivas/4-hostlistener-hostbinding-y-directivas-estructurales-propias.md)                     | HostListener, HostBinding y directivas estructurales propias | `@HostListener`, `@HostBinding`, directiva estructural con `TemplateRef` y `ViewContainerRef`   |

---

### PARTE IV - Pipes: Transformando Datos

_Capítulo 7 · 4 archivos_

Los pipes built-in de Angular, cómo encadenarlos y parametrizarlos, y cómo crear pipes personalizados con control total del rendimiento.

| Archivo                                                                                                                                | Título                                              | Descripción breve                                                                            |
| -------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| [docs/07-pipes/1-pipes-built-in-date-currency-number-json-async.md](docs/07-pipes/1-pipes-built-in-date-currency-number-json-async.md) | Pipes built-in: date, currency, number, json, async | `DatePipe`, `CurrencyPipe`, `DecimalPipe`, `AsyncPipe` con Observable y Promise, `LOCALE_ID` |
| [docs/07-pipes/2-parametros-de-pipes-y-encadenamiento.md](docs/07-pipes/2-parametros-de-pipes-y-encadenamiento.md)                     | Parámetros de pipes y encadenamiento                | Sintaxis `\| pipe:param1:param2`, encadenamiento múltiple, orden de evaluación               |
| [docs/07-pipes/3-creando-pipes-personalizados-con-pipetransform.md](docs/07-pipes/3-creando-pipes-personalizados-con-pipetransform.md) | Creando pipes personalizados con PipeTransform      | `@Pipe({ name, standalone, pure })`, ejemplo `filtrarPor` y `truncarTexto`                   |
| [docs/07-pipes/4-pipes-puros-vs-impuros-impacto-en-rendimiento.md](docs/07-pipes/4-pipes-puros-vs-impuros-impacto-en-rendimiento.md)   | Pipes puros vs impuros: impacto en rendimiento      | Qué es un pipe puro, cuándo necesitas `pure: false` y el costo, alternativas                 |

---

### PARTE V - Servicios e Inyección de Dependencias

_Capítulos 8–9 · 8 archivos_

La arquitectura de capas de Angular, el sistema de DI, la jerarquía de inyectores y la migración completa del mundo NgModules al mundo Standalone.

| Archivo                                                                                                                                                                                                                                | Título                                                           | Descripción breve                                                                            |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| [docs/08-servicios-e-inyeccion-de-dependencias/1-que-es-un-servicio-responsabilidad-unica-y-separacion-de-capas.md](docs/08-servicios-e-inyeccion-de-dependencias/1-que-es-un-servicio-responsabilidad-unica-y-separacion-de-capas.md) | ¿Qué es un servicio? Responsabilidad única y separación de capas | Problema que resuelven, diagrama de capas (presentación / lógica / datos)                    |
| [docs/08-servicios-e-inyeccion-de-dependencias/2-creando-e-inyectando-servicios.md](docs/08-servicios-e-inyeccion-de-dependencias/2-creando-e-inyectando-servicios.md)                                                                 | Creando e inyectando servicios                                   | `@Injectable({ providedIn: 'root' })`, inyección por constructor vs `inject()`               |
| [docs/08-servicios-e-inyeccion-de-dependencias/3-inyeccion-de-dependencias-el-sistema-di-de-angular.md](docs/08-servicios-e-inyeccion-de-dependencias/3-inyeccion-de-dependencias-el-sistema-di-de-angular.md)                         | Inyección de Dependencias: el sistema DI de Angular              | Tokens de inyección, `InjectionToken<T>`, `@Inject()`, `inject()` en funciones puras         |
| [docs/08-servicios-e-inyeccion-de-dependencias/4-jerarquia-de-inyectores-root-modulo-y-componente.md](docs/08-servicios-e-inyeccion-de-dependencias/4-jerarquia-de-inyectores-root-modulo-y-componente.md)                             | Jerarquía de inyectores: root, módulo y componente               | Árbol de inyectores, resolución de dependencias, instancias separadas por componente         |
| [docs/09-ngmodules-y-standalone/1-ngmodules-declarations-imports-exports-providers.md](docs/09-ngmodules-y-standalone/1-ngmodules-declarations-imports-exports-providers.md)                                                           | NgModules: declarations, imports, exports, providers             | Anatomía de `@NgModule`, qué va en cada array, errores comunes                               |
| [docs/09-ngmodules-y-standalone/2-modulo-core-shared-y-de-funcionalidad.md](docs/09-ngmodules-y-standalone/2-modulo-core-shared-y-de-funcionalidad.md)                                                                                 | Módulo Core, Shared y de funcionalidad                           | Patrón de tres tipos de módulos, `forRoot()` para evitar importar CoreModule dos veces       |
| [docs/09-ngmodules-y-standalone/3-el-mundo-standalone-componentes-directivas-y-pipes-sin-modulo.md](docs/09-ngmodules-y-standalone/3-el-mundo-standalone-componentes-directivas-y-pipes-sin-modulo.md)                                 | El mundo Standalone: componentes, directivas y pipes sin módulo  | `standalone: true`, imports en el decorador, ventajas en tree-shaking, `importProvidersFrom` |
| [docs/09-ngmodules-y-standalone/4-guia-de-migracion-de-ngmodules-a-standalone.md](docs/09-ngmodules-y-standalone/4-guia-de-migracion-de-ngmodules-a-standalone.md)                                                                     | Guía de migración: de NgModules a Standalone                     | Comando automático `ng generate @angular/core:standalone`, fases, compatibilidad híbrida     |

---

### PARTE VI - Navegación y Routing

_Capítulos 10–11 · 8 archivos_

Configuración del router, navegación programática, rutas dinámicas, lazy loading, guards funcionales y estrategias de preloading.

| Archivo                                                                                                                                                                                  | Título                                                        | Descripción breve                                                                            |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| [docs/10-routing-fundamentos/1-configuracion-del-router-providerouter-y-rutas-basicas.md](docs/10-routing-fundamentos/1-configuracion-del-router-providerouter-y-rutas-basicas.md)       | Configuración del Router: provideRouter y rutas básicas       | `provideRouter(routes)`, objeto de ruta, `redirectTo`, `pathMatch`, ruta wildcard `**`       |
| [docs/10-routing-fundamentos/2-routerlink-routeroutlet-y-navegacion-programatica.md](docs/10-routing-fundamentos/2-routerlink-routeroutlet-y-navegacion-programatica.md)                 | RouterLink, RouterOutlet y navegación programática            | `<router-outlet>`, `[routerLink]`, `routerLinkActive`, `Router.navigate()`                   |
| [docs/10-routing-fundamentos/3-rutas-con-parametros-id-y-query-params.md](docs/10-routing-fundamentos/3-rutas-con-parametros-id-y-query-params.md)                                       | Rutas con parámetros :id y Query Params                       | `paramMap` como Observable, `queryParams`, `fragment`, lectura con `inject(ActivatedRoute)`  |
| [docs/10-routing-fundamentos/4-rutas-hijas-child-routes-y-outlets-secundarios.md](docs/10-routing-fundamentos/4-rutas-hijas-child-routes-y-outlets-secundarios.md)                       | Rutas hijas (Child Routes) y outlets secundarios              | `children` en rutas, `<router-outlet>` anidado, outlets con nombre                           |
| [docs/11-routing-avanzado/1-lazy-loading-cargando-modulos-y-componentes-bajo-demanda.md](docs/11-routing-avanzado/1-lazy-loading-cargando-modulos-y-componentes-bajo-demanda.md)         | Lazy Loading: cargando módulos y componentes bajo demanda     | `loadComponent`, `loadChildren`, impacto en bundle size, verificar chunks en DevTools        |
| [docs/11-routing-avanzado/2-guards-funcionales-canactivate-candeactivate-canmatch.md](docs/11-routing-avanzado/2-guards-funcionales-canactivate-candeactivate-canmatch.md)               | Guards funcionales: canActivate, canDeactivate, canMatch      | Guards como funciones (Angular 14+), `inject()` dentro del guard, redirigir desde guard      |
| [docs/11-routing-avanzado/3-resolvers-precargando-datos-antes-de-navegar.md](docs/11-routing-avanzado/3-resolvers-precargando-datos-antes-de-navegar.md)                                 | Resolvers: precargando datos antes de navegar                 | `ResolveFn<T>`, acceder a datos resueltos, cuándo NO usar resolvers, alternativa con Signals |
| [docs/11-routing-avanzado/4-estrategias-de-preloading-preloadallmodules-y-personalizadas.md](docs/11-routing-avanzado/4-estrategias-de-preloading-preloadallmodules-y-personalizadas.md) | Estrategias de preloading: PreloadAllModules y personalizadas | `PreloadAllModules`, estrategia personalizada, preloading selectivo, `QuicklinkStrategy`     |

---

### PARTE VII - Formularios

_Capítulos 12–13 · 8 archivos_

Los dos enfoques de formularios en Angular: template-driven para casos simples y reactive forms para validación compleja, dinámismo y control total.

| Archivo                                                                                                                                                                                          | Título                                                | Descripción breve                                                                         |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| [docs/12-formularios-template-driven/1-fundamentos-ngmodel-ngform-y-formsmodule.md](docs/12-formularios-template-driven/1-fundamentos-ngmodel-ngform-y-formsmodule.md)                           | Fundamentos: ngModel, ngForm y FormsModule            | `[(ngModel)]`, `ngForm`, `form.valid`, `form.value`, submit con `(ngSubmit)`              |
| [docs/12-formularios-template-driven/2-validacion-con-atributos-html-y-directivas-de-angular.md](docs/12-formularios-template-driven/2-validacion-con-atributos-html-y-directivas-de-angular.md) | Validación con atributos HTML y directivas de Angular | `required`, `minlength`, `pattern`, clases CSS `ng-valid/ng-invalid/ng-touched`           |
| [docs/12-formularios-template-driven/3-mensajes-de-error-y-clases-css-de-estado.md](docs/12-formularios-template-driven/3-mensajes-de-error-y-clases-css-de-estado.md)                           | Mensajes de error y clases CSS de estado              | Estrategias para mostrar errores, componente de campo reutilizable, reset de formulario   |
| [docs/12-formularios-template-driven/4-formularios-anidados-con-ngmodelgroup.md](docs/12-formularios-template-driven/4-formularios-anidados-con-ngmodelgroup.md)                                 | Formularios anidados con ngModelGroup                 | `ngModelGroup` para agrupar campos, acceder a subgrupos, validación de grupo              |
| [docs/13-formularios-reactivos/1-formcontrol-formgroup-y-formbuilder.md](docs/13-formularios-reactivos/1-formcontrol-formgroup-y-formbuilder.md)                                                 | FormControl, FormGroup y FormBuilder                  | `new FormControl<T>()`, `FormBuilder.group()`, `FormBuilder.nonNullable`, tipado genérico |
| [docs/13-formularios-reactivos/2-validators-sincronos-y-asincronos-built-in.md](docs/13-formularios-reactivos/2-validators-sincronos-y-asincronos-built-in.md)                                   | Validators síncronos y asíncronos built-in            | `Validators.required/email/min/max/pattern`, `AsyncValidatorFn` con `debounceTime`        |
| [docs/13-formularios-reactivos/3-formarray-listas-dinamicas-de-controles.md](docs/13-formularios-reactivos/3-formarray-listas-dinamicas-de-controles.md)                                         | FormArray: listas dinámicas de controles              | `FormArray`, `push()`, `removeAt()`, tipado genérico, validación del array completo       |
| [docs/13-formularios-reactivos/4-validadores-personalizados-y-cross-field-validation.md](docs/13-formularios-reactivos/4-validadores-personalizados-y-cross-field-validation.md)                 | Validadores personalizados y cross-field validation   | `ValidatorFn`, validación de contraseñas iguales, `AsyncValidatorFn` que consulta una API |

---

### PARTE VIII - Comunicación HTTP

_Capítulos 14–15 · 8 archivos_

`HttpClient` con tipado genérico, manejo de errores, interceptores funcionales para autenticación, loading global y caché con RxJS.

| Archivo                                                                                                                                                                                          | Título                                                         | Descripción breve                                                                              |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| [docs/14-httpclient/1-configuracion-con-providehttpclient-y-primera-peticion-get.md](docs/14-httpclient/1-configuracion-con-providehttpclient-y-primera-peticion-get.md)                         | Configuración con provideHttpClient y primera petición GET     | `provideHttpClient()`, inyectar `HttpClient`, primer `get<T>()`, async pipe                    |
| [docs/14-httpclient/2-post-put-patch-delete-con-tipado-generico.md](docs/14-httpclient/2-post-put-patch-delete-con-tipado-generico.md)                                                           | POST, PUT, PATCH, DELETE con tipado genérico                   | Métodos HTTP con body tipado, interfaces de respuesta, opciones por request                    |
| [docs/14-httpclient/3-manejo-de-errores-con-catcherror-y-tipado-de-respuestas.md](docs/14-httpclient/3-manejo-de-errores-con-catcherror-y-tipado-de-respuestas.md)                               | Manejo de errores con catchError y tipado de respuestas        | `HttpErrorResponse`, `catchError`, errores de cliente vs servidor, estrategias de notificación |
| [docs/14-httpclient/4-headers-params-httpcontext-y-opciones-avanzadas.md](docs/14-httpclient/4-headers-params-httpcontext-y-opciones-avanzadas.md)                                               | Headers, params, HttpContext y opciones avanzadas              | `HttpHeaders`, `HttpParams`, `observe: 'response'`, `reportProgress`, `HttpContext`            |
| [docs/15-interceptores-http/1-interceptores-funcionales-angular-15-concepto-y-estructura.md](docs/15-interceptores-http/1-interceptores-funcionales-angular-15-concepto-y-estructura.md)         | Interceptores funcionales (Angular 15+): concepto y estructura | `HttpInterceptorFn`, `request.clone()`, `withInterceptors([])`, orden de ejecución             |
| [docs/15-interceptores-http/2-interceptor-de-autenticacion-adjuntando-jwt-automaticamente.md](docs/15-interceptores-http/2-interceptor-de-autenticacion-adjuntando-jwt-automaticamente.md)       | Interceptor de autenticación: adjuntando JWT automáticamente   | Leer token desde servicio, `Authorization: Bearer`, excluir URLs públicas, manejar 401         |
| [docs/15-interceptores-http/3-interceptor-de-loading-global-y-manejo-centralizado-de-errores.md](docs/15-interceptores-http/3-interceptor-de-loading-global-y-manejo-centralizado-de-errores.md) | Interceptor de loading global y manejo centralizado de errores | Contador con Signal, spinner global, interceptor de errores con toast, `finalize()`            |
| [docs/15-interceptores-http/4-estrategias-de-cache-http-y-retry-con-rxjs.md](docs/15-interceptores-http/4-estrategias-de-cache-http-y-retry-con-rxjs.md)                                         | Estrategias de caché HTTP y retry con RxJS                     | `shareReplay(1)`, caché con `Map`, `retry(3)`, backoff exponencial con `retryWhen`             |

---

### PARTE IX - Programación Reactiva con RxJS

_Capítulos 16–18 · 12 archivos_

RxJS de cero a avanzado: Observables, Subjects, operadores de transformación/filtrado/combinación, patrones reactivos en servicios y marble testing.

| Archivo                                                                                                                                                                                | Título                                                            | Descripción breve                                                                    |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| [docs/16-rxjs-fundamentos/1-que-es-la-programacion-reactiva-observables-vs-promesas.md](docs/16-rxjs-fundamentos/1-que-es-la-programacion-reactiva-observables-vs-promesas.md)         | ¿Qué es la programación reactiva? Observables vs Promesas         | Push vs pull, lazy vs eager, unicast vs multicast, diagrama comparativo              |
| [docs/16-rxjs-fundamentos/2-observable-observer-subscription-y-el-contrato-reactivo.md](docs/16-rxjs-fundamentos/2-observable-observer-subscription-y-el-contrato-reactivo.md)         | Observable, Observer, Subscription y el contrato reactivo         | Anatomía del Observable, `next/error/complete`, cold vs hot, `unsubscribe()`         |
| [docs/16-rxjs-fundamentos/3-subject-behaviorsubject-replaysubject-y-asyncsubject.md](docs/16-rxjs-fundamentos/3-subject-behaviorsubject-replaysubject-y-asyncsubject.md)               | Subject, BehaviorSubject, ReplaySubject y AsyncSubject            | Cuándo usar cada tipo de Subject, comparativa con diagrama Mermaid                   |
| [docs/16-rxjs-fundamentos/4-creadores-of-from-interval-timer-fromevent.md](docs/16-rxjs-fundamentos/4-creadores-of-from-interval-timer-fromevent.md)                                   | Creadores: of, from, interval, timer, fromEvent                   | `of`, `from`, `interval`, `timer`, `fromEvent`, `EMPTY`, `NEVER`, `throwError`       |
| [docs/17-rxjs-operadores/1-transformacion-map-switchmap-mergemap-concatmap-exhaustmap.md](docs/17-rxjs-operadores/1-transformacion-map-switchmap-mergemap-concatmap-exhaustmap.md)     | Transformación: map, switchMap, mergeMap, concatMap, exhaustMap   | Diferencias críticas entre los cuatro operadores de aplanamiento con ejemplos reales |
| [docs/17-rxjs-operadores/2-filtrado-filter-take-first-debouncetime-distinctuntilchanged.md](docs/17-rxjs-operadores/2-filtrado-filter-take-first-debouncetime-distinctuntilchanged.md) | Filtrado: filter, take, first, debounceTime, distinctUntilChanged | Buscador con `debounceTime(300)` + `distinctUntilChanged` + `switchMap`              |
| [docs/17-rxjs-operadores/3-combinacion-combinelatest-forkjoin-zip-withlatestfrom.md](docs/17-rxjs-operadores/3-combinacion-combinelatest-forkjoin-zip-withlatestfrom.md)               | Combinación: combineLatest, forkJoin, zip, withLatestFrom         | Peticiones paralelas, combinar filtros reactivos, sincronización de streams          |
| [docs/17-rxjs-operadores/4-manejo-de-errores-catcherror-retry-retrywhen-throwerror.md](docs/17-rxjs-operadores/4-manejo-de-errores-catcherror-retry-retrywhen-throwerror.md)           | Manejo de errores: catchError, retry, retryWhen, throwError       | `catchError` con alternativa o re-lanzamiento, backoff exponencial, `finalize`       |
| [docs/18-rxjs-patrones-y-testing/1-patrones-reactivos-en-servicios-angular.md](docs/18-rxjs-patrones-y-testing/1-patrones-reactivos-en-servicios-angular.md)                           | Patrones reactivos en servicios Angular                           | State service con `BehaviorSubject`, `asObservable()`, `shareReplay(1)`              |
| [docs/18-rxjs-patrones-y-testing/2-evitando-memory-leaks-takeuntildestroyed-async-pipe.md](docs/18-rxjs-patrones-y-testing/2-evitando-memory-leaks-takeuntildestroyed-async-pipe.md)   | Evitando memory leaks: takeUntilDestroyed, async pipe             | `takeUntilDestroyed()`, `DestroyRef`, cuándo el async pipe es preferible             |
| [docs/18-rxjs-patrones-y-testing/3-operadores-de-acumulacion-scan-reduce-buffer-window.md](docs/18-rxjs-patrones-y-testing/3-operadores-de-acumulacion-scan-reduce-buffer-window.md)   | Operadores de acumulación: scan, reduce, buffer, window           | `scan` para carrito reactivo, `reduce`, `bufferTime`, `bufferCount`                  |
| [docs/18-rxjs-patrones-y-testing/4-testing-de-observables-con-marble-testing.md](docs/18-rxjs-patrones-y-testing/4-testing-de-observables-con-marble-testing.md)                       | Testing de Observables con marble testing                         | `TestScheduler`, sintaxis de marble strings, `hot()`/`cold()`, tiempo virtual        |

---

### PARTE X - Angular Signals: Reactividad Moderna

_Capítulos 19–20 · 8 archivos_

La trinidad reactiva de Signals, inputs y outputs modernos, interoperabilidad con RxJS, gestión de estado local, `resource()`, `httpResource()` y el camino a Zoneless.

| Archivo                                                                                                                                                                        | Título                                                   | Descripción breve                                                                          |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| [docs/19-signals-fundamentos/1-que-son-los-signals-y-como-cambian-angular.md](docs/19-signals-fundamentos/1-que-son-los-signals-y-como-cambian-angular.md)                     | ¿Qué son los Signals y cómo cambian Angular?             | El problema con Zone.js, la trinidad signal→computed→effect, diagrama del grafo reactivo   |
| [docs/19-signals-fundamentos/2-signal-computed-y-effect-la-trinidad-reactiva.md](docs/19-signals-fundamentos/2-signal-computed-y-effect-la-trinidad-reactiva.md)               | signal(), computed() y effect(): la trinidad reactiva    | `.set()`, `.update()`, `.mutate()`, `computed()` lazy, `effect()` con limpieza             |
| [docs/19-signals-fundamentos/3-signal-inputs-model-signals-y-output.md](docs/19-signals-fundamentos/3-signal-inputs-model-signals-y-output.md)                                 | Signal Inputs, Model Signals y output()                  | `input<T>()`, `input.required()`, `model<T>()` para two-way moderno, `output<T>()`         |
| [docs/19-signals-fundamentos/4-tosignal-y-toobservable-puente-entre-signals-y-rxjs.md](docs/19-signals-fundamentos/4-tosignal-y-toobservable-puente-entre-signals-y-rxjs.md)   | toSignal() y toObservable(): puente entre Signals y RxJS | `toSignal(obs$, { initialValue })`, `requireSync`, `toObservable(signal)`, errores comunes |
| [docs/20-signals-avanzado/1-gestion-de-estado-local-con-signals-en-componentes.md](docs/20-signals-avanzado/1-gestion-de-estado-local-con-signals-en-componentes.md)           | Gestión de estado local con Signals en componentes       | Reemplazar `BehaviorSubject` con `signal`, local store con `computed` y `effect`           |
| [docs/20-signals-avanzado/2-signals-en-formularios-reactivos-e-http.md](docs/20-signals-avanzado/2-signals-en-formularios-reactivos-e-http.md)                                 | Signals en formularios reactivos e HTTP                  | `linkedSignal`, `resource()`, `httpResource()`, estados `isLoading/error/value`            |
| [docs/20-signals-avanzado/3-signals-y-change-detection-el-camino-a-zoneless-angular.md](docs/20-signals-avanzado/3-signals-y-change-detection-el-camino-a-zoneless-angular.md) | Signals y Change Detection: el camino a Zoneless Angular | Cómo Signals elimina Zone.js, `provideExperimentalZonelessChangeDetection()`, checklist    |
| [docs/20-signals-avanzado/4-signals-vs-rxjs-cuando-usar-cada-paradigma.md](docs/20-signals-avanzado/4-signals-vs-rxjs-cuando-usar-cada-paradigma.md)                           | Signals vs RxJS: cuándo usar cada paradigma              | Tabla de decisión, reglas prácticas, antipatrones, arquitectura de coexistencia            |

---

### PARTE XI - Gestión de Estado con NgRx

_Capítulos 21–24 · 16 archivos_

NgRx completo: el patrón Redux, acciones, reducers, selectors memoizados, effects con RxJS, Entity, Router Store, DevTools y el moderno Signal Store.

| Archivo                                                                                                                                                                                                      | Título                                                            | Descripción breve                                                                  |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| [docs/21-ngrx-fundamentos/1-el-problema-del-estado-y-el-patron-redux.md](docs/21-ngrx-fundamentos/1-el-problema-del-estado-y-el-patron-redux.md)                                                             | El problema del estado y el patrón Redux                          | Prop drilling, servicios compartidos limitados, flujo unidireccional Redux         |
| [docs/21-ngrx-fundamentos/2-instalacion-configuracion-y-arquitectura-ngrx.md](docs/21-ngrx-fundamentos/2-instalacion-configuracion-y-arquitectura-ngrx.md)                                                   | Instalación, configuración y arquitectura NgRx                    | `provideStore()`, estructura de carpetas por feature, paquetes del ecosistema      |
| [docs/21-ngrx-fundamentos/3-actions-definiendo-los-eventos-de-la-aplicacion.md](docs/21-ngrx-fundamentos/3-actions-definiendo-los-eventos-de-la-aplicacion.md)                                               | Actions: definiendo los eventos de la aplicación                  | `createAction`, `createActionGroup`, `props<T>()`, convención `[Fuente] Evento`    |
| [docs/21-ngrx-fundamentos/4-reducers-transformando-el-estado-de-forma-pura.md](docs/21-ngrx-fundamentos/4-reducers-transformando-el-estado-de-forma-pura.md)                                                 | Reducers: transformando el estado de forma pura                   | `createReducer`, `on()`, inmutabilidad, `createFeature` con selectores automáticos |
| [docs/22-ngrx-selectors-y-effects/1-selectors-consultando-el-estado-de-forma-eficiente.md](docs/22-ngrx-selectors-y-effects/1-selectors-consultando-el-estado-de-forma-eficiente.md)                         | Selectors: consultando el estado de forma eficiente               | `createFeatureSelector`, `createSelector`, composición, memoización automática     |
| [docs/22-ngrx-selectors-y-effects/2-selectors-compuestos-memoizacion-y-createselector.md](docs/22-ngrx-selectors-y-effects/2-selectors-compuestos-memoizacion-y-createselector.md)                           | Selectors compuestos, memoización y createSelector                | Selectors multi-feature, `defaultMemoize`, factory functions con parámetros        |
| [docs/22-ngrx-selectors-y-effects/3-effects-manejando-efectos-secundarios-asincronicos.md](docs/22-ngrx-selectors-y-effects/3-effects-manejando-efectos-secundarios-asincronicos.md)                         | Effects: manejando efectos secundarios asincrónicos               | `createEffect`, `ofType`, patrón action→HTTP→action, `dispatch: false`             |
| [docs/22-ngrx-selectors-y-effects/4-effects-con-operadores-rxjs-switchmap-concatmap-error-handling.md](docs/22-ngrx-selectors-y-effects/4-effects-con-operadores-rxjs-switchmap-concatmap-error-handling.md) | Effects con operadores RxJS: switchMap, concatMap, error handling | Cuándo usar cada operador, `catchError` dentro del switchMap, tabla de decisión    |
| [docs/23-ngrx-entity-y-herramientas/1-ngrx-entity-colecciones-normalizadas-con-entityadapter.md](docs/23-ngrx-entity-y-herramientas/1-ngrx-entity-colecciones-normalizadas-con-entityadapter.md)             | NgRx Entity: colecciones normalizadas con EntityAdapter           | `EntityState<T>`, `createEntityAdapter`, operaciones CRUD, selectores del adapter  |
| [docs/23-ngrx-entity-y-herramientas/2-ngrx-router-store-sincronizando-router-y-store.md](docs/23-ngrx-entity-y-herramientas/2-ngrx-router-store-sincronizando-router-y-store.md)                             | NgRx Router Store: sincronizando router y store                   | `provideRouterStore()`, `selectUrl`, `selectRouteParams`, effects con navegación   |
| [docs/23-ngrx-entity-y-herramientas/3-ngrx-devtools-debugging-con-time-travel.md](docs/23-ngrx-entity-y-herramientas/3-ngrx-devtools-debugging-con-time-travel.md)                                           | NgRx DevTools: debugging con time-travel                          | Redux DevTools Extension, inspección de acciones, time-travel, `actionSanitizer`   |
| [docs/23-ngrx-entity-y-herramientas/4-testing-de-ngrx-actions-reducers-effects-y-selectors.md](docs/23-ngrx-entity-y-herramientas/4-testing-de-ngrx-actions-reducers-effects-y-selectors.md)                 | Testing de NgRx: Actions, Reducers, Effects y Selectors           | Testing de reducers puros, `MockStore`, `overrideSelector`, `provideMockActions`   |
| [docs/24-ngrx-signal-store/1-introduccion-al-signal-store-el-nuevo-paradigma-ngrx.md](docs/24-ngrx-signal-store/1-introduccion-al-signal-store-el-nuevo-paradigma-ngrx.md)                                   | Introducción al Signal Store: el nuevo paradigma NgRx             | Motivación, primer `signalStore()`, comparación con store clásico                  |
| [docs/24-ngrx-signal-store/2-withstate-withcomputed-y-withmethods.md](docs/24-ngrx-signal-store/2-withstate-withcomputed-y-withmethods.md)                                                                   | withState, withComputed y withMethods                             | `withState<T>()` genera Signals, `withComputed()`, `withMethods()`, `patchState()` |
| [docs/24-ngrx-signal-store/3-withhooks-y-store-features-personalizadas-reutilizables.md](docs/24-ngrx-signal-store/3-withhooks-y-store-features-personalizadas-reutilizables.md)                             | withHooks y store features personalizadas reutilizables           | `onInit/onDestroy`, `withRequestStatus()`, `signalStoreFeature()`, composición     |
| [docs/24-ngrx-signal-store/4-migrando-del-ngrx-store-clasico-al-signal-store.md](docs/24-ngrx-signal-store/4-migrando-del-ngrx-store-clasico-al-signal-store.md)                                             | Migrando del NgRx Store clásico al Signal Store                   | Tabla de equivalencias, estrategia incremental, cuándo mantener el store clásico   |

---

### PARTE XII - Optimización y Rendimiento

_Capítulos 25–27 · 12 archivos_

Change Detection en profundidad, OnPush, Zoneless, Virtual Scrolling, imágenes optimizadas, análisis de bundle, Core Web Vitals y SSR completo.

| Archivo                                                                                                                                                                                          | Título                                                          | Descripción breve                                                                     |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| [docs/25-change-detection/1-como-funciona-zone-js-y-el-ciclo-de-change-detection.md](docs/25-change-detection/1-como-funciona-zone-js-y-el-ciclo-de-change-detection.md)                         | Cómo funciona Zone.js y el ciclo de Change Detection            | Monkey-patching de APIs, cuándo se dispara el CD, árbol de componentes                |
| [docs/25-change-detection/2-estrategia-onpush-cuando-y-como-usarla.md](docs/25-change-detection/2-estrategia-onpush-cuando-y-como-usarla.md)                                                     | Estrategia OnPush: cuándo y cómo usarla                         | Los 4 triggers de OnPush, inmutabilidad, antipatrones que lo rompen silenciosamente   |
| [docs/25-change-detection/3-changedetectorref-markforcheck-detach-y-control-manual.md](docs/25-change-detection/3-changedetectorref-markforcheck-detach-y-control-manual.md)                     | ChangeDetectorRef: markForCheck, detach y control manual        | `markForCheck()`, `detectChanges()`, `detach()`/`reattach()`, cuándo usarlos          |
| [docs/25-change-detection/4-zoneless-angular-con-provideexperimentalzonelesschangedetection.md](docs/25-change-detection/4-zoneless-angular-con-provideexperimentalzonelesschangedetection.md)   | Zoneless Angular con provideExperimentalZonelessChangeDetection | Eliminar Zone.js, qué deja de funcionar, checklist de migración                       |
| [docs/26-rendimiento-y-optimizacion/1-virtual-scrolling-con-cdk-listas-de-miles-de-elementos.md](docs/26-rendimiento-y-optimizacion/1-virtual-scrolling-con-cdk-listas-de-miles-de-elementos.md) | Virtual Scrolling con CDK: listas de miles de elementos         | `cdk-virtual-scroll-viewport`, `*cdkVirtualFor`, `itemSize`, limitaciones             |
| [docs/26-rendimiento-y-optimizacion/2-ngoptimizedimage-imagenes-optimizadas-out-of-the-box.md](docs/26-rendimiento-y-optimizacion/2-ngoptimizedimage-imagenes-optimizadas-out-of-the-box.md)     | NgOptimizedImage: imágenes optimizadas out-of-the-box           | `ngSrc`, `priority`, `fill`, `sizes`, loaders (Imgix, Cloudinary), impacto en LCP     |
| [docs/26-rendimiento-y-optimizacion/3-bundle-analysis-con-webpack-bundle-analyzer-y-esbuild.md](docs/26-rendimiento-y-optimizacion/3-bundle-analysis-con-webpack-bundle-analyzer-y-esbuild.md)   | Bundle analysis con webpack-bundle-analyzer y esbuild           | `--stats-json`, treemap de dependencias, `source-map-explorer`, reducir bundle        |
| [docs/26-rendimiento-y-optimizacion/4-core-web-vitals-en-apps-angular-lcp-cls-y-inp.md](docs/26-rendimiento-y-optimizacion/4-core-web-vitals-en-apps-angular-lcp-cls-y-inp.md)                   | Core Web Vitals en apps Angular: LCP, CLS y INP                 | Métricas de Google, causas específicas en Angular, checklist de 10 puntos             |
| [docs/27-server-side-rendering/1-ssr-con-angular-ssr-introduccion-e-instalacion.md](docs/27-server-side-rendering/1-ssr-con-angular-ssr-introduccion-e-instalacion.md)                           | SSR con @angular/ssr: introducción e instalación                | CSR vs SSR, `ng add @angular/ssr`, archivos generados, cuándo usar SSR                |
| [docs/27-server-side-rendering/2-hydration-e-transferstate-del-servidor-al-cliente.md](docs/27-server-side-rendering/2-hydration-e-transferstate-del-servidor-al-cliente.md)                     | Hydration e TransferState: del servidor al cliente              | `provideClientHydration()`, `TransferState`, `makeStateKey`, `withHttpTransferCache`  |
| [docs/27-server-side-rendering/3-static-site-generation-ssg-con-prerender.md](docs/27-server-side-rendering/3-static-site-generation-ssg-con-prerender.md)                                       | Static Site Generation (SSG) con prerender                      | SSG vs SSR, `"prerender": true`, rutas dinámicas, `PrerenderFallback`                 |
| [docs/27-server-side-rendering/4-ssr-con-autenticacion-cookies-y-apis-privadas.md](docs/27-server-side-rendering/4-ssr-con-autenticacion-cookies-y-apis-privadas.md)                             | SSR con autenticación, cookies y APIs privadas                  | Token `REQUEST`, cookies HttpOnly, `isPlatformBrowser`/`isPlatformServer`, `DOCUMENT` |

---

### PARTE XIII - Librerías Esenciales del Ecosistema

_Capítulos 28–31 · 16 archivos_

Angular Material (Material 3), CDK, Tailwind CSS y una suite completa de testing con Jest, Angular Testing Library y Playwright.

| Archivo                                                                                                                                                                                    | Título                                                            | Descripción breve                                                                              |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| [docs/28-angular-material/1-instalacion-y-theming-con-design-tokens-material-3.md](docs/28-angular-material/1-instalacion-y-theming-con-design-tokens-material-3.md)                       | Instalación y theming con Design Tokens (Material 3)              | `ng add @angular/material`, `mat-theme()`, paleta de colores, typography                       |
| [docs/28-angular-material/2-componentes-de-navegacion-toolbar-sidenav-tabs-menu.md](docs/28-angular-material/2-componentes-de-navegacion-toolbar-sidenav-tabs-menu.md)                     | Componentes de navegación: toolbar, sidenav, tabs, menu           | `MatSidenav` responsivo con `BreakpointObserver`, `MatTabs`, `MatMenu` con submenús            |
| [docs/28-angular-material/3-formularios-y-tablas-matinput-matselect-mattable-matpaginator.md](docs/28-angular-material/3-formularios-y-tablas-matinput-matselect-mattable-matpaginator.md) | Formularios y tablas: MatInput, MatSelect, MatTable, MatPaginator | `MatFormField`, `MatAutocomplete`, `MatTableDataSource` con sort y paginación                  |
| [docs/28-angular-material/4-overlays-matdialog-matsnackbar-matbottomsheet.md](docs/28-angular-material/4-overlays-matdialog-matsnackbar-matbottomsheet.md)                                 | Overlays: MatDialog, MatSnackBar, MatBottomSheet                  | `MatDialog.open()`, `MAT_DIALOG_DATA`, `afterClosed()`, `MatSnackBar`, `MatBottomSheet`        |
| [docs/29-angular-cdk/1-overlay-y-portal-capas-dinamicas-de-ui.md](docs/29-angular-cdk/1-overlay-y-portal-capas-dinamicas-de-ui.md)                                                         | Overlay y Portal: capas dinámicas de UI                           | `Overlay`, `ConnectedPositionStrategy`, `TemplatePortal`, `ComponentPortal`, ciclo de vida     |
| [docs/29-angular-cdk/2-drag-and-drop-con-dragdropmodule.md](docs/29-angular-cdk/2-drag-and-drop-con-dragdropmodule.md)                                                                     | Drag and Drop con DragDropModule                                  | `cdkDrag`, `cdkDropList`, `moveItemInArray`, `transferArrayItem`, kanban con tres columnas     |
| [docs/29-angular-cdk/3-accesibilidad-con-el-paquete-a11y-del-cdk.md](docs/29-angular-cdk/3-accesibilidad-con-el-paquete-a11y-del-cdk.md)                                                   | Accesibilidad con el paquete a11y del CDK                         | `FocusTrap`, `LiveAnnouncer`, `FocusMonitor`, `AriaDescriber`, dialog accesible                |
| [docs/29-angular-cdk/4-stepper-table-y-virtual-scroll-del-cdk.md](docs/29-angular-cdk/4-stepper-table-y-virtual-scroll-del-cdk.md)                                                         | Stepper, Table y Virtual Scroll del CDK                           | `CdkStepper` sin estilos Material, `CdkTableModule`, stepper de onboarding personalizado       |
| [docs/30-tailwind-css/1-instalacion-y-configuracion-de-tailwind-en-angular.md](docs/30-tailwind-css/1-instalacion-y-configuracion-de-tailwind-en-angular.md)                               | Instalación y configuración de Tailwind en Angular                | `tailwind.config.js` con `content` para templates Angular, integración con esbuild, purging    |
| [docs/30-tailwind-css/2-construyendo-componentes-ui-con-clases-utilitarias.md](docs/30-tailwind-css/2-construyendo-componentes-ui-con-clases-utilitarias.md)                               | Construyendo componentes UI con clases utilitarias                | Utility-first en templates, `@apply` en SCSS, componentes Card/Alert/Badge con Tailwind        |
| [docs/30-tailwind-css/3-responsive-design-y-dark-mode-con-tailwind.md](docs/30-tailwind-css/3-responsive-design-y-dark-mode-con-tailwind.md)                                               | Responsive design y Dark Mode con Tailwind                        | Breakpoints `sm:/md:/lg:`, `darkMode: 'class'`, toggle con Signal, `prefers-color-scheme`      |
| [docs/30-tailwind-css/4-tailwind-angular-material-convivencia-armoniosa.md](docs/30-tailwind-css/4-tailwind-angular-material-convivencia-armoniosa.md)                                     | Tailwind + Angular Material: convivencia armoniosa                | Desactivar preflight, `@layer`, estrategia híbrida Material+Tailwind para proyectos reales     |
| [docs/31-testing/1-testing-unitario-con-jest-setup-y-primeras-pruebas.md](docs/31-testing/1-testing-unitario-con-jest-setup-y-primeras-pruebas.md)                                         | Testing unitario con Jest: setup y primeras pruebas               | Migrar de Karma a Jest, `jest-preset-angular`, `TestBed`, primer test de componente standalone |
| [docs/31-testing/2-testing-de-componentes-con-angular-testing-library.md](docs/31-testing/2-testing-de-componentes-con-angular-testing-library.md)                                         | Testing de componentes con Angular Testing Library                | `render()`, `screen.getByRole()`, `userEvent`, filosofía de testing por comportamiento         |
| [docs/31-testing/3-testing-de-servicios-http-y-ngrx.md](docs/31-testing/3-testing-de-servicios-http-y-ngrx.md)                                                                             | Testing de servicios, HTTP y NgRx                                 | `HttpTestingController`, `MockStore`, `overrideSelector`, testing de effects                   |
| [docs/31-testing/4-e2e-testing-con-playwright-en-proyectos-angular.md](docs/31-testing/4-e2e-testing-con-playwright-en-proyectos-angular.md)                                               | E2E Testing con Playwright en proyectos Angular                   | `playwright.config.ts`, queries accesibles, Page Object Model, CI con GitHub Actions           |

---

### PARTE XIV - Arquitectura y Patrones Avanzados

_Capítulos 32–35 · 16 archivos_

Patrones de arquitectura escalable, micro-frontends con Module Federation y Native Federation, internacionalización, accesibilidad avanzada y despliegue en producción.

| Archivo                                                                                                                                                                                                      | Título                                                           | Descripción breve                                                                              |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| [docs/32-arquitectura-y-patrones/1-arquitectura-por-features-y-dominios-escalables.md](docs/32-arquitectura-y-patrones/1-arquitectura-por-features-y-dominios-escalables.md)                                 | Arquitectura por features y dominios escalables                  | Feature-based structure, barrel exports con `index.ts`, separación UI/dominio                  |
| [docs/32-arquitectura-y-patrones/2-smart-components-y-dumb-components.md](docs/32-arquitectura-y-patrones/2-smart-components-y-dumb-components.md)                                                           | Smart Components y Dumb Components                               | Container vs Presentational, reglas para cada tipo, relación con OnPush y testing              |
| [docs/32-arquitectura-y-patrones/3-facade-pattern-con-servicios-y-ngrx.md](docs/32-arquitectura-y-patrones/3-facade-pattern-con-servicios-y-ngrx.md)                                                         | Facade Pattern con servicios y NgRx                              | `ProductosFacade` que abstrae el store, ventajas en testing, cuándo es overhead                |
| [docs/32-arquitectura-y-patrones/4-nx-workspace-monorepos-y-arquitectura-de-librerias.md](docs/32-arquitectura-y-patrones/4-nx-workspace-monorepos-y-arquitectura-de-librerias.md)                           | Nx Workspace: monorepos y arquitectura de librerías              | `create-nx-workspace`, tagging de librerías, `nx affected:test`, `enforce-module-boundaries`   |
| [docs/33-micro-frontends/1-que-son-los-micro-frontends-y-cuando-usarlos.md](docs/33-micro-frontends/1-que-son-los-micro-frontends-y-cuando-usarlos.md)                                                       | ¿Qué son los micro-frontends y cuándo usarlos?                   | Motivación, patrones de composición (client-side/server-side), cuándo NO usar MFE              |
| [docs/33-micro-frontends/2-webpack-module-federation-con-angular.md](docs/33-micro-frontends/2-webpack-module-federation-con-angular.md)                                                                     | Webpack Module Federation con Angular                            | Host y remote con `@angular-architects/module-federation`, `shared`, versioning                |
| [docs/33-micro-frontends/3-native-federation-module-federation-sin-webpack.md](docs/33-micro-frontends/3-native-federation-module-federation-sin-webpack.md)                                                 | Native Federation: Module Federation sin Webpack                 | Import Maps nativos, `federation.config.js`, `initFederation()` en `main.ts`, comparativa      |
| [docs/33-micro-frontends/4-comunicacion-entre-micro-frontends-eventos-y-estado-compartido.md](docs/33-micro-frontends/4-comunicacion-entre-micro-frontends-eventos-y-estado-compartido.md)                   | Comunicación entre micro-frontends: eventos y estado compartido  | Custom Events, `BroadcastChannel`, shell como mediador de autenticación, qué NO compartir      |
| [docs/34-i18n-y-accesibilidad/1-i18n-nativo-con-angular-localize.md](docs/34-i18n-y-accesibilidad/1-i18n-nativo-con-angular-localize.md)                                                                     | i18n nativo con @angular/localize                                | Atributo `i18n`, `ng extract-i18n`, XLIFF, `ng build --localize`, un build por locale          |
| [docs/34-i18n-y-accesibilidad/2-transloco-la-alternativa-moderna-para-i18n-en-runtime.md](docs/34-i18n-y-accesibilidad/2-transloco-la-alternativa-moderna-para-i18n-en-runtime.md)                           | Transloco: la alternativa moderna para i18n en runtime           | `@jsverse/transloco`, JSON de traducciones, cambio de idioma sin recargar, lazy loading        |
| [docs/34-i18n-y-accesibilidad/3-accesibilidad-a11y-semantica-roles-aria-y-angular.md](docs/34-i18n-y-accesibilidad/3-accesibilidad-a11y-semantica-roles-aria-y-angular.md)                                   | Accesibilidad (a11y): semántica, roles ARIA y Angular            | HTML semántico, `aria-label`, `aria-live`, gestión del foco en SPAs                            |
| [docs/34-i18n-y-accesibilidad/4-patrones-aria-avanzados-y-auditoria-de-accesibilidad.md](docs/34-i18n-y-accesibilidad/4-patrones-aria-avanzados-y-auditoria-de-accesibilidad.md)                             | Patrones ARIA avanzados y auditoría de accesibilidad             | Dialog/Combobox/Tabs accesibles, `axe-core` en tests, Lighthouse en CI                         |
| [docs/35-despliegue-y-produccion/1-configuracion-de-entornos-environment-ts-y-variables-de-entorno.md](docs/35-despliegue-y-produccion/1-configuracion-de-entornos-environment-ts-y-variables-de-entorno.md) | Configuración de entornos: environment.ts y variables de entorno | `fileReplacements`, `APP_CONFIG` con `InjectionToken`, config en runtime con `APP_INITIALIZER` |
| [docs/35-despliegue-y-produccion/2-ci-cd-con-github-actions-build-test-y-deploy-automatico.md](docs/35-despliegue-y-produccion/2-ci-cd-con-github-actions-build-test-y-deploy-automatico.md)                 | CI/CD con GitHub Actions: build, test y deploy automático        | Workflow YAML completo, caché de `node_modules`, deploy a GitHub Pages/Firebase/Vercel         |
| [docs/35-despliegue-y-produccion/3-dockerizacion-de-apps-angular-y-deploy-en-cloud.md](docs/35-despliegue-y-produccion/3-dockerizacion-de-apps-angular-y-deploy-en-cloud.md)                                 | Dockerización de apps Angular y deploy en cloud                  | Dockerfile multi-stage, `nginx.conf` para SPA, Cloud Run y ECS Fargate                         |
| [docs/35-despliegue-y-produccion/4-monitoreo-error-tracking-con-sentry-y-analytics.md](docs/35-despliegue-y-produccion/4-monitoreo-error-tracking-con-sentry-y-analytics.md)                                 | Monitoreo, error tracking con Sentry y analytics                 | `@sentry/angular`, `ErrorHandler`, GA4 con consent management, GDPR                            |

---

### PARTE XV - Angular 20 y el Futuro del Framework

_Capítulo 36 · 4 archivos_

Las novedades estables de Angular 20: `@let` en templates, signal-based queries, `linkedSignal()` y `resource()` estables, hydratación incremental, modos de renderizado por ruta, HMR mejorado, y el roadmap hacia Angular 21 con Zoneless estable y Signal Forms.

| Archivo                                                                                                                                                                                | Título                                                    | Descripción breve                                                                                  |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| [docs/36-zoneless-y-el-futuro/1-let-en-templates-y-signal-based-queries.md](docs/36-zoneless-y-el-futuro/1-let-en-templates-y-signal-based-queries.md)                                 | `@let` en templates y signal-based queries                | Declaración de variables locales reactivas, `viewChild()`/`contentChild()` como Signals            |
| [docs/36-zoneless-y-el-futuro/2-linkedsignal-resource-y-httpresource-en-angular-20.md](docs/36-zoneless-y-el-futuro/2-linkedsignal-resource-y-httpresource-en-angular-20.md)           | linkedSignal(), resource() y httpResource() en Angular 20 | APIs promovidas a developer preview/estable, comparativa con enfoques anteriores                   |
| [docs/36-zoneless-y-el-futuro/3-hydratacion-incremental-y-modos-de-renderizado-por-ruta.md](docs/36-zoneless-y-el-futuro/3-hydratacion-incremental-y-modos-de-renderizado-por-ruta.md) | Hydratación incremental y modos de renderizado por ruta   | `withIncrementalHydration()`, `@defer hydrate on`, `RenderMode` por ruta en `app.routes.server.ts` |
| [docs/36-zoneless-y-el-futuro/4-zoneless-angular-21-y-el-roadmap-del-framework.md](docs/36-zoneless-y-el-futuro/4-zoneless-angular-21-y-el-roadmap-del-framework.md)                   | Zoneless, Angular 21 y el roadmap del framework           | `provideZonelessChangeDetection()` estable, Signal Forms, `@angular/build`, hoja de ruta           |

---

### PARTE XVI - Angular 22

_Capítulo 37 · 4 archivos_

Cubre la versión estable más reciente del framework: `OnPush` como estrategia de change detection por defecto, Signal Forms con su API definitiva (`form()`/`field()`), los decoradores `@Service()` e `injectAsync()` para inyección de dependencias, Angular Aria estable y las mejoras acumuladas de sintaxis en templates.

| Archivo                                                                                                                                                                                  | Título                                                                   | Descripción breve                                                                                                                                         |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [docs/37-angular-22/1-angular-22-onpush-por-defecto-y-la-nueva-base-del-framework.md](docs/37-angular-22/1-angular-22-onpush-por-defecto-y-la-nueva-base-del-framework.md)               | Angular 22: OnPush por defecto y la nueva base del framework             | `ChangeDetectionStrategy.OnPush` como default, `Eager` como opt-out, migración con `ng update`, TypeScript 6, `HttpClient` con `FetchBackend` por defecto |
| [docs/37-angular-22/2-signal-forms-estables-form-field-y-fieldtree.md](docs/37-angular-22/2-signal-forms-estables-form-field-y-fieldtree.md)                                             | Signal Forms estables: form(), field() y FieldTree                       | API definitiva desde `@angular/forms/signals`, `[formField]`/`[formRoot]`, submission API, `validateStandardSchema` con Zod                               |
| [docs/37-angular-22/3-service-injectasync-y-la-evolucion-de-la-inyeccion-de-dependencias.md](docs/37-angular-22/3-service-injectasync-y-la-evolucion-de-la-inyeccion-de-dependencias.md) | @Service(), injectAsync() y la evolución de la inyección de dependencias | `@Service()` vs `@Injectable`, `autoProvided: false`, `injectAsync()` con `prefetch: onIdle`                                                              |
| [docs/37-angular-22/4-angular-aria-estable-templates-y-el-ecosistema-de-angular-22.md](docs/37-angular-22/4-angular-aria-estable-templates-y-el-ecosistema-de-angular-22.md)             | Angular Aria estable, templates y el ecosistema de Angular 22            | Patrones headless de accesibilidad, spread/rest, `@switch` exhaustivo con `never()`, `isActive()` del router, WebMCP y `@boundary` en preview             |

---

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

---

## Contribuidores

Gracias a todas las personas que contribuyan con correcciones, sugerencias y mejoras a través de issues y pull requests.
