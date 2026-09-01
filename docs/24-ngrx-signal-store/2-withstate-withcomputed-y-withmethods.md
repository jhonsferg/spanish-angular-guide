# Capítulo 24 - Parte 2: withState, withComputed y withMethods

> **Parte 2 de 4** · Capítulo 24 · PARTE XI - Gestión de Estado con NgRx

---

## Los tres building blocks fundamentales

El Signal Store se construye componiendo funciones llamadas "store features". Las tres más importantes son `withState`, `withComputed` y `withMethods`. Juntas definen la forma completa de cualquier store: el estado, lo que se puede derivar de él, y cómo puede cambiar. Veamos cada una en profundidad con un ejemplo real de dominio.

---

## withState: el estado como Signals automáticos

`withState<T>(estadoInicial)` es el punto de partida. Recibe el estado inicial y transforma automáticamente cada propiedad en un Signal de solo lectura accesible desde el store.

```typescript
// src/app/productos/productos.store.ts
import {
  signalStore,
  withState,
  withComputed,
  withMethods,
  patchState,
} from '@ngrx/signals';
import { computed, inject } from '@angular/core';
import { rxMethod } from '@ngrx/signals/rxjs-interop';
import { pipe, switchMap, tap } from 'rxjs';
import { tapResponse } from '@ngrx/operators';
import { ProductosService } from './servicios/productos.service';

export interface Producto {
  id: string;
  nombre: string;
  precio: number;
  categoria: string;
  stock: number;
}

export interface EstadoProductos {
  productos: Producto[];
  productoSeleccionadoId: string | null;
  cargando: boolean;
  error: string | null;
  terminoBusqueda: string;
}

const estadoInicial: EstadoProductos = {
  productos: [],
  productoSeleccionadoId: null,
  cargando: false,
  error: null,
  terminoBusqueda: '',
};
```

Una vez que definimos el estado inicial, `withState` hace que cada propiedad esté disponible como `store.propiedad()`, donde el `()` indica que es un Signal que se llama para leer su valor:

```typescript
// Dentro de un componente:
// store.productos()          → Producto[]
// store.cargando()           → boolean
// store.terminoBusqueda()    → string
// store.productoSeleccionadoId() → string | null
```

Los Signals generados son de solo lectura. No se pueden mutar directamente desde fuera del store, lo cual preserva el principio de que el estado solo se modifica a través de métodos controlados.

---

## withComputed: estado derivado reactivo

`withComputed` recibe una función que tiene acceso a todos los Signals del estado actual, y devuelve un objeto con nuevos Signals derivados. Estos Signals son `computed()` de Angular, lo que significa que se recalculan automáticamente y de forma lazy cuando cambian sus dependencias.

```typescript
withComputed(({ productos, terminoBusqueda, productoSeleccionadoId }) => ({
  productosFiltrados: computed(() => {
    const termino = terminoBusqueda().toLowerCase().trim();
    if (!termino) return productos();
    return productos().filter(
      (p) =>
        p.nombre.toLowerCase().includes(termino) ||
        p.categoria.toLowerCase().includes(termino)
    );
  }),

  totalProductos: computed(() => productos().length),

  totalEnStock: computed(() =>
    productos().reduce((suma, p) => suma + p.stock, 0)
  ),

  productoSeleccionado: computed(() => {
    const id = productoSeleccionadoId();
    if (!id) return null;
    return productos().find((p) => p.id === id) ?? null;
  }),

  precioPromedio: computed(() => {
    const lista = productos();
    if (lista.length === 0) return 0;
    return lista.reduce((suma, p) => suma + p.precio, 0) / lista.length;
  }),

  hayProductos: computed(() => productos().length > 0),
})),
```

La parte clave es que los computed acceden a los Signals llamándolos como funciones dentro del `computed(() => ...)`. Angular rastrea automáticamente estas dependencias y recalcula el computed solo cuando alguna de ellas cambia.

Un detalle importante: `withComputed` también puede recibir los computed definidos previamente en el mismo bloque si necesitamos componer derivaciones. Sin embargo, para ese caso es más limpio encadenar un segundo `withComputed`.

---

## withMethods: las mutaciones y acciones del store

`withMethods` define los métodos que el store expone para que los componentes interactúen con él. Recibe el store completo (con acceso a estado y computed) y devuelve un objeto con métodos:

```typescript
withMethods((store, productosService = inject(ProductosService)) => ({
  seleccionarProducto(id: string): void {
    patchState(store, { productoSeleccionadoId: id });
  },

  deseleccionarProducto(): void {
    patchState(store, { productoSeleccionadoId: null });
  },

  buscar(termino: string): void {
    patchState(store, { terminoBusqueda: termino });
  },

  limpiarBusqueda(): void {
    patchState(store, { terminoBusqueda: '' });
  },

  actualizarPrecio(id: string, nuevoPrecio: number): void {
    patchState(store, (estado) => ({
      productos: estado.productos.map((p) =>
        p.id === id ? { ...p, precio: nuevoPrecio } : p
      ),
    }));
  },

  async cargarProductos(): Promise<void> {
    patchState(store, { cargando: true, error: null });
    try {
      const productos = await productosService.obtenerTodos();
      patchState(store, { productos, cargando: false });
    } catch (err) {
      const mensaje = err instanceof Error ? err.message : 'Error desconocido';
      patchState(store, { error: mensaje, cargando: false });
    }
  },
})),
```

Observemos varios patrones en `withMethods`:

**Inyección de servicios**: el segundo parámetro de la función callback nos permite usar `inject()`. Esta es la forma idiomática de acceder a servicios dentro del store.

**`patchState` con objeto parcial**: la forma más simple de mutar. Solo las propiedades incluidas se actualizan; el resto permanece igual.

**`patchState` con función**: cuando la mutación depende del estado actual (como `actualizarPrecio`), pasamos una función que recibe el estado actual y devuelve el objeto parcial con los cambios.

**Métodos async**: los métodos pueden ser funciones async normales. NgRx no impone ninguna restricción en este sentido.

---

## rxMethod para flujos reactivos

Para casos donde queremos trabajar con Observables en lugar de Promises (por ejemplo, para usar `switchMap` y cancelar peticiones anteriores), `@ngrx/signals/rxjs-interop` provee `rxMethod`:

```typescript
withMethods((store, productosService = inject(ProductosService)) => ({
  // rxMethod crea un método que acepta Signal, Observable o valor directo
  cargarProductosRx: rxMethod<void>(
    pipe(
      tap(() => patchState(store, { cargando: true, error: null })),
      switchMap(() =>
        productosService.obtenerTodos$().pipe(
          tapResponse({
            next: (productos) =>
              patchState(store, { productos, cargando: false }),
            error: (err: Error) =>
              patchState(store, { error: err.message, cargando: false }),
          })
        )
      )
    )
  ),
})),
```

`rxMethod` acepta un operador de RxJS y lo envuelve en un método que puede recibir un valor directo, un Signal, o un Observable. Si le pasamos un Signal, se subscribirá automáticamente y re-ejecutará el flujo cada vez que el Signal cambie.

---

## El ProductosStore completo ensamblado

```typescript
export const ProductosStore = signalStore(
  { providedIn: 'root' },
  withState(estadoInicial),
  withComputed(({ productos, terminoBusqueda, productoSeleccionadoId }) => ({
    productosFiltrados: computed(() => {
      const termino = terminoBusqueda().toLowerCase().trim();
      if (!termino) return productos();
      return productos().filter((p) =>
        p.nombre.toLowerCase().includes(termino)
      );
    }),
    totalProductos: computed(() => productos().length),
    productoSeleccionado: computed(() => {
      const id = productoSeleccionadoId();
      return id ? (productos().find((p) => p.id === id) ?? null) : null;
    }),
    hayProductos: computed(() => productos().length > 0),
  })),
  withMethods((store, productosService = inject(ProductosService)) => ({
    seleccionarProducto: (id: string) =>
      patchState(store, { productoSeleccionadoId: id }),
    buscar: (termino: string) =>
      patchState(store, { terminoBusqueda: termino }),
    cargarProductos: rxMethod<void>(
      pipe(
        tap(() => patchState(store, { cargando: true, error: null })),
        switchMap(() =>
          productosService.obtenerTodos$().pipe(
            tapResponse({
              next: (productos) =>
                patchState(store, { productos, cargando: false }),
              error: (err: Error) =>
                patchState(store, { error: err.message, cargando: false }),
            })
          )
        )
      )
    ),
  }))
);
```

---

## Consumiendo el store en componentes

```typescript
// src/app/productos/componentes/catalogo.component.ts
import { Component, inject, OnInit } from '@angular/core';
import { ProductosStore } from '../productos.store';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-catalogo',
  standalone: true,
  imports: [FormsModule],
  template: `
    <div>
      <p>{{ store.totalProductos() }} productos encontrados</p>
      <input
        type="text"
        placeholder="Buscar..."
        [ngModel]="store.terminoBusqueda()"
        (ngModelChange)="store.buscar($event)"
      />
      @for (producto of store.productosFiltrados(); track producto.id) {
        <div (click)="store.seleccionarProducto(producto.id)">
          <strong>{{ producto.nombre }}</strong>
          <span>${{ producto.precio }}</span>
        </div>
      }
      @if (store.productoSeleccionado(); as seleccionado) {
        <aside>
          <h2>{{ seleccionado.nombre }}</h2>
          <p>Precio: ${{ seleccionado.precio }}</p>
          <p>Stock: {{ seleccionado.stock }}</p>
        </aside>
      }
    </div>
  `,
})
export class CatalogoComponent implements OnInit {
  readonly store = inject(ProductosStore);

  ngOnInit(): void {
    this.store.cargarProductos();
  }
}
```

Sin `async pipe`, sin `| async`, sin subscripciones manuales. Los Signals se leen directamente en el template con `()`. Angular gestiona la detección de cambios de forma granular y eficiente.

---

## Diagrama del flujo de datos

```mermaid
flowchart TD
    A[Componente llama store.cargarProductos()] --> B[rxMethod recibe el trigger]
    B --> C[tap: patchState cargando=true]
    C --> D[switchMap llama al servicio HTTP]
    D --> E{¿Respuesta?}
    E -->|Éxito| F[patchState productos=data, cargando=false]
    E -->|Error| G[patchState error=msg, cargando=false]
    F --> H[Signal productos actualizado]
    H --> I[computed productosFiltrados recalcula]
    I --> J[Componente re-renderiza automáticamente]
```

---

## Puntos clave

- `withState(estadoInicial)` convierte cada propiedad del estado en un Signal de solo lectura accesible como `store.propiedad()`.
- `withComputed` acepta los Signals del estado como argumentos y devuelve nuevos Signals derivados con `computed()` de Angular.
- `withMethods` es donde viven las mutaciones: usa `patchState(store, cambios)` con un objeto parcial o con una función que recibe el estado actual.
- La inyección de dependencias en `withMethods` se hace con `inject()` como segundo parámetro de la función callback.
- `rxMethod` de `@ngrx/signals/rxjs-interop` permite usar operadores RxJS para flujos asincrónicos con cancelación automática.

## ¿Qué sigue?

En la siguiente parte veremos `withHooks` para reaccionar al ciclo de vida del store, y cómo crear store features reutilizables que encapsulan comportamientos transversales como el manejo de estado de carga.
