# Capítulo 37 - Parte 3: @Service(), injectAsync() y la evolución de la inyección de dependencias

> **Parte 3 de 4** · Capítulo 37 · PARTE XVI - Angular 22

Angular 22 no reemplaza el sistema de DI que vimos en el Capítulo 8 - `@Injectable`, `inject()` y la jerarquía de inyectores siguen funcionando exactamente igual. Lo que añade son dos herramientas nuevas para los dos problemas más comunes al escribir servicios hoy: simplificar el caso más frecuente (un singleton de toda la app) y resolver el caso menos frecuente pero costoso (un servicio pesado que no siempre hace falta).

## `@Service()`: la forma opinionada de declarar un singleton

`@Service()` es un decorador nuevo pensado para el patrón más común de todos: un servicio que se provee una sola vez, a nivel raíz, escrito con `inject()` en vez de inyección por constructor.

```typescript
// Con @Injectable - hay que pedir explícitamente providedIn: 'root'
import { Injectable, signal } from "@angular/core";
import { HttpClient, httpResource } from "@angular/common/http";

@Injectable({ providedIn: "root" })
export class VuelosService {
  private http = inject(HttpClient);
  usuarioSeleccionado = signal<number | null>(null);
  vuelos = httpResource<Vuelo[]>(() => `${API_BASE}/vuelos`, {
    defaultValue: [],
  });
}
```

```typescript
// Con @Service() - root-provided por defecto, sin flags
import { Service, signal, inject } from "@angular/core";
import { HttpClient, httpResource } from "@angular/common/http";

@Service()
export class VuelosService {
  private http = inject(HttpClient);
  usuarioSeleccionado = signal<number | null>(null);
  vuelos = httpResource<Vuelo[]>(() => `${API_BASE}/vuelos`, {
    defaultValue: [],
  });
}
```

La diferencia no es solo que `@Service()` ahorre escribir `{ providedIn: 'root' }`. El decorador es **más estricto a propósito**: fuerza el patrón moderno con `inject()` y **rechaza en tiempo de compilación** cualquier dependencia declarada por parámetro de constructor.

```typescript
// Esto NO compila con @Service()
@Service()
export class VuelosService {
  constructor(private http: HttpClient) {} // Error de compilación
}

// Forma correcta
@Service()
export class VuelosService {
  private http = inject(HttpClient); // Obligatorio usar inject()
}
```

→ Ver Capítulo 8, Parte 2 para la diferencia entre inyección por constructor e `inject()` - `@Service()` básicamente convierte en regla obligatoria lo que ya era la práctica recomendada desde Angular 14.

### `@Service({ autoProvided: false })`: servicios con scope de componente

No todos los servicios deben vivir en el inyector raíz. Para un servicio pensado para el ciclo de vida de un componente específico (por ejemplo, estado de un formulario en edición que debe destruirse junto con el componente), `autoProvided: false` desactiva el auto-registro en root y exige proveerlo explícitamente:

```typescript
@Service({ autoProvided: false })
export class BorradorVueloService {
  origen = signal("");
  esValido = computed(() => this.origen().length > 3);
}

@Component({
  selector: "app-panel-borrador",
  standalone: true,
  providers: [BorradorVueloService], // Debe declararse explícitamente
  template: `...`,
})
export class PanelBorradorComponent {
  protected borrador = inject(BorradorVueloService);
}
```

→ Ver Capítulo 8, Parte 4 para la jerarquía de inyectores completa - `@Service({ autoProvided: false })` en un componente se comporta igual que un `@Injectable()` sin `providedIn` listado en el array `providers` del componente: una instancia nueva por cada árbol de componentes donde se provea.

`@Service()` es la opción recomendada para la mayoría de servicios nuevos de aplicación, no un reemplazo universal de `@Injectable()`. Configuraciones de DI avanzadas (multi-providers, factories complejas, `useExisting`) siguen requiriendo `@Injectable()` o proveedores explícitos.

## `injectAsync()`: servicios pesados que no siempre hacen falta

Algunos servicios son costosos de cargar pero se usan solo en un flujo específico - un exportador de PDF, un editor de texto enriquecido, un cliente de un SDK grande de terceros. Antes de Angular 22, la única forma de aplazar ese costo era envolver manualmente un `import()` dinámico y perder el patrón habitual de inyección. `injectAsync()` resuelve esto a nivel de servicio:

```typescript
import { Component, injectAsync } from "@angular/core";

@Component({
  selector: "app-reporte",
  standalone: true,
  template: `<button (click)="generar()">Generar reporte</button>`,
})
export class ReporteComponent {
  private getReportService = injectAsync(() =>
    import("./report.service").then((m) => m.ReportService),
  );

  protected async generar(): Promise<void> {
    const service = await this.getReportService();
    service.generar();
  }
}
```

El servicio (`ReportService`, en este caso) se compila en su **propio chunk** y no se descarga hasta la primera vez que se invoca `getReportService()`. Es una optimización a nivel de bundle equivalente a `loadComponent`/`loadChildren` en el router (Capítulo 11, Parte 1), pero aplicada a un servicio individual en vez de a una ruta completa.

Un requisito importante: el servicio inyectado con `injectAsync()` debe estar auto-provisto - con `@Service()` o con `@Injectable({ providedIn: 'root' })`. `injectAsync()` no reemplaza la configuración de providers, solo aplaza la descarga del chunk.

### Precarga en tiempo idle con `prefetch: onIdle`

Para servicios que probablemente se van a necesitar pero no de inmediato, `injectAsync()` acepta una estrategia de prefetch que descarga el chunk quando el navegador está inactivo, sin bloquear la carga inicial:

```typescript
import { injectAsync, onIdle } from "@angular/core";

// Precarga el chunk en tiempo idle del navegador
private readonly upgradeService = injectAsync(
  () => import("./upgrade-service").then((m) => m.UpgradeService),
  { prefetch: onIdle },
);

// Con timeout configurable - fuerza la precarga si el navegador
// nunca reporta tiempo idle dentro del plazo indicado
private readonly upgradeService2 = injectAsync(
  () => import("./upgrade-service").then((m) => m.UpgradeService),
  { prefetch: () => onIdle({ timeout: 100 }) },
);
```

Este patrón es análogo a las estrategias de preloading del router que vimos en el Capítulo 11, Parte 4 (`PreloadAllModules`, estrategias personalizadas), pero a nivel de servicio individual: el chunk se descarga de fondo sin que el usuario tenga que esperar, y `await getReportService()` resuelve instantáneamente si el prefetch ya terminó.

## Puntos clave

- `@Service()` es una alternativa opinionada a `@Injectable({ providedIn: 'root' })`: root-provided por defecto, prohíbe inyección por constructor y fuerza `inject()`
- `@Service({ autoProvided: false })` da servicios con scope de componente, análogo a `@Injectable()` sin `providedIn` provisto explícitamente en `providers`
- `@Service()` no reemplaza `@Injectable()` en casos de DI avanzada (multi-providers, factories, `useExisting`)
- `injectAsync()` carga un servicio en su propio chunk, descargado solo al invocarlo por primera vez - útil para servicios pesados de uso ocasional
- `prefetch: onIdle` precarga el chunk en tiempo idle del navegador sin bloquear el arranque de la app; el servicio debe estar auto-provisto para poder usarse con `injectAsync()`

## ¿Qué sigue?

En la Parte 4, la última del capítulo, cubrimos Angular Aria ya estable, las mejoras de sintaxis en templates (spread, `@switch` exhaustivo, funciones flecha), el nuevo `isActive()` del router, y un vistazo breve a lo que sigue en preview (WebMCP, `@boundary`).
