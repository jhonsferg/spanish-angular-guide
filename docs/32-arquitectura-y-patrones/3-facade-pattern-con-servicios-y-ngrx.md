# Capítulo 32 - Parte 3: Facade Pattern con servicios y NgRx

> **Parte 3 de 4** · Capítulo 32 · PARTE XIV - Arquitectura y Patrones Avanzados

Cuando un componente Smart necesita obtener datos del store y despachar acciones, el código se llena de referencias a acciones, selectores y efectos de NgRx. Esto crea un acoplamiento directo entre la UI y la tecnología de gestión de estado. Si algún día queremos migrar de NgRx a Signals, o simplificar la solución para un feature pequeño, tenemos que tocar cada componente que interactuó con el store. El Facade Pattern resuelve esto poniendo una capa intermedia que actúa como la única puerta de entrada al estado de un feature.

## La idea central del Facade

Un Facade es un servicio que expone solo lo que los componentes necesitan ver, ocultando completamente cómo se implementa el estado por debajo. Desde la perspectiva del componente, la Facade es solo un servicio con Observables y métodos. No importa si detrás hay NgRx, un BehaviorSubject simple, una señal, o una llamada HTTP directa.

Pensemos en la analogía de un recepcionista de hotel. El huésped no necesita saber si la habitación ya estaba lista o si el recepcionista tuvo que llamar al equipo de limpieza, revisar el sistema, y reasignar el cuarto. El huésped solo dice "quiero hacer el check-in" y recibe su llave. La Facade es ese recepcionista.

## Implementación completa: ProductosFacade con NgRx

Primero definamos el store que la Facade va a abstraer:

```typescript
// features/productos/store/productos.actions.ts
import { createAction, props } from '@ngrx/store';
import { Producto, FiltroProductos } from '../models/producto.model';

export const cargarProductos = createAction(
  '[Productos] Cargar Productos',
  props<{ filtro?: FiltroProductos }>()
);
export const cargarProductosExito = createAction(
  '[Productos API] Cargar Productos Éxito',
  props<{ productos: Producto[] }>()
);
export const cargarProductosError = createAction(
  '[Productos API] Cargar Productos Error',
  props<{ error: string }>()
);
export const eliminarProducto = createAction(
  '[Productos] Eliminar Producto',
  props<{ id: string }>()
);
export const seleccionarProducto = createAction(
  '[Productos] Seleccionar Producto',
  props<{ id: string }>()
);
```

```typescript
// features/productos/store/productos.selectors.ts
import { createFeatureSelector, createSelector } from '@ngrx/store';

export interface EstadoProductos {
  items: Producto[];
  cargando: boolean;
  error: string | null;
  idSeleccionado: string | null;
}

export const selectFeatureProductos =
  createFeatureSelector<EstadoProductos>('productos');

export const selectTodosLosProductos = createSelector(
  selectFeatureProductos,
  estado => estado.items
);
export const selectCargando = createSelector(
  selectFeatureProductos,
  estado => estado.cargando
);
export const selectError = createSelector(
  selectFeatureProductos,
  estado => estado.error
);
export const selectProductoActivo = createSelector(
  selectFeatureProductos,
  estado => estado.items.find(p => p.id === estado.idSeleccionado) ?? null
);
```

Ahora la estrella del capítulo: la Facade que encapsula todo esto:

```typescript
// features/productos/services/productos.facade.ts
import { Injectable, inject } from '@angular/core';
import { Store } from '@ngrx/store';
import { Observable } from 'rxjs';
import { Producto, FiltroProductos } from '../models/producto.model';
import * as ProductosActions from '../store/productos.actions';
import * as ProductosSelectors from '../store/productos.selectors';

@Injectable({ providedIn: 'root' })
export class ProductosFacade {
  private readonly store = inject(Store);

  // API de lectura: solo Observables, no selectores
  readonly productos$: Observable<Producto[]> =
    this.store.select(ProductosSelectors.selectTodosLosProductos);

  readonly cargando$: Observable<boolean> =
    this.store.select(ProductosSelectors.selectCargando);

  readonly error$: Observable<string | null> =
    this.store.select(ProductosSelectors.selectError);

  readonly productoActivo$: Observable<Producto | null> =
    this.store.select(ProductosSelectors.selectProductoActivo);

  // API de escritura: solo métodos con nombres de dominio
  cargarProductos(filtro?: FiltroProductos): void {
    this.store.dispatch(ProductosActions.cargarProductos({ filtro }));
  }

  seleccionarProducto(id: string): void {
    this.store.dispatch(ProductosActions.seleccionarProducto({ id }));
  }

  eliminarProducto(id: string): void {
    this.store.dispatch(ProductosActions.eliminarProducto({ id }));
  }
}
```

La belleza está en lo que **no** exponemos: ninguna acción, ningún selector, nada del vocabulario de NgRx. Un componente que usa esta Facade nunca necesita hacer `import from '@ngrx/store'`.

## El componente Smart con Facade: qué tan limpio queda

Comparemos. Sin Facade, el Container luce así:

```typescript
// SIN FACADE: acoplado a NgRx directamente
import { Store } from '@ngrx/store';
import * as ProductosActions from '../store/productos.actions';
import * as ProductosSelectors from '../store/productos.selectors';

export class ProductosPageComponent {
  private readonly store = inject(Store);
  productos$ = this.store.select(ProductosSelectors.selectTodosLosProductos);

  eliminar(id: string): void {
    this.store.dispatch(ProductosActions.eliminarProducto({ id }));
  }
}
```

Con Facade, el mismo componente queda así:

```typescript
// CON FACADE: desacoplado, legible, testeable
import { ProductosFacade } from '../services/productos.facade';

export class ProductosPageComponent implements OnInit {
  protected readonly facade = inject(ProductosFacade);

  ngOnInit(): void {
    this.facade.cargarProductos();
  }

  protected eliminar(id: string): void {
    this.facade.eliminarProducto(id);
  }
}
```

La diferencia en legibilidad es notable, pero la diferencia en testabilidad es aún mayor.

## Testing con Facade: mockear una sola cosa

Sin Facade, para testear el Container necesitamos configurar un store de NgRx completo o mockear el Store. Con Facade, solo necesitamos un spy simple:

```typescript
// Test limpio gracias al Facade
describe('ProductosPageComponent', () => {
  let facadeMock: jasmine.SpyObj<ProductosFacade>;

  beforeEach(async () => {
    facadeMock = jasmine.createSpyObj<ProductosFacade>(
      'ProductosFacade',
      ['cargarProductos', 'eliminarProducto', 'seleccionarProducto'],
      {
        productos$: of([mockProducto1, mockProducto2]),
        cargando$: of(false),
        error$: of(null),
        productoActivo$: of(null)
      }
    );

    await TestBed.configureTestingModule({
      imports: [ProductosPageComponent],
      providers: [{ provide: ProductosFacade, useValue: facadeMock }]
    }).compileComponents();
  });

  it('llama a cargarProductos al iniciar', () => {
    const fixture = TestBed.createComponent(ProductosPageComponent);
    fixture.detectChanges();
    expect(facadeMock.cargarProductos).toHaveBeenCalledOnce();
  });
});
```

## Ventajas de implementar Facades

**Desacoplamiento tecnológico**: si mañana NgRx se vuelve demasiado pesado para un feature y queremos simplificarlo con un BehaviorSubject, solo modificamos la Facade. Los componentes no cambian.

**API orientada al dominio**: `facade.cargarProductos()` es lenguaje de negocio. `store.dispatch(new CargarProductosAction())` es lenguaje técnico. El componente debería hablar el lenguaje del negocio.

**Punto único de prueba**: para verificar que un feature completo funciona, podemos testear la Facade de forma aislada sin renderizar ningún componente.

## Desventajas y cuándo es overhead

El Facade no es gratis. Agrega una capa adicional de indirección que tiene costos reales:

**Más archivos, más mantenimiento**: cada feature necesita su Facade además del store. En un proyecto con 20 features, son 20 Facades extra que mantener.

**Puede esconder complejidad en lugar de reducirla**: si la Facade tiene 30 métodos y 20 Observables, el problema no es la falta de Facade, el problema es que el feature es demasiado grande.

**Overhead en features pequeñas**: si un feature tiene dos acciones y un selector, la Facade añade más burocracia que valor. En este caso es perfectamente válido que el Container use el Store directamente.

Una heurística útil: si el componente importa más de dos cosas de NgRx (actions + selectors + store = ya son tres imports), considera agregar una Facade.

## Facade con Signals en lugar de NgRx

Angular 17+ con Signals permite una Facade igualmente limpia pero sin NgRx:

```typescript
// features/productos/services/productos-signal.facade.ts
import { Injectable, inject, signal, computed } from '@angular/core';
import { ProductosService } from './productos.service';
import { Producto } from '../models/producto.model';

@Injectable({ providedIn: 'root' })
export class ProductosFacade {
  private readonly servicio = inject(ProductosService);

  private readonly _productos = signal<Producto[]>([]);
  private readonly _cargando = signal<boolean>(false);
  private readonly _error = signal<string | null>(null);

  // API pública de lectura: signals computadas
  readonly productos = computed(() => this._productos());
  readonly cargando = computed(() => this._cargando());
  readonly error = computed(() => this._error());

  cargarProductos(): void {
    this._cargando.set(true);
    this.servicio.obtenerTodos().subscribe({
      next: lista => {
        this._productos.set(lista);
        this._cargando.set(false);
      },
      error: err => {
        this._error.set(err.message);
        this._cargando.set(false);
      }
    });
  }
}
```

Los componentes que usan esta Facade no notan la diferencia: siguen llamando `facade.cargarProductos()` y leyendo `facade.productos`. La implementación interna cambió completamente.

## Puntos clave

- El Facade Pattern es un servicio que expone una API orientada al dominio (métodos y Observables/Signals con nombres de negocio) ocultando completamente si el estado viene de NgRx, Signals o cualquier otra solución.
- Los componentes que usan Facades no importan nada de `@ngrx/store`: cero acoplamiento a la tecnología de gestión de estado.
- El testing se simplifica dramáticamente: en lugar de configurar un store completo, basta con un spy object de la Facade.
- Las Facades son overhead en features pequeñas con pocas acciones; el punto de inflexión está alrededor de 3 o más imports de NgRx en un solo componente.
- La Facade hace que migrar entre soluciones de estado (NgRx a Signals, o viceversa) sea una operación local al feature, sin impacto en los componentes.

## ¿Qué sigue?

En la siguiente parte damos el salto a la escala de la organización: los monorepos con Nx Workspace, donde múltiples aplicaciones comparten código de forma estructurada con límites de dependencia explícitos.
