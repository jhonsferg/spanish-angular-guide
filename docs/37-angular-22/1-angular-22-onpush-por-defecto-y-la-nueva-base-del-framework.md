# Capítulo 37 - Parte 1: Angular 22: OnPush por defecto y la nueva base del framework

> **Parte 1 de 4** · Capítulo 37 · PARTE XVI - Angular 22

Angular 22 llegó el 3 de junio de 2026 como la culminación del ciclo que empezó con Zoneless estable en Angular 21: en vez de sumar features experimentales, el equipo se dedicó a **graduar lo que ya estaba probado** y a **subir el piso del toolchain**. El resultado es un release con pocos features nuevos pero con decisiones de fondo — la más importante en años para el modelo mental de change detection.

## `OnPush` es ahora la estrategia por defecto

Desde la primera versión de Angular moderno se discutió si `OnPush` debería ser el comportamiento por defecto en vez de una estrategia opt-in. En Angular 22 esa discusión se cierra: **todo componente sin `changeDetection` explícito ahora usa `OnPush`**. La estrategia anterior por defecto se renombra `Eager` y sigue disponible para quien la necesite explícitamente.

```typescript
// Angular 22 - un componente sin "changeDetection" ya es OnPush
import { Component, signal } from "@angular/core";

@Component({
  selector: "app-contador",
  standalone: true,
  template: ` <button (click)="incrementar()">{{ contador() }}</button> `,
})
export class ContadorComponent {
  // Con OnPush por defecto, Signals es la forma natural de disparar
  // detección de cambios - ya no hace falta declarar la estrategia
  contador = signal(0);

  incrementar(): void {
    this.contador.update((valor) => valor + 1);
  }
}
```

```typescript
// Para mantener el comportamiento clásico (chequeo en cada ciclo),
// hay que optar explícitamente por "Eager"
import { ChangeDetectionStrategy, Component } from "@angular/core";

@Component({
  selector: "app-legado",
  changeDetection: ChangeDetectionStrategy.Eager,
  template: `...`,
})
export class LegadoComponent {}
```

→ Ver Capítulo 25, Parte 2 para los cuatro triggers de `OnPush` y los antipatrones que lo rompen silenciosamente - siguen aplicando igual en Angular 22, solo que ahora son el comportamiento por defecto en vez de la excepción.

### Migración automática con `ng update`

El schematic de migración de `ng update` recorre el código y **añade `changeDetection: ChangeDetectionStrategy.Eager` explícitamente a cualquier componente que no declaraba una estrategia**, preservando el comportamiento exacto que tenía el proyecto antes de actualizar. Es decir: la migración no asume que tu código está listo para `OnPush`, sino que congela el comportamiento anterior componente por componente para que decidas tú, con calma, cuáles migrar a `OnPush` real.

```bash
# Migrar de Angular 21 a Angular 22
ng update @angular/cli@22 @angular/core@22

# El schematic:
# 1. Añade `changeDetection: ChangeDetectionStrategy.Eager` a componentes sin estrategia
# 2. Añade `strictTemplates: false` en tsconfig si no estaba presente
#    (para no romper builds con el chequeo de tipos más estricto)
```

Una vez migrado, el trabajo real es ir quitando `Eager` componente por componente y verificando que sigan actualizándose correctamente con Signals, `async pipe` o `markForCheck()` manual - exactamente el mismo checklist que ya usábamos para adoptar `OnPush` manualmente.

## TypeScript 6 y el piso mínimo del toolchain

Angular 22 requiere **TypeScript 6** como mínimo y **deja de soportar Node 20** (el mínimo pasa a ser Node 22 LTS). Ambos cambios siguen la política de soporte de Angular de alinear el framework con las versiones LTS activas del ecosistema, y son parte de por qué la migración automática agrega `strictTemplates: false` cuando hace falta: el chequeo de tipos en templates se volvió más estricto por defecto y algunos proyectos con `any` implícitos necesitan ese respiro temporal.

## `HttpClient` usa `FetchBackend` por defecto

Desde Angular 22, `HttpClient` usa la API `fetch` del navegador como backend por defecto en vez de `XMLHttpRequest`. Esto no es nuevo - `withFetch()` existía como opción desde hace varias versiones - pero ahora es el comportamiento out-of-the-box, así que `withFetch()` queda deprecado (ya no hace falta pedirlo explícitamente).

```typescript
// Antes de Angular 22 - había que pedir el fetch backend explícitamente
provideHttpClient(withFetch());

// Angular 22 - fetch ya es el backend por defecto, no hace falta el flag
provideHttpClient();

// Si tu app depende de XHR (por ejemplo, para progreso de subida de archivos
// en navegadores donde Fetch todavía no soporta ReadableStream en el request body)
provideHttpClient(withXhr());
```

Como consecuencia directa, el progreso de peticiones se separó en dos opciones porque `fetch` solo soporta reportar progreso de descarga de forma nativa:

```typescript
// Progreso de descarga - funciona con el FetchBackend por defecto
this.http.get("/archivo-grande.zip", {
  reportDownloadProgress: true,
  observe: "events",
});

// Progreso de subida - todavía requiere XHR
this.http.post("/subir", archivo, {
  reportUploadProgress: true,
  observe: "events",
});
// (requiere provideHttpClient(withXhr()) en la configuración de la app)
```

→ Ver Capítulo 14, Parte 4 para `HttpHeaders`, `HttpParams` y el resto de opciones avanzadas de `HttpClient` que siguen funcionando igual sobre el nuevo backend.

## Otros breaking changes a tener en cuenta

La lista completa está en la guía oficial de actualización (`ng update` te la resume interactivamente), pero estos son los que afectan a más proyectos reales:

| Cambio                                                                     | Qué hacer                                                                                                             |
| -------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `ComponentFactoryResolver` y `ComponentFactory` eliminados                 | Usar `ViewContainerRef.createComponent(Componente)` directamente (API disponible desde Angular 13)                    |
| `createNgModuleRef` eliminado                                              | Usar `createNgModule`                                                                                                 |
| `ChangeDetectorRef.checkNoChanges` eliminado                               | Usar los helpers de testing (`ComponentFixture.detectChanges` con `checkNoChanges` interno)                           |
| `provideRoutes()` eliminado                                                | Usar `provideRouter(routes)`                                                                                          |
| Soporte a Hammer.js eliminado de `platform-browser`                        | Migrar gestos táctiles a librerías activas o a Angular CDK                                                            |
| `paramsInheritanceStrategy` por defecto pasa de `'emptyOnly'` a `'always'` | Revisar rutas hijas que dependían de **no** heredar params - no hay migración automática, hay que auditar manualmente |

## Puntos clave

- `OnPush` es la estrategia de change detection por defecto en Angular 22; el comportamiento anterior se renombra `Eager` y sigue disponible
- `ng update` migra automáticamente marcando `Eager` explícito donde hace falta, sin forzar a nadie a adoptar `OnPush` de golpe
- TypeScript 6 y Node 22 son los mínimos requeridos; `strictTemplates` queda activado por defecto
- `HttpClient` usa `FetchBackend` por defecto; `withFetch()` queda deprecado y `withXhr()` es la vía explícita para progreso de subida
- `provideRoutes()`, `ComponentFactoryResolver`, `createNgModuleRef` y el soporte a Hammer.js se eliminaron - no hay ambigüedad, son APIs removidas, no deprecadas

## ¿Qué sigue?

En la Parte 2 cubrimos la feature insignia de Angular 22: Signal Forms pasa de developer preview a **estable**, con una API definitiva (`form()` y `field()`) que reemplaza al preview que vimos en el Capítulo 36.
