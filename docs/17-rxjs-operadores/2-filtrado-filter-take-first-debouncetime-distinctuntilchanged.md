# Capítulo 17 - Parte 2: Filtrado: filter, take, first, debounceTime, distinctUntilChanged

> **Parte 2 de 4** · Capítulo 17 · PARTE IX - Programación Reactiva con RxJS

Un Observable puede emitir muchos valores, pero no siempre queremos procesarlos todos. Los operadores de filtrado nos permiten decidir qué valores continúan por el pipeline, cuántos aceptamos y cuándo consideramos que ya vimos suficiente. Veamos cada uno en detalle y luego los combinaremos en un ejemplo real de buscador.

## filter: el portero del stream

`filter` recibe un predicado -una función que devuelve `boolean`- y solo deja pasar los valores para los cuales esa función retorna `true`. Es conceptualmente idéntico a `Array.prototype.filter`.

```typescript
import { Component, OnInit } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map, filter } from 'rxjs/operators';

interface Pedido {
  id: number;
  estado: 'pendiente' | 'aprobado' | 'rechazado';
  monto: number;
}

@Component({
  selector: 'app-pedidos-aprobados',
  template: `<li *ngFor="let p of pedidosGrandes$ | async">Pedido #{{ p.id }}</li>`
})
export class PedidosAprobadosComponent implements OnInit {
  pedidosGrandes$!: Observable<Pedido[]>;

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    this.pedidosGrandes$ = this.http.get<Pedido[]>('/api/pedidos').pipe(
      map(pedidos => pedidos.filter(p => p.estado === 'aprobado')),
      map(aprobados => aprobados.filter(p => p.monto > 1000))
    );
  }
}
```

Un detalle importante: cuando usamos `filter` sobre un Observable de valores individuales (no arrays), los valores filtrados simplemente no llegan al siguiente operador. El stream continúa vivo, esperando el próximo valor que sí cumpla la condición.

```typescript
import { fromEvent } from 'rxjs';
import { filter, map } from 'rxjs/operators';

// Solo procesar teclas Enter en un input
const entradas$ = fromEvent<KeyboardEvent>(document, 'keydown').pipe(
  filter(evento => evento.key === 'Enter'),
  map(evento => (evento.target as HTMLInputElement).value)
);
```

## take: completar tras N emisiones

`take(n)` deja pasar exactamente `n` valores y luego completa el Observable automáticamente. Es perfecto para cuando solo necesitamos una "instantánea" del stream o queremos limitar la cantidad de veces que se ejecuta algo.

```typescript
import { Component, OnInit } from '@angular/core';
import { interval, Observable } from 'rxjs';
import { take, map } from 'rxjs/operators';

@Component({
  selector: 'app-cuenta-regresiva',
  template: `<p>{{ cuenta$ | async }}</p>`
})
export class CuentaRegresivaComponent implements OnInit {
  cuenta$!: Observable<string>;

  ngOnInit(): void {
    this.cuenta$ = interval(1000).pipe(
      take(5),
      map(n => `Faltan ${4 - n} segundos`)
    );
    // Emitirá: "Faltan 4 segundos", "Faltan 3 segundos", ..., "Faltan 0 segundos"
    // Luego completa automáticamente
  }
}
```

La gran ventaja de `take(1)` en particular es que garantiza que el Observable se complete tras el primer valor, lo que evita memory leaks en subscripciones que solo necesitan un valor inicial.

## first: take(1) con superpoderes

`first(predicado?)` es como `take(1)` pero acepta un predicado opcional. Sin predicado, toma el primer valor y completa. Con predicado, toma el primer valor que cumpla la condición.

```typescript
import { from, first } from 'rxjs';

interface Usuario {
  id: number;
  rol: 'admin' | 'usuario' | 'moderador';
  nombre: string;
}

const usuarios: Usuario[] = [
  { id: 1, rol: 'usuario', nombre: 'Ana' },
  { id: 2, rol: 'admin', nombre: 'Carlos' },
  { id: 3, rol: 'moderador', nombre: 'Diana' }
];

// Obtener el primer administrador del stream
const primerAdmin$ = from(usuarios).pipe(
  first(u => u.rol === 'admin')
);

primerAdmin$.subscribe(admin => console.log('Admin:', admin.nombre)); // "Carlos"
```

Una diferencia importante con `find` de arreglos: si ningún valor cumple el predicado, `first` lanza un error. Para casos donde el valor podría no existir, existe `first(pred, valorPorDefecto)` que devuelve el valor por defecto en lugar de lanzar error.

## debounceTime: esperar la pausa

`debounceTime(ms)` es uno de los operadores más valiosos en interfaces de usuario. Solo emite un valor cuando han pasado `ms` milisegundos **sin que haya habido otra emisión**. Es decir, espera a que el stream "se calme" antes de dejar pasar el valor.

```typescript
import { Component, OnInit } from '@angular/core';
import { FormControl } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { Observable, EMPTY } from 'rxjs';
import { debounceTime, switchMap, catchError } from 'rxjs/operators';

interface Sugerencia {
  texto: string;
}

@Component({
  selector: 'app-autocompletado',
  template: `
    <input [formControl]="campo" placeholder="Escribe para buscar...">
    <ul>
      <li *ngFor="let s of sugerencias$ | async">{{ s.texto }}</li>
    </ul>
  `
})
export class AutocompletadoComponent implements OnInit {
  campo = new FormControl('');
  sugerencias$!: Observable<Sugerencia[]>;

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    this.sugerencias$ = this.campo.valueChanges.pipe(
      debounceTime(400),
      switchMap(termino =>
        termino
          ? this.http.get<Sugerencia[]>(`/api/sugerencias?q=${termino}`)
          : EMPTY
      ),
      catchError(() => EMPTY)
    );
  }
}
```

Sin `debounceTime`, cada letra que escribe el usuario dispararía una petición HTTP. Con 400ms, solo se dispara la petición cuando el usuario hace una pausa. En una conexión normal, eso puede reducir las peticiones de 20 a 3 o 4 en una búsqueda típica.

## distinctUntilChanged: ignorar repetidos consecutivos

`distinctUntilChanged()` no deja pasar un valor si es igual al anterior. Actúa como un filtro de "cambios reales". Sin argumentos, usa `===` para la comparación. Con un comparador personalizado, podemos definir qué significa "igual" para nuestros objetos.

```typescript
import { from, distinctUntilChanged } from 'rxjs';

// Valores: 1, 1, 2, 2, 2, 3, 1
// Con distinctUntilChanged emite: 1, 2, 3, 1
const valores$ = from([1, 1, 2, 2, 2, 3, 1]).pipe(
  distinctUntilChanged()
);

// Con objetos necesitamos un comparador
interface Filtros {
  categoria: string;
  precioMaximo: number;
}

// Solo procesar cuando los filtros realmente cambien
const filtros$ = /* algún BehaviorSubject<Filtros> */{} as any;
const filtrosCambiados$ = filtros$.pipe(
  distinctUntilChanged(
    (anterior: Filtros, actual: Filtros) =>
      anterior.categoria === actual.categoria &&
      anterior.precioMaximo === actual.precioMaximo
  )
);
```

## takeUntil: desuscribirse cuando otro Observable emite

`takeUntil(notificador$)` completa el Observable cuando el Observable notificador emite su primer valor. Es el mecanismo tradicional para gestionar el ciclo de vida de suscripciones en Angular.

```typescript
import { Component, OnInit, OnDestroy } from '@angular/core';
import { interval, Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';

@Component({
  selector: 'app-temporizador',
  template: `<p>Ticks: {{ contador }}</p>`
})
export class TemporizadorComponent implements OnInit, OnDestroy {
  contador = 0;
  private destruir$ = new Subject<void>();

  ngOnInit(): void {
    interval(1000).pipe(
      takeUntil(this.destruir$)
    ).subscribe(() => this.contador++);
  }

  ngOnDestroy(): void {
    this.destruir$.next();
    this.destruir$.complete();
  }
}
```

En Angular 16+, `takeUntilDestroyed()` de `@angular/core/rxjs-interop` reemplaza este patrón de forma más elegante (lo veremos en el Capítulo 18). Pero `takeUntil` sigue siendo válido y muy útil cuando el notificador viene de una lógica de negocio (no del ciclo de vida del componente).

## Ejemplo integrado: buscador completo

Combinemos `debounceTime`, `distinctUntilChanged`, `filter`, y `take` en un buscador realista que muestra cómo trabajan juntos:

```typescript
import { Component, OnInit } from '@angular/core';
import { FormControl, ReactiveFormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { Observable, EMPTY } from 'rxjs';
import { debounceTime, distinctUntilChanged, filter, switchMap, catchError, tap } from 'rxjs/operators';
import { AsyncPipe, NgFor } from '@angular/common';

interface ResultadoBusqueda {
  id: number;
  titulo: string;
  descripcion: string;
}

@Component({
  selector: 'app-buscador-completo',
  standalone: true,
  imports: [ReactiveFormsModule, AsyncPipe, NgFor],
  template: `
    <div>
      <input [formControl]="busqueda" placeholder="Mínimo 3 caracteres...">
      <span *ngIf="cargando">Buscando...</span>
      <ul>
        <li *ngFor="let resultado of resultados$ | async">
          <strong>{{ resultado.titulo }}</strong>: {{ resultado.descripcion }}
        </li>
      </ul>
    </div>
  `
})
export class BuscadorCompletoComponent implements OnInit {
  busqueda = new FormControl('');
  resultados$!: Observable<ResultadoBusqueda[]>;
  cargando = false;

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    this.resultados$ = this.busqueda.valueChanges.pipe(
      debounceTime(350),
      distinctUntilChanged(),
      filter(termino => (termino?.length ?? 0) >= 3),
      tap(() => (this.cargando = true)),
      switchMap(termino =>
        this.http.get<ResultadoBusqueda[]>(`/api/buscar?q=${termino}`).pipe(
          tap(() => (this.cargando = false)),
          catchError(() => {
            this.cargando = false;
            return EMPTY;
          })
        )
      )
    );
  }
}
```

El flujo es: espera 350ms de pausa → solo si el texto cambió → solo si tiene 3+ caracteres → activa el indicador de carga → cancela la petición anterior y hace una nueva → desactiva el indicador al recibir resultados.

## Puntos clave

- `filter` actúa sobre valores individuales del stream, no sobre colecciones; los valores que no pasan simplemente desaparecen.
- `take(1)` y `first()` son equivalentes sin predicado, pero `first(pred)` encuentra el primer valor que cumple una condición; si no hay ninguno, lanza un error.
- `debounceTime` es indispensable antes de cualquier petición HTTP disparada por entrada del usuario; 300-400ms es el rango habitual.
- `distinctUntilChanged` complementa a `debounceTime`: evita peticiones duplicadas cuando el usuario escribe y borra hasta llegar al mismo texto.
- La combinación `debounceTime + distinctUntilChanged + filter(longitud) + switchMap` es el patrón estándar para buscadores reactivos en Angular.

## ¿Qué sigue?

En la siguiente parte veremos los operadores de combinación -`combineLatest`, `forkJoin`, `zip` y `withLatestFrom`- para trabajar con múltiples streams de forma simultánea.
