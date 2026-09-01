# Capítulo 17 - Parte 4: Manejo de errores: catchError, retry, retryWhen, throwError

> **Parte 4 de 4** · Capítulo 17 · PARTE IX - Programación Reactiva con RxJS

Los errores en Observables tienen una naturaleza diferente a los errores en código imperativo. Cuando un Observable lanza un error, el stream termina: no habrá más emisiones. Por eso el manejo de errores en RxJS no es solo sobre capturar excepciones, sino sobre decidir qué le pasa al stream después de un fallo. Veamos las herramientas disponibles.

## Por qué los errores son especiales en RxJS

En un Observable, existen tres tipos de notificaciones: `next` (un valor), `error` (fallo terminal) y `complete` (finalización exitosa). Cuando llega una notificación de `error`, el stream se cierra. Si no lo manejamos, el error se propaga al suscriptor y la suscripción termina.

Esto significa que si tenemos un buscador en tiempo real y la primera petición HTTP falla, sin manejo de errores el Observable del buscador muere para siempre. El usuario no podrá buscar más nada hasta que recargue la página.

## catchError: recuperarse o re-lanzar

`catchError` intercepta la notificación de error y nos da la oportunidad de devolver un Observable alternativo o re-lanzar el error (posiblemente transformado).

```typescript
import { Component, OnInit } from '@angular/core';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { Observable, EMPTY, of } from 'rxjs';
import { catchError, map } from 'rxjs/operators';

interface Articulo {
  id: number;
  titulo: string;
}

@Component({
  selector: 'app-articulos',
  template: `<li *ngFor="let a of articulos$ | async">{{ a.titulo }}</li>`
})
export class ArticulosComponent implements OnInit {
  articulos$!: Observable<Articulo[]>;
  mensajeError = '';

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    this.articulos$ = this.http.get<Articulo[]>('/api/articulos').pipe(
      catchError((error: HttpErrorResponse) => {
        if (error.status === 404) {
          return of([]);  // Retorna lista vacía como fallback
        }
        this.mensajeError = 'Error al cargar artículos. Intenta de nuevo.';
        return EMPTY;  // Completa sin emitir nada
      })
    );
  }
}
```

La diferencia entre retornar `of([])` y `EMPTY` es sutil pero importante:
- `of([])` emite un valor (la lista vacía) y luego completa. El `async pipe` recibirá `[]`.
- `EMPTY` completa directamente sin emitir. El `async pipe` no actualizará el template.
- `throwError(() => new Error('...'))` re-lanza el error, propagándolo al suscriptor.

## Mantener el stream vivo tras un error

El problema que mencionamos antes: si un Observable de eventos (como un buscador) falla, muere. La solución clásica es poner el `catchError` **dentro** del `switchMap`, no fuera:

```typescript
import { Component, OnInit } from '@angular/core';
import { FormControl } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { Observable, EMPTY } from 'rxjs';
import { debounceTime, distinctUntilChanged, switchMap, catchError } from 'rxjs/operators';

interface ResultadoBusqueda {
  id: number;
  titulo: string;
}

@Component({
  selector: 'app-buscador-robusto',
  template: `<input [formControl]="busqueda">`
})
export class BuscadorRobustoComponent implements OnInit {
  busqueda = new FormControl('');
  resultados$!: Observable<ResultadoBusqueda[]>;

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    this.resultados$ = this.busqueda.valueChanges.pipe(
      debounceTime(300),
      distinctUntilChanged(),
      switchMap(termino =>
        this.http.get<ResultadoBusqueda[]>(`/api/buscar?q=${termino}`).pipe(
          catchError(() => EMPTY)  // Error interno al Observable de la petición
        )
        // El catchError está DENTRO del switchMap: si esta petición falla,
        // el Observable externo (valueChanges) sigue vivo para la próxima búsqueda
      )
    );
  }
}
```

Si el `catchError` estuviera fuera del `switchMap`, un error en la petición HTTP mataría el Observable `valueChanges.pipe(...)` completo. Adentro, solo muere el Observable de esa petición específica.

## retry: reintentos inmediatos

`retry(n)` re-suscribe automáticamente al Observable fuente hasta `n` veces cuando ocurre un error. Si después de `n` reintentos sigue fallando, el error se propaga.

```typescript
import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { retry, catchError, throwError } from 'rxjs/operators';

interface Configuracion {
  version: string;
  opciones: Record<string, unknown>;
}

@Injectable({ providedIn: 'root' })
export class ConfiguracionService {
  constructor(private http: HttpClient) {}

  obtenerConfiguracion(): Observable<Configuracion> {
    return this.http.get<Configuracion>('/api/configuracion').pipe(
      retry(3),
      catchError(error => {
        console.error('Falló después de 3 reintentos:', error);
        return throwError(() => new Error('No se pudo cargar la configuración'));
      })
    );
  }
}
```

El problema con `retry(n)` es que los reintentos son **inmediatos**. Si el servidor está sobrecargado, bombardearlo con tres peticiones seguidas no ayuda. Para eso necesitamos `retryWhen` o la versión moderna: `retry({ delay })`.

## retryWhen con backoff exponencial

Con RxJS 7+, `retry` acepta una configuración más detallada que permite implementar backoff exponencial sin necesidad de `retryWhen`:

```typescript
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, timer } from 'rxjs';
import { retry, catchError, throwError } from 'rxjs/operators';

interface DatosCriticos {
  valor: number;
  timestamp: string;
}

@Injectable({ providedIn: 'root' })
export class DatosCriticosService {
  constructor(private http: HttpClient) {}

  obtenerDatos(): Observable<DatosCriticos> {
    return this.http.get<DatosCriticos>('/api/datos-criticos').pipe(
      retry({
        count: 4,
        delay: (error, intentoActual) => {
          const esperaMs = Math.pow(2, intentoActual) * 1000; // 2s, 4s, 8s, 16s
          console.warn(`Intento ${intentoActual}, reintentando en ${esperaMs}ms`);
          return timer(esperaMs);
        }
      }),
      catchError(error => throwError(() => error))
    );
  }
}
```

Si necesitamos usar la sintaxis clásica de `retryWhen` por compatibilidad o mayor control:

```typescript
import { Observable, timer, throwError } from 'rxjs';
import { retryWhen, mergeMap, finalize } from 'rxjs/operators';

function conBackoffExponencial<T>(
  observable$: Observable<T>,
  maxIntentos = 3
): Observable<T> {
  return observable$.pipe(
    retryWhen(errores$ =>
      errores$.pipe(
        mergeMap((error, indice) => {
          if (indice >= maxIntentos) {
            return throwError(() => error);
          }
          const esperaMs = Math.pow(2, indice + 1) * 1000;
          return timer(esperaMs);
        })
      )
    )
  );
}
```

## finalize: limpiar siempre

`finalize` ejecuta una función cuando el Observable completa, ya sea por éxito o por error. Es el equivalente reactivo del bloque `finally` en un `try/catch/finally`.

```typescript
import { Component } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { finalize, catchError } from 'rxjs/operators';
import { EMPTY } from 'rxjs';

interface Reporte {
  total: number;
  items: string[];
}

@Component({
  selector: 'app-reporte',
  template: `
    <button (click)="generar()" [disabled]="cargando">Generar reporte</button>
    <span *ngIf="cargando">Generando...</span>
  `
})
export class ReporteComponent {
  cargando = false;

  constructor(private http: HttpClient) {}

  generar(): void {
    this.cargando = true;
    this.http.post<Reporte>('/api/reportes/generar', {}).pipe(
      catchError(() => EMPTY),
      finalize(() => {
        this.cargando = false;  // Siempre se ejecuta, éxito o error
      })
    ).subscribe(reporte => {
      console.log('Reporte generado:', reporte.total, 'items');
    });
  }
}
```

Sin `finalize`, si la petición falla y usamos `catchError` para silenciar el error, `cargando` nunca volvería a `false`. El botón quedaría bloqueado indefinidamente.

## Manejo de errores en cadenas largas

Cuando tenemos pipelines complejos, el error se propaga hacia adelante hasta encontrar el primer `catchError`. Podemos tener múltiples `catchError` en diferentes puntos del pipeline para manejar distintos tipos de error:

```typescript
import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable, of } from 'rxjs';
import { switchMap, map, catchError, retry } from 'rxjs/operators';

interface Usuario { id: number; }
interface Perfil { nombre: string; foto: string; }
interface Preferencias { tema: string; }

@Injectable({ providedIn: 'root' })
export class PerfilCompletoService {
  constructor(private http: HttpClient) {}

  obtenerPerfilCompleto(usuarioId: number): Observable<Perfil & Preferencias> {
    return this.http.get<Usuario>(`/api/usuarios/${usuarioId}`).pipe(
      retry(2),
      catchError(() => of({ id: usuarioId })),  // Fallback al ID si falla
      switchMap(usuario =>
        this.http.get<Perfil>(`/api/perfiles/${usuario.id}`).pipe(
          catchError(() => of({ nombre: 'Anónimo', foto: '/default.png' }))
        )
      ),
      switchMap(perfil =>
        this.http.get<Preferencias>(`/api/preferencias/${usuarioId}`).pipe(
          map(prefs => ({ ...perfil, ...prefs })),
          catchError(() => of({ ...perfil, tema: 'claro' }))  // Preferencias por defecto
        )
      )
    );
  }
}
```

Cada `catchError` maneja su tramo del pipeline independientemente, garantizando que el usuario siempre ve algo útil aunque alguna de las APIs falle.

## Puntos clave

- Cuando un Observable lanza un error, el stream termina; el manejo de errores en RxJS es sobre decidir qué Observable reemplaza al fallido.
- Colocar `catchError` dentro de `switchMap` (no fuera) mantiene el Observable externo vivo para futuras emisiones, lo cual es crítico en streams de eventos de usuario.
- `retry(n)` reintenta inmediatamente; usa `retry({ count, delay })` para implementar backoff exponencial sin dependencias extra.
- `finalize` garantiza que el código de limpieza se ejecute independientemente del resultado; es el `finally` del mundo reactivo.
- En cadenas largas, los `catchError` actúan como "cortafuegos": el error no se propaga más allá del `catchError` que lo capture.

## ¿Qué sigue?

En el Capítulo 18 pasamos de los operadores individuales a los patrones arquitecturales: cómo construir servicios de estado reactivo con `BehaviorSubject`, gestionar el ciclo de vida de las suscripciones y hacer testing de Observables con marble testing.
