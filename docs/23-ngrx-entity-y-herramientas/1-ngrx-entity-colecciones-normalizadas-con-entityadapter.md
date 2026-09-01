# Capítulo 23 - Parte 1: NgRx Entity: colecciones normalizadas con EntityAdapter

> **Parte 1 de 4** · Capítulo 23 · PARTE XI - Gestión de Estado con NgRx

---

## El problema del estado no normalizado

Cuando empezamos a trabajar con NgRx, el instinto natural es almacenar colecciones como arrays de objetos. Tiene sentido intuitivo: recibimos un array del servidor, lo guardamos tal cual. Sin embargo, este enfoque esconde un problema de rendimiento que se hace visible a medida que la colección crece.

Imaginemos un estado inicial para una tienda de productos:

```typescript
// Enfoque ingenuo: array plano
interface ProductosState {
  productos: Producto[];
  cargando: boolean;
  error: string | null;
}

const estadoInicial: ProductosState = {
  productos: [],
  cargando: false,
  error: null,
};
```

Ahora, cada vez que queremos actualizar un solo producto, necesitamos recorrer todo el array para encontrarlo:

```typescript
// Reducer con búsqueda O(n) - problemático con colecciones grandes
on(ProductosActions.actualizarProductoExito, (estado, { producto }) => ({
  ...estado,
  productos: estado.productos.map((p) =>
    p.id === producto.id ? { ...p, ...producto } : p
  ),
})),
```

Esta operación `.map()` itera cada elemento aunque solo necesitemos tocar uno. Con 10 productos no se nota. Con 10.000 productos, la interfaz empieza a sentirse lenta. El problema real es la estructura de datos: los arrays son eficientes para iterar, no para buscar por clave.

La solución clásica en bases de datos es la normalización: separar los IDs de los datos y usar un mapa clave-valor para acceso O(1).

---

## EntityState: la estructura normalizada de NgRx

`@ngrx/entity` nos provee exactamente esta estructura. Un `EntityState<T>` tiene solo dos propiedades:

```typescript
interface EntityState<T> {
  ids: string[] | number[]; // orden de los elementos
  entities: { [id: string]: T }; // mapa para acceso O(1)
}
```

`ids` mantiene el orden (esencial para listas ordenadas), mientras que `entities` permite buscar cualquier elemento por su clave en tiempo constante. Para nuestro caso de productos:

```typescript
// src/app/productos/estado/productos.state.ts
import { EntityState } from '@ngrx/entity';

export interface Producto {
  id: string;
  nombre: string;
  precio: number;
  categoria: string;
  stock: number;
}

export interface ProductosState extends EntityState<Producto> {
  cargando: boolean;
  error: string | null;
  productoSeleccionadoId: string | null;
}
```

Nuestro estado ahora extiende `EntityState<Producto>`, heredando `ids` y `entities`, y le agregamos propiedades adicionales propias del dominio.

---

## Creando el EntityAdapter

El `EntityAdapter` es la pieza central de `@ngrx/entity`. Es un objeto con métodos para manipular el estado de forma inmutable, y también genera los selectores básicos automáticamente.

```typescript
// src/app/productos/estado/productos.reducer.ts
import { createEntityAdapter, EntityAdapter } from '@ngrx/entity';
import { createFeature, createReducer, on } from '@ngrx/store';
import { Producto, ProductosState } from './productos.state';
import { ProductosActions } from './productos.actions';

export const adaptadorProductos: EntityAdapter<Producto> =
  createEntityAdapter<Producto>({
    selectId: (producto) => producto.id,
    sortComparer: (a, b) => a.nombre.localeCompare(b.nombre),
  });
```

Los dos parámetros de configuración son opcionales pero importantes:

- **`selectId`**: le dice al adapter cuál propiedad usar como clave única. Si la propiedad se llama `id`, es el valor por defecto y podemos omitirlo.
- **`sortComparer`**: una función comparadora para mantener el array `ids` ordenado automáticamente. Si lo omitimos, el orden de inserción se preserva tal cual.

---

## Operaciones del adapter en el reducer

El adapter nos provee métodos que reemplazan las manipulaciones manuales del array. Veamos el reducer completo:

```typescript
const estadoInicial: ProductosState = adaptadorProductos.getInitialState({
  cargando: false,
  error: null,
  productoSeleccionadoId: null,
});

export const productosFeature = createFeature({
  name: 'productos',
  reducer: createReducer(
    estadoInicial,

    on(ProductosActions.cargarProductos, (estado) => ({
      ...estado,
      cargando: true,
      error: null,
    })),

    on(ProductosActions.cargarProductosExito, (estado, { productos }) =>
      adaptadorProductos.setAll(productos, { ...estado, cargando: false })
    ),

    on(ProductosActions.cargarProductosError, (estado, { error }) => ({
      ...estado,
      cargando: false,
      error,
    })),

    on(ProductosActions.agregarProductoExito, (estado, { producto }) =>
      adaptadorProductos.addOne(producto, estado)
    ),

    on(ProductosActions.actualizarProductoExito, (estado, { cambios, id }) =>
      adaptadorProductos.updateOne({ id, changes: cambios }, estado)
    ),

    on(ProductosActions.upsertProducto, (estado, { producto }) =>
      adaptadorProductos.upsertOne(producto, estado)
    ),

    on(ProductosActions.eliminarProductoExito, (estado, { id }) =>
      adaptadorProductos.removeOne(id, estado)
    ),

    on(ProductosActions.seleccionarProducto, (estado, { id }) => ({
      ...estado,
      productoSeleccionadoId: id,
    }))
  ),
});
```

Cada método del adapter toma el estado actual como segundo argumento y devuelve un nuevo estado inmutable. No hay `.map()`, no hay `.filter()`, no hay búsquedas manuales.

---

## Catálogo de operaciones del adapter

Veamos el mapa completo de operaciones disponibles:

```typescript
// Reemplazar toda la colección
adaptadorProductos.setAll(productos, estado);

// Agregar sin duplicar (ignora si ya existe)
adaptadorProductos.addOne(producto, estado);
adaptadorProductos.addMany(productos, estado);

// Insertar o actualizar (upsert)
adaptadorProductos.upsertOne(producto, estado);
adaptadorProductos.upsertMany(productos, estado);

// Actualizar solo campos específicos (requiere id + changes)
adaptadorProductos.updateOne({ id, changes: camposParciales }, estado);
adaptadorProductos.updateMany([{ id, changes }], estado);

// Eliminar
adaptadorProductos.removeOne(id, estado);
adaptadorProductos.removeMany(ids, estado);
adaptadorProductos.removeAll(estado);

// Establecer exactamente un conjunto (como setAll pero para un subconjunto)
adaptadorProductos.setMany(productos, estado);
adaptadorProductos.setOne(producto, estado);
```

La diferencia clave entre `addOne` y `upsertOne`: `addOne` ignora el elemento si ya existe con ese ID, mientras que `upsertOne` lo reemplaza completamente.

---

## Selectores generados automáticamente

`createFeature` combinado con el adapter nos da selectores listos para usar:

```typescript
// src/app/productos/estado/productos.selectors.ts
import { productosFeature } from './productos.reducer';

// Selectores de la feature (generados por createFeature)
export const {
  selectProductosState,
  selectCargando,
  selectError,
  selectProductoSeleccionadoId,
} = productosFeature;

// Selectores del adapter (para navegar la estructura normalizada)
export const {
  selectAll: selectTodosLosProductos,
  selectEntities: selectEntidadesProductos,
  selectIds: selectIdsProductos,
  selectTotal: selectTotalProductos,
} = adaptadorProductos.getSelectors(productosFeature.selectProductosState);
```

`selectAll` devuelve un `Producto[]` ordenado según el `sortComparer` configurado. `selectEntities` devuelve el mapa `{ [id]: Producto }`, ideal para buscar por ID en O(1) desde otros selectores.

Podemos componer selectores derivados sobre estos:

```typescript
import { createSelector } from '@ngrx/store';

export const selectProductoActual = createSelector(
  selectEntidadesProductos,
  selectProductoSeleccionadoId,
  (entidades, idSeleccionado) =>
    idSeleccionado ? (entidades[idSeleccionado] ?? null) : null
);

export const selectProductosPorCategoria = (categoria: string) =>
  createSelector(selectTodosLosProductos, (productos) =>
    productos.filter((p) => p.categoria === categoria)
  );
```

---

## Usando la feature en el componente

```typescript
// src/app/productos/componentes/lista-productos.component.ts
import { Component, inject, OnInit } from '@angular/core';
import { Store } from '@ngrx/store';
import { AsyncPipe } from '@angular/common';
import { ProductosActions } from '../estado/productos.actions';
import {
  selectTodosLosProductos,
  selectCargando,
  selectTotalProductos,
} from '../estado/productos.selectors';

@Component({
  selector: 'app-lista-productos',
  standalone: true,
  imports: [AsyncPipe],
  template: `
    <p>Total: {{ total$ | async }} productos</p>
    @if (cargando$ | async) {
      <p>Cargando...</p>
    }
    @for (producto of productos$ | async; track producto.id) {
      <div>{{ producto.nombre }} - ${{ producto.precio }}</div>
    }
  `,
})
export class ListaProductosComponent implements OnInit {
  private readonly store = inject(Store);

  readonly productos$ = this.store.select(selectTodosLosProductos);
  readonly cargando$ = this.store.select(selectCargando);
  readonly total$ = this.store.select(selectTotalProductos);

  ngOnInit(): void {
    this.store.dispatch(ProductosActions.cargarProductos());
  }
}
```

---

## Diagrama del flujo de datos con Entity

```mermaid
flowchart TD
    A[Componente dispara acción] --> B[Reducer con adapter]
    B --> C{Operación adapter}
    C -->|setAll| D[Reemplaza toda la colección]
    C -->|addOne / upsertOne| E[Agrega o actualiza uno]
    C -->|updateOne| F[Actualiza campos parciales]
    C -->|removeOne| G[Elimina por ID]
    D & E & F & G --> H[Nuevo EntityState]
    H --> I[ids: string[]]
    H --> J["entities: Record<id, T>"]
    I & J --> K[selectAll → T[]]
    I & J --> L["selectEntities → Record<id, T>"]
    K & L --> M[Componente re-renderiza]
```

---

## Puntos clave

- `EntityState<T>` separa `ids[]` (orden) de `entities{}` (acceso O(1)), eliminando búsquedas lentas en arrays.
- `createEntityAdapter` acepta `selectId` para claves personalizadas y `sortComparer` para orden automático.
- Las operaciones del adapter (`setAll`, `addOne`, `updateOne`, `upsertOne`, `removeOne`) garantizan inmutabilidad sin código manual.
- `getSelectors()` genera `selectAll`, `selectEntities`, `selectIds` y `selectTotal` listos para componer selectores derivados.
- `adaptadorProductos.getInitialState({ ...extraProps })` combina el estado de Entity con propiedades propias del dominio.

## ¿Qué sigue?

En la siguiente parte veremos cómo sincronizar el Router de Angular con el Store usando `@ngrx/router-store`, permitiendo que nuestros effects reaccionen a cambios de URL sin tocar `ActivatedRoute`.
