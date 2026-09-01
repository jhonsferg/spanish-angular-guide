# Capítulo 18 - Parte 1: Patrones reactivos en servicios Angular: estado con BehaviorSubject

> **Parte 1 de 4** · Capítulo 18 · PARTE IX - Programación Reactiva con RxJS

Uno de los patrones más poderosos y subutilizados en Angular es el "state service" reactivo: un servicio que centraliza el estado de una funcionalidad usando `BehaviorSubject` como fuente de verdad. Este patrón es el puente entre RxJS puro y soluciones de gestión de estado como NgRx, y en muchos proyectos medianos es todo lo que necesitamos. Construiremos uno desde cero.

## ¿Por qué BehaviorSubject?

`BehaviorSubject` es un tipo especial de `Subject` con dos características únicas:

1. **Recuerda el último valor emitido**: cualquier nuevo suscriptor recibe inmediatamente el valor actual al suscribirse.
2. **Requiere un valor inicial**: siempre tiene un valor, incluso antes de que nadie haya emitido nada.

Estas características lo convierten en la elección perfecta para representar estado. Cuando un componente se inicializa y se suscribe al estado, quiere saber el valor actual de inmediato, no esperar a la próxima emisión.

```typescript
import { BehaviorSubject, Subject, ReplaySubject } from 'rxjs';

// Subject: no recuerda nada, solo emite a suscriptores actuales
const subject$ = new Subject<number>();
subject$.next(1);
subject$.subscribe(v => console.log(v)); // No imprime nada (perdió el 1)

// BehaviorSubject: recuerda el último valor
const behavior$ = new BehaviorSubject<number>(0);
behavior$.next(1);
behavior$.subscribe(v => console.log(v)); // Imprime 1 inmediatamente

// ReplaySubject: recuerda los últimos N valores
const replay$ = new ReplaySubject<number>(3);
replay$.next(1); replay$.next(2); replay$.next(3);
replay$.subscribe(v => console.log(v)); // Imprime 1, 2, 3
```

## El patrón: encapsular con asObservable()

Un error común es exponer el `BehaviorSubject` directamente desde el servicio. Esto permite que cualquier componente emita valores directamente, rompiendo el flujo unidireccional de datos. La solución es exponer solo el Observable:

```typescript
import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';

interface EstadoUsuario {
  nombre: string;
  autenticado: boolean;
  cargando: boolean;
}

const estadoInicial: EstadoUsuario = {
  nombre: '',
  autenticado: false,
  cargando: false
};

@Injectable({ providedIn: 'root' })
export class UsuarioService {
  // Privado: solo este servicio puede emitir
  private estado$ = new BehaviorSubject<EstadoUsuario>(estadoInicial);

  // Público: solo lectura para el exterior
  readonly estadoUsuario$: Observable<EstadoUsuario> = this.estado$.asObservable();

  actualizarNombre(nombre: string): void {
    this.estado$.next({ ...this.estado$.getValue(), nombre });
  }

  establecerAutenticacion(autenticado: boolean): void {
    this.estado$.next({ ...this.estado$.getValue(), autenticado });
  }
}
```

`asObservable()` envuelve el `BehaviorSubject` en un Observable puro. Un componente puede suscribirse pero no puede llamar `.next()` sobre él. Esto es encapsulamiento reactivo.

## CarritoService: estado CRUD reactivo completo

Construyamos un servicio de carrito de compras que demuestre las operaciones básicas de estado:

```typescript
import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { map, shareReplay } from 'rxjs/operators';

export interface ItemCarrito {
  id: string;
  nombre: string;
  precio: number;
  cantidad: number;
}

interface EstadoCarrito {
  items: ItemCarrito[];
  cargando: boolean;
  error: string | null;
}

const estadoInicial: EstadoCarrito = {
  items: [],
  cargando: false,
  error: null
};

@Injectable({ providedIn: 'root' })
export class CarritoService {
  private estado$ = new BehaviorSubject<EstadoCarrito>(estadoInicial);

  // Selectores: estado derivado
  readonly items$: Observable<ItemCarrito[]> = this.estado$.pipe(
    map(estado => estado.items),
    shareReplay(1)
  );

  readonly totalItems$: Observable<number> = this.items$.pipe(
    map(items => items.reduce((total, item) => total + item.cantidad, 0)),
    shareReplay(1)
  );

  readonly totalPrecio$: Observable<number> = this.items$.pipe(
    map(items =>
      items.reduce((total, item) => total + item.precio * item.cantidad, 0)
    ),
    shareReplay(1)
  );

  readonly estaVacio$: Observable<boolean> = this.totalItems$.pipe(
    map(total => total === 0)
  );

  agregarItem(nuevoItem: Omit<ItemCarrito, 'cantidad'>): void {
    const estadoActual = this.estado$.getValue();
    const itemExistente = estadoActual.items.find(i => i.id === nuevoItem.id);

    const itemsActualizados = itemExistente
      ? estadoActual.items.map(item =>
          item.id === nuevoItem.id
            ? { ...item, cantidad: item.cantidad + 1 }
            : item
        )
      : [...estadoActual.items, { ...nuevoItem, cantidad: 1 }];

    this.estado$.next({ ...estadoActual, items: itemsActualizados });
  }

  quitarItem(itemId: string): void {
    const estadoActual = this.estado$.getValue();
    this.estado$.next({
      ...estadoActual,
      items: estadoActual.items.filter(item => item.id !== itemId)
    });
  }

  actualizarCantidad(itemId: string, cantidad: number): void {
    if (cantidad <= 0) {
      this.quitarItem(itemId);
      return;
    }
    const estadoActual = this.estado$.getValue();
    this.estado$.next({
      ...estadoActual,
      items: estadoActual.items.map(item =>
        item.id === itemId ? { ...item, cantidad } : item
      )
    });
  }

  vaciarCarrito(): void {
    this.estado$.next(estadoInicial);
  }
}
```

Cada método de mutación sigue el mismo patrón: leer el estado actual con `getValue()`, calcular el nuevo estado inmutablemente (usando el operador spread), y emitirlo con `next()`.

## shareReplay(1): caché para múltiples suscriptores

Veamos por qué usamos `shareReplay(1)` en los selectores. Sin él, cada componente que se suscriba a `totalItems$` ejecutaría el `map` independientemente. Con `shareReplay(1)`:

```typescript
import { interval } from 'rxjs';
import { map, shareReplay, tap } from 'rxjs/operators';

// Sin shareReplay: la función map se ejecuta por cada suscriptor
const sinCache$ = interval(1000).pipe(
  tap(() => console.log('Cálculo ejecutado')),
  map(n => n * 2)
);
sinCache$.subscribe(); // "Cálculo ejecutado" aparece
sinCache$.subscribe(); // "Cálculo ejecutado" aparece de nuevo (doble trabajo)

// Con shareReplay(1): se calcula una vez y se comparte
const conCache$ = interval(1000).pipe(
  tap(() => console.log('Cálculo ejecutado')),
  map(n => n * 2),
  shareReplay(1)
);
conCache$.subscribe(); // "Cálculo ejecutado" aparece UNA SOLA VEZ
conCache$.subscribe(); // Recibe el valor en caché, no ejecuta de nuevo
```

El `1` en `shareReplay(1)` indica cuántos valores se guardan en el buffer. Para estado, generalmente es `1` (el estado más reciente).

## Estado derivado combinando múltiples BehaviorSubjects

A veces el estado de un componente depende de múltiples fuentes. `combineLatest` nos permite derivar estado de varias fuentes reactivas:

```typescript
import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable, combineLatest } from 'rxjs';
import { map, shareReplay } from 'rxjs/operators';
import { CarritoService } from './carrito.service';

interface Descuento {
  codigo: string;
  porcentaje: number;
}

@Injectable({ providedIn: 'root' })
export class ResumenPagoService {
  private descuento$ = new BehaviorSubject<Descuento | null>(null);

  // Estado derivado de AMBOS servicios
  readonly resumen$: Observable<{ subtotal: number; descuento: number; total: number }>;

  constructor(private carritoService: CarritoService) {
    this.resumen$ = combineLatest([
      this.carritoService.totalPrecio$,
      this.descuento$
    ]).pipe(
      map(([subtotal, descuentoActivo]) => {
        const montoDescuento = descuentoActivo
          ? subtotal * (descuentoActivo.porcentaje / 100)
          : 0;
        return {
          subtotal,
          descuento: montoDescuento,
          total: subtotal - montoDescuento
        };
      }),
      shareReplay(1)
    );
  }

  aplicarDescuento(descuento: Descuento): void {
    this.descuento$.next(descuento);
  }

  quitarDescuento(): void {
    this.descuento$.next(null);
  }
}
```

Cada vez que cambia el carrito o el descuento, `resumen$` recalcula automáticamente. Los componentes que se suscriban siempre tendrán los datos actualizados sin lógica adicional.

## Usando el servicio en un componente

```typescript
import { Component } from '@angular/core';
import { AsyncPipe, CurrencyPipe, NgFor, NgIf } from '@angular/common';
import { CarritoService, ItemCarrito } from './carrito.service';

@Component({
  selector: 'app-carrito',
  standalone: true,
  imports: [AsyncPipe, CurrencyPipe, NgFor, NgIf],
  template: `
    <div *ngIf="carritoService.estaVacio$ | async">El carrito está vacío</div>
    <ul>
      <li *ngFor="let item of carritoService.items$ | async">
        {{ item.nombre }} x{{ item.cantidad }} -
        {{ item.precio * item.cantidad | currency:'COP' }}
        <button (click)="carritoService.quitarItem(item.id)">Quitar</button>
      </li>
    </ul>
    <strong>Total: {{ carritoService.totalPrecio$ | async | currency:'COP' }}</strong>
  `
})
export class CarritoComponent {
  constructor(readonly carritoService: CarritoService) {}
}
```

El componente no tiene lógica de negocio ni variables de estado propias. Todo viene del servicio reactivo, y el `async pipe` gestiona automáticamente las suscripciones y la detección de cambios.

## Puntos clave

- `BehaviorSubject` es el núcleo del patrón "state service": recuerda el último valor y lo entrega a nuevos suscriptores de inmediato.
- `asObservable()` es fundamental para encapsular el Subject y garantizar que solo el servicio pueda emitir nuevos valores.
- Los selectores con `shareReplay(1)` evitan cálculos duplicados cuando múltiples componentes consumen el mismo estado derivado.
- El patrón de mutación con `getValue()` + spread + `next()` garantiza inmutabilidad y trazabilidad del estado.
- `combineLatest` permite derivar estado de múltiples fuentes de forma declarativa, sin suscripciones manuales.

## ¿Qué sigue?

En la siguiente parte abordaremos el problema de los memory leaks por suscripciones no canceladas y veremos `takeUntilDestroyed` de Angular 16+ como la solución moderna y elegante.
