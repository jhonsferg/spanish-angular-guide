# Capítulo 18 - Parte 3: Operadores de acumulación: scan, reduce, buffer, window

> **Parte 3 de 4** · Capítulo 18 · PARTE IX - Programación Reactiva con RxJS

Los operadores que veremos en esta parte nos permiten trabajar con el tiempo y la historia de un stream. En lugar de procesar cada valor de forma aislada, los operadores de acumulación construyen algo nuevo a partir de todos los valores anteriores, o los agrupan antes de procesarlos. Son fundamentales para construir estado en tiempo real y para procesar streams de alta frecuencia de forma eficiente.

## scan: el estado acumulativo en tiempo real

`scan` es el operador más importante de esta categoría. Funciona exactamente como `Array.prototype.reduce`, pero en lugar de esperar a que el array termine, emite el acumulador tras **cada emisión**. Es decir, vemos la evolución del estado en tiempo real.

La firma es `scan(acumulador: (estado, valor) => nuevoEstado, semilla)`.

```typescript
import { Component, OnInit } from '@angular/core';
import { Subject, Observable } from 'rxjs';
import { scan, map } from 'rxjs/operators';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';

interface EstadoContador {
  valor: number;
  historial: number[];
  maximo: number;
}

@Component({
  selector: 'app-contador-avanzado',
  template: `
    <button (click)="incrementar()">+</button>
    <button (click)="decrementar()">-</button>
    <button (click)="reiniciar()">Reset</button>
    <p>Valor: {{ estado?.valor }}</p>
    <p>Máximo alcanzado: {{ estado?.maximo }}</p>
  `
})
export class ContadorAvanzadoComponent implements OnInit {
  private acciones$ = new Subject<number>();
  estado: EstadoContador = { valor: 0, historial: [], maximo: 0 };
  private destroy = takeUntilDestroyed();

  ngOnInit(): void {
    this.acciones$.pipe(
      scan((estadoActual, delta) => {
        const nuevoValor = estadoActual.valor + delta;
        return {
          valor: nuevoValor,
          historial: [...estadoActual.historial, nuevoValor],
          maximo: Math.max(estadoActual.maximo, nuevoValor)
        };
      }, { valor: 0, historial: [], maximo: 0 } as EstadoContador),
      this.destroy
    ).subscribe(nuevoEstado => {
      this.estado = nuevoEstado;
    });
  }

  incrementar(): void { this.acciones$.next(1); }
  decrementar(): void { this.acciones$.next(-1); }
  reiniciar(): void { this.acciones$.next(-this.estado.valor); }
}
```

La clave de `scan` es que el estado es **inmutable**: nunca mutamos `estadoActual`, siempre retornamos un nuevo objeto. Esto hace el código predecible y facilita el debugging.

## Carrito de compras reactivo con scan

Veamos cómo `scan` puede ser el motor de un carrito de compras completo, procesando diferentes tipos de acciones:

```typescript
import { Injectable } from '@angular/core';
import { Subject, Observable } from 'rxjs';
import { scan, map, shareReplay } from 'rxjs/operators';

type AccionCarrito =
  | { tipo: 'AGREGAR'; productoId: string; nombre: string; precio: number }
  | { tipo: 'QUITAR'; productoId: string }
  | { tipo: 'ACTUALIZAR_CANTIDAD'; productoId: string; cantidad: number }
  | { tipo: 'VACIAR' };

interface ItemCarrito {
  productoId: string;
  nombre: string;
  precio: number;
  cantidad: number;
}

function reducirCarrito(items: ItemCarrito[], accion: AccionCarrito): ItemCarrito[] {
  switch (accion.tipo) {
    case 'AGREGAR': {
      const existente = items.find(i => i.productoId === accion.productoId);
      return existente
        ? items.map(i => i.productoId === accion.productoId
            ? { ...i, cantidad: i.cantidad + 1 } : i)
        : [...items, { productoId: accion.productoId, nombre: accion.nombre,
            precio: accion.precio, cantidad: 1 }];
    }
    case 'QUITAR':
      return items.filter(i => i.productoId !== accion.productoId);
    case 'ACTUALIZAR_CANTIDAD':
      return accion.cantidad <= 0
        ? items.filter(i => i.productoId !== accion.productoId)
        : items.map(i => i.productoId === accion.productoId
            ? { ...i, cantidad: accion.cantidad } : i);
    case 'VACIAR':
      return [];
  }
}

@Injectable({ providedIn: 'root' })
export class CarritoReactivoService {
  private acciones$ = new Subject<AccionCarrito>();

  readonly items$: Observable<ItemCarrito[]> = this.acciones$.pipe(
    scan(reducirCarrito, [] as ItemCarrito[]),
    shareReplay(1)
  );

  readonly total$: Observable<number> = this.items$.pipe(
    map(items => items.reduce((t, i) => t + i.precio * i.cantidad, 0))
  );

  despachar(accion: AccionCarrito): void {
    this.acciones$.next(accion);
  }
}
```

Este patrón es esencialmente un mini-NgRx implementado en 50 líneas. La función `reducirCarrito` es un reductor puro, perfectamente testeable de forma unitaria sin ninguna dependencia de RxJS.

## reduce: acumulación al completar

`reduce` funciona exactamente igual que `scan`, pero **no emite valores intermedios**: espera a que el Observable fuente complete y solo entonces emite el valor acumulado final.

```typescript
import { from } from 'rxjs';
import { reduce, scan } from 'rxjs/operators';

const numeros$ = from([1, 2, 3, 4, 5]);

// scan emite: 1, 3, 6, 10, 15 (acumulado tras cada valor)
numeros$.pipe(
  scan((acc, valor) => acc + valor, 0)
).subscribe(v => console.log('scan:', v));

// reduce emite: solo 15 (al completar el Observable)
numeros$.pipe(
  reduce((acc, valor) => acc + valor, 0)
).subscribe(v => console.log('reduce:', v));
```

`reduce` es ideal para calcular estadísticas sobre un conjunto finito de datos, pero en streams infinitos (como eventos del usuario) es prácticamente inútil porque nunca emite. En esos casos, siempre queremos `scan`.

## buffer: agrupar emisiones en arrays

`buffer(closingNotifier$)` acumula los valores del Observable fuente en un array y lo emite cuando el `closingNotifier$` emite. Luego comienza un nuevo buffer.

```typescript
import { Component, OnInit } from '@angular/core';
import { fromEvent, interval, Observable } from 'rxjs';
import { buffer, filter, map } from 'rxjs/operators';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';

@Component({
  selector: 'app-detector-doble-clic',
  template: `
    <button id="btn-principal">Haz clic (detectamos doble clic)</button>
    <p>Dobles clics: {{ contadorDoblesClic }}</p>
  `
})
export class DetectorDobleClicComponent implements OnInit {
  contadorDoblesClic = 0;
  private destroy = takeUntilDestroyed();

  ngOnInit(): void {
    const boton = document.getElementById('btn-principal')!;
    const clics$ = fromEvent(boton, 'click');
    const ventana$ = interval(300); // Cierra el buffer cada 300ms

    clics$.pipe(
      buffer(ventana$),
      filter(clicsEnVentana => clicsEnVentana.length >= 2),
      this.destroy
    ).subscribe(() => {
      this.contadorDoblesClic++;
      console.log('¡Doble clic detectado!');
    });
  }
}
```

## bufferTime: agrupar por tiempo

`bufferTime(ms)` es un atajo para `buffer(interval(ms))`. Agrupa todo lo que llega en el intervalo dado y emite el array, incluso si está vacío.

```typescript
import { Injectable } from '@angular/core';
import { Subject, Observable } from 'rxjs';
import { bufferTime, filter, switchMap } from 'rxjs/operators';
import { HttpClient } from '@angular/common/http';

interface EventoAnalytics {
  tipo: string;
  pagina: string;
  timestamp: number;
}

@Injectable({ providedIn: 'root' })
export class AnalyticsService {
  private eventos$ = new Subject<EventoAnalytics>();

  constructor(private http: HttpClient) {
    // Acumular eventos por 5 segundos y enviarlos en lote
    this.eventos$.pipe(
      bufferTime(5000),
      filter(lote => lote.length > 0),
      switchMap(lote =>
        this.http.post<void>('/api/analytics/batch', { eventos: lote })
      )
    ).subscribe();
  }

  registrar(tipo: string, pagina: string): void {
    this.eventos$.next({ tipo, pagina, timestamp: Date.now() });
  }
}
```

Este patrón es muy común para analytics: en lugar de hacer una petición HTTP por cada evento (que podría ser cientos por minuto), agrupamos y enviamos en lotes, reduciendo drásticamente la cantidad de peticiones.

## bufferCount: agrupar por cantidad

`bufferCount(n, salto?)` agrupa exactamente `n` valores y emite el array. Con el segundo parámetro `salto`, podemos crear ventanas deslizantes.

```typescript
import { from } from 'rxjs';
import { bufferCount } from 'rxjs/operators';

// Agrupar de a 3
from([1, 2, 3, 4, 5, 6, 7]).pipe(
  bufferCount(3)
).subscribe(grupo => console.log(grupo));
// [1, 2, 3]
// [4, 5, 6]
// [7] (el último grupo puede ser incompleto)

// Ventana deslizante: cada 2 valores, tomar los últimos 3
from([1, 2, 3, 4, 5, 6]).pipe(
  bufferCount(3, 2)
).subscribe(ventana => console.log(ventana));
// [1, 2, 3]
// [3, 4, 5]
// [5, 6]
```

## window: la versión de "orden superior"

`window` es conceptualmente similar a `buffer`, pero en lugar de emitir arrays, emite **Observables**. Es la versión "de orden superior" de `buffer`: cada "ventana" es un Observable que emite los valores de esa ventana.

```typescript
import { interval, Subject } from 'rxjs';
import { window as rxjsWindow, mergeMap, take, toArray } from 'rxjs/operators';

const fuente$ = interval(200);
const cerrar$ = interval(1000); // Cierra ventana cada segundo

fuente$.pipe(
  rxjsWindow(cerrar$),
  mergeMap(ventana$ =>
    ventana$.pipe(
      toArray()  // Convertir el Observable de ventana en array al completar
    )
  ),
  take(3)
).subscribe(ventana => {
  console.log('Ventana:', ventana);
  // Ventana: [0, 1, 2, 3, 4] (valores en los primeros 1000ms)
  // Ventana: [5, 6, 7, 8, 9] (valores en los siguientes 1000ms)
});
```

La ventaja de `window` sobre `buffer` es que podemos aplicar operadores al Observable de ventana antes de que cierre. Por ejemplo, podríamos filtrar o transformar valores dentro de la ventana mientras aún llegan.

En la práctica, `buffer` y `bufferTime` son suficientes para la mayoría de los casos. `window` aparece en escenarios más avanzados donde necesitamos transformaciones complejas dentro de cada grupo temporal.

## Puntos clave

- `scan` es el operador fundamental para estado acumulativo en tiempo real; piensa en él como el `reduce` que emite en cada paso, no solo al final.
- El patrón `Subject + scan + reducerPuro` es un mini-NgRx que cubre muchos casos sin la complejidad de la librería completa.
- `reduce` solo tiene sentido con Observables que completan; en streams infinitos de eventos de usuario, siempre prefiere `scan`.
- `bufferTime(ms)` es la herramienta clave para agrupar eventos de alta frecuencia en lotes antes de enviarlos a una API.
- `window` es la contraparte de "orden superior" de `buffer`; úsalo cuando necesitas aplicar operadores RxJS dentro de cada grupo antes de que cierre.

## ¿Qué sigue?

En la última parte de este capítulo aprenderemos a testear Observables con marble testing usando `TestScheduler`, eliminando la necesidad de esperar tiempo real en los tests.
