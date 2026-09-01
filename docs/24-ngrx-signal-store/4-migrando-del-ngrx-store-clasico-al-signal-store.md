# Capítulo 24 - Parte 4: Migrando del NgRx Store clásico al Signal Store

> **Parte 4 de 4** · Capítulo 24 · PARTE XI - Gestión de Estado con NgRx

---

## El dilema de la migración

Cuando el Signal Store apareció, muchos equipos enfrentaron la misma pregunta: ¿migramos todo ahora o esperamos? La respuesta pragmática es ninguna de las dos. Migrar todo en un "big bang" es arriesgado y costoso. Esperar indefinidamente significa perderse los beneficios en código nuevo.

La estrategia correcta es la migración incremental: convivir con ambos paradigmas durante el tiempo que sea necesario, migrar feature por feature cuando tenga sentido, y nunca forzar una migración solo porque existe el nuevo enfoque.

En esta parte construimos el mapa mental para entender las equivalencias y tomamos decisiones informadas sobre qué migrar y qué dejar como está.

---

## Comparación conceptual lado a lado

Empecemos con el núcleo del cambio de paradigma. Tomemos la misma feature de notificaciones y la implementamos en ambos paradigmas:

**Store clásico - 5 archivos:**

```typescript
// notificaciones.actions.ts
import { createActionGroup, emptyProps, props } from '@ngrx/store';

export const NotificacionesActions = createActionGroup({
  source: 'Notificaciones',
  events: {
    'Agregar Notificacion': props<{ mensaje: string; tipo: 'exito' | 'error' }>(),
    'Eliminar Notificacion': props<{ id: string }>(),
    'Limpiar Todas': emptyProps(),
  },
});
```

```typescript
// notificaciones.reducer.ts
import { createFeature, createReducer, on } from '@ngrx/store';
import { NotificacionesActions } from './notificaciones.actions';

interface Notificacion { id: string; mensaje: string; tipo: 'exito' | 'error'; }
interface Estado { lista: Notificacion[]; }

const estadoInicial: Estado = { lista: [] };

export const notificacionesFeature = createFeature({
  name: 'notificaciones',
  reducer: createReducer(
    estadoInicial,
    on(NotificacionesActions.agregarNotificacion, (estado, { mensaje, tipo }) => ({
      lista: [...estado.lista, { id: crypto.randomUUID(), mensaje, tipo }],
    })),
    on(NotificacionesActions.eliminarNotificacion, (estado, { id }) => ({
      lista: estado.lista.filter((n) => n.id !== id),
    })),
    on(NotificacionesActions.limpiarTodas, () => estadoInicial),
  ),
});
```

```typescript
// notificaciones.selectors.ts
import { createSelector } from '@ngrx/store';
import { notificacionesFeature } from './notificaciones.reducer';

export const { selectLista: selectNotificaciones } = notificacionesFeature;

export const selectTieneNotificaciones = createSelector(
  selectNotificaciones,
  (lista) => lista.length > 0
);
```

**Signal Store - 1 archivo:**

```typescript
// notificaciones.store.ts
import { signalStore, withState, withComputed, withMethods, patchState } from '@ngrx/signals';
import { computed } from '@angular/core';

interface Notificacion { id: string; mensaje: string; tipo: 'exito' | 'error'; }

export const NotificacionesStore = signalStore(
  { providedIn: 'root' },
  withState({ lista: [] as Notificacion[] }),
  withComputed(({ lista }) => ({
    tieneNotificaciones: computed(() => lista().length > 0),
    totalNotificaciones: computed(() => lista().length),
  })),
  withMethods((store) => ({
    agregar(mensaje: string, tipo: 'exito' | 'error'): void {
      patchState(store, (estado) => ({
        lista: [...estado.lista, { id: crypto.randomUUID(), mensaje, tipo }],
      }));
    },
    eliminar(id: string): void {
      patchState(store, (estado) => ({
        lista: estado.lista.filter((n) => n.id !== id),
      }));
    },
    limpiarTodas(): void {
      patchState(store, { lista: [] });
    },
  }))
);
```

La reducción de boilerplate es evidente. Pero más importante que el número de líneas es la cohesión: toda la lógica de notificaciones vive en un solo lugar.

---

## Tabla de equivalencias

| Store Clásico | Signal Store | Notas |
|---|---|---|
| `createAction` / `createActionGroup` | Método en `withMethods` | Las acciones se reemplazan por métodos directos |
| `createReducer` + `on(action, ...)` | `patchState(store, ...)` | Sin intermediario de mensajes |
| `createSelector` | `computed(() => ...)` en `withComputed` | Misma reactividad, sintaxis Angular nativa |
| `createEffect` | Método async en `withMethods` o `withHooks` | Los efectos son métodos o hooks del store |
| `store.dispatch(accion())` | `store.metodo()` | Llamada directa sin dispatch |
| `store.select(selector)` | `store.propiedad()` o `store.computed()` | Signal directo, sin Observable |
| `AsyncPipe` en template | `store.propiedad()` directo | Signals no necesitan async pipe |
| `provideMockStore` en tests | `TestBed` con store real o mock de clase | El testing cambia de paradigma |

---

## Estrategia de migración incremental

El enfoque probado es migrar una feature a la vez, sin tocar el resto de la aplicación. El store clásico y el Signal Store coexisten perfectamente porque ambos son servicios de inyección de dependencias de Angular:

```mermaid
flowchart LR
    subgraph Fase 1 - Coexistencia
        C1[Auth Store\nStore Clásico]
        C2[Productos Store\nStore Clásico]
        C3[UI Store\nStore Clásico]
    end

    subgraph Fase 2 - Migración gradual
        D1[Auth Store\nStore Clásico]
        D2[Productos Store\nSignal Store]
        D3[UI Store\nSignal Store]
    end

    subgraph Fase 3 - Estado objetivo
        E1[Auth Store\nStore Clásico]
        E2[Productos Store\nSignal Store]
        E3[UI Store\nSignal Store]
    end

    Fase 1 --> Fase 2 --> Fase 3
```

El paso a paso para migrar una feature específica:

**1. Crear el Signal Store en paralelo** sin eliminar el store clásico:

```typescript
// productos.store.ts (nuevo) - coexiste con el reducer/actions existente
export const ProductosStore = signalStore(
  withState(estadoInicial),
  withMethods(/* ... */)
);
```

**2. Migrar los componentes de la feature** para usar el nuevo store en lugar del clásico:

```typescript
// Antes
export class ListaProductosComponent {
  private store = inject(Store);
  productos$ = this.store.select(selectTodosLosProductos);
}

// Después
export class ListaProductosComponent {
  readonly store = inject(ProductosStore);
  // store.productos() en lugar de productos$ | async
}
```

**3. Verificar que ningún otro componente fuera de la feature** usa los selectores o actions del store clásico de esa feature.

**4. Eliminar el código del store clásico** (reducer, actions, selectors, effects) para la feature migrada.

---

## Cuándo mantener el store clásico

Hay escenarios donde el store clásico no solo es válido, sino preferible:

**Estado genuinamente global entre features no relacionadas**: si el estado de autenticación afecta a la feature de productos, la de pedidos, la de usuarios y la de configuración, el store clásico con sus acciones globales es más apropiado. Una acción `[Auth] Sesión Expirada` puede ser escuchada por múltiples effects de distintas features. En el Signal Store, tendríamos que llamar manualmente a cada store afectado.

**Auditoría y DevTools avanzados**: si el negocio requiere un log completo de todas las operaciones del usuario (para auditoría, para soporte, para análisis), el historial de acciones del store clásico con Redux DevTools es insustituible. Las mutaciones del Signal Store no aparecen en el historial de DevTools de la misma manera.

**Equipos con testing establecido con `MockStore`**: si el equipo tiene cientos de tests que usan `MockStore` y `overrideSelector`, la migración al Signal Store implica reescribir esos tests. El costo puede no justificarse.

**Código que depende de `@ngrx/effects` para lógica compleja**: flujos con múltiples acciones encadenadas, debounce, retry, y condiciones de carrera son naturalmente expresivos con RxJS en effects. En el Signal Store son posibles con `rxMethod`, pero pueden resultar más verbosos.

---

## Cuándo preferir el Signal Store

**Estado de feature o de componente**: si el estado solo importa dentro de una feature, el Signal Store es la elección natural. No contamina el store global, se destruye con la feature, y es más fácil de razonar.

**Equipos que priorizan la legibilidad**: el Signal Store es más intuitivo para desarrolladores que vienen de React (Zustand, Jotai) o que no tienen experiencia previa con Redux. La curva de aprendizaje es significativamente menor.

**Features nuevas en aplicaciones existentes**: al agregar funcionalidades nuevas a una aplicación con store clásico, usar Signal Store para las features nuevas es una estrategia de modernización incremental sin riesgo.

**Estado de formularios complejos**: manejar el estado de un wizard multi-paso o un formulario con lógica condicional compleja con el Signal Store resulta natural. Un Signal Store provisto en el componente raíz del wizard gestiona toda la lógica, se destruye al terminar, y no deja rastros en el store global.

---

## Conectando el Signal Store con el store clásico

Cuando necesitamos que un Signal Store reaccione a acciones del store clásico (durante la migración), podemos crear un puente:

```typescript
// src/app/notificaciones/notificaciones.store.ts
import { withHooks } from '@ngrx/signals';
import { rxMethod } from '@ngrx/signals/rxjs-interop';
import { Store, ActionsSubject } from '@ngrx/store';
import { ofType } from '@ngrx/effects';
import { pipe, tap } from 'rxjs';
import { AuthActions } from '../auth/estado/auth.actions';

export const NotificacionesStore = signalStore(
  { providedIn: 'root' },
  withState({ lista: [] as Notificacion[] }),
  withMethods((store, accionesSubject = inject(ActionsSubject)) => ({
    escucharAccionesGlobales: rxMethod<void>(
      pipe(
        switchMap(() =>
          accionesSubject.pipe(
            ofType(AuthActions.sesionExpirada),
            tap(() => store.agregar('Tu sesión ha expirado', 'error'))
          )
        )
      )
    ),
    agregar(mensaje: string, tipo: 'exito' | 'error'): void {
      patchState(store, (estado) => ({
        lista: [...estado.lista, { id: crypto.randomUUID(), mensaje, tipo }],
      }));
    },
  })),
  withHooks({ onInit: (store) => store.escucharAccionesGlobales() })
);
```

`ActionsSubject` es el Observable interno del store clásico que emite cada acción despachada. Al inyectarlo en un Signal Store, podemos crear un puente entre ambos paradigmas durante la transición.

---

## Puntos clave

- La migración incremental feature por feature es la estrategia más segura: ambos paradigmas coexisten sin conflicto en la misma aplicación.
- Las equivalencias fundamentales son: action → método, reducer → `patchState`, selector → `computed`, effect → método async o `withHooks`, dispatch → llamada directa.
- El store clásico sigue siendo la mejor opción para estado global compartido entre features no relacionadas, auditoría de acciones, y equipos con testing establecido con `MockStore`.
- El Signal Store es ideal para estado de feature o componente, equipos que priorizan legibilidad, y features nuevas en aplicaciones existentes.
- `ActionsSubject` permite que un Signal Store escuche acciones del store clásico durante períodos de transición, creando un puente entre paradigmas.

## ¿Qué sigue?

Con esto completamos la Parte XI sobre gestión de estado con NgRx. En el siguiente capítulo nos adentramos en las estrategias de rendimiento avanzadas de Angular: `OnPush`, Signals, virtual scrolling y optimización de bundle con lazy loading granular.
