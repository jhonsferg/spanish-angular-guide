# Capítulo 18 - Parte 4: Testing de Observables con marble testing

> **Parte 4 de 4** · Capítulo 18 · PARTE IX - Programación Reactiva con RxJS

Testear código asíncrono es difícil. Testear Observables con operadores de tiempo como `debounceTime` o `delay` puede ser extremadamente lento si esperamos el tiempo real, o frágil si usamos `fakeAsync` con `tick()`. Los marble tests resuelven esto de forma elegante: describen el comportamiento temporal de un Observable como una cadena de texto y usan tiempo virtual para ejecutar los tests en microsegundos.

## ¿Por qué el testing asíncrono normal es frágil?

Veamos el problema con un test tradicional de `debounceTime`:

```typescript
// Frágil: depende del tiempo real del sistema
it('debería emitir después de 300ms sin más valores', (done) => {
  const valores: number[] = [];
  const fuente$ = new Subject<number>();

  fuente$.pipe(debounceTime(300)).subscribe(v => valores.push(v));

  fuente$.next(1);
  fuente$.next(2);

  setTimeout(() => {
    expect(valores).toEqual([2]); // ¿Y si el sistema está ocupado?
    done();
  }, 400); // El test tarda 400ms reales en ejecutarse
});
```

Este test tarda 400ms en ejecutarse. Con 50 tests similares, la suite tarda 20 segundos. Además, en un sistema bajo carga, el `setTimeout` puede dispararse antes de lo esperado y el test falla de forma intermitente (flaky test).

## TestScheduler: tiempo virtual

`TestScheduler` de RxJS nos permite controlar el tiempo como si fuera una variable. Podemos "avanzar" 300ms de tiempo virtual en microsegundos reales. Los tests con `TestScheduler` son deterministas y prácticamente instantáneos.

```typescript
import { TestScheduler } from 'rxjs/testing';

describe('MiOperador', () => {
  let testScheduler: TestScheduler;

  beforeEach(() => {
    testScheduler = new TestScheduler((actual, expected) => {
      expect(actual).toEqual(expected);
    });
  });

  it('debería funcionar', () => {
    testScheduler.run(({ cold, hot, expectObservable }) => {
      // Definimos el Observable y sus expectativas aquí
      const fuente$ = cold('--a--b--c|');
      const esperado  =    '--a--b--c|';
      expectObservable(fuente$).toBe(esperado);
    });
  });
});
```

El callback de `TestScheduler` recibe el resultado actual y el esperado, y la función que pasemos se usa para hacer la aserción. Con Jest, `expect(actual).toEqual(expected)` funciona perfectamente.

## Sintaxis de marble strings

La sintaxis de "mármol" (marble strings) representa el comportamiento de un Observable como texto, donde cada carácter representa un "frame" de tiempo virtual:

| Carácter | Significado |
|---|---|
| `-` | Un frame de tiempo (10ms por defecto en modo `run`) |
| `a-z`, `A-Z`, `0-9` | Emisión de un valor (la letra es la clave en el mapa de valores) |
| `\|` | El Observable completa |
| `#` | El Observable lanza un error |
| `()` | Emisiones sincrónicas (en el mismo frame) |
| `^` | Punto de suscripción (solo en hot Observables) |
| `!` | Punto de cancelación (en `expectSubscriptions`) |
| ` ` | Espacio en blanco (ignorado, mejora legibilidad) |

```typescript
// '--a--b--c|' significa:
// Frame 0: nada
// Frame 1: nada
// Frame 2: emite 'a'
// Frame 3: nada
// Frame 4: nada
// Frame 5: emite 'b'
// Frame 6: nada
// Frame 7: nada
// Frame 8: emite 'c'
// Frame 9: completa

// '(abc|)' significa:
// Frame 0: emite 'a', 'b', 'c' y completa (todo en el mismo frame)

// '--#' significa:
// Frame 2: lanza un error
```

## Cold vs Hot en tests

La diferencia entre `cold` y `hot` en marble testing refleja la misma distinción que en Observables reales:

```typescript
import { TestScheduler } from 'rxjs/testing';
import { map } from 'rxjs/operators';

describe('cold vs hot', () => {
  let testScheduler: TestScheduler;

  beforeEach(() => {
    testScheduler = new TestScheduler((actual, expected) => {
      expect(actual).toEqual(expected);
    });
  });

  it('cold: cada suscriptor recibe la secuencia desde el inicio', () => {
    testScheduler.run(({ cold, expectObservable }) => {
      // cold: el tiempo empieza cuando alguien se suscribe
      const frio$ = cold('--a--b--c|', { a: 1, b: 2, c: 3 });
      expectObservable(frio$).toBe('--a--b--c|', { a: 1, b: 2, c: 3 });
    });
  });

  it('hot: el Observable existe antes de que nadie se suscriba', () => {
    testScheduler.run(({ hot, expectObservable }) => {
      // hot: ^ indica cuándo empieza la suscripción
      // Los valores antes de ^ ya se perdieron
      const caliente$ = hot('--a--^--b--c|', { a: 1, b: 2, c: 3 });
      // El suscriptor solo ve b y c, no a
      expectObservable(caliente$).toBe('---b--c|', { b: 2, c: 3 });
    });
  });
});
```

## Ejemplo completo: testear switchMap con debounceTime

Veamos el caso más valioso: testear el pipeline completo de un buscador sin esperar tiempo real.

Primero, el operador que vamos a testear:

```typescript
// buscador.operador.ts
import { Observable, EMPTY } from 'rxjs';
import { debounceTime, distinctUntilChanged, filter, switchMap } from 'rxjs/operators';
import { HttpClient } from '@angular/common/http';

export interface ResultadoBusqueda {
  id: number;
  titulo: string;
}

export function crearPipelineBuscador(
  http: HttpClient
): (fuente$: Observable<string>) => Observable<ResultadoBusqueda[]> {
  return (fuente$: Observable<string>) =>
    fuente$.pipe(
      debounceTime(300),
      distinctUntilChanged(),
      filter(termino => termino.length >= 2),
      switchMap(termino =>
        http.get<ResultadoBusqueda[]>(`/api/buscar?q=${termino}`)
      )
    );
}
```

Ahora el test con marble testing:

```typescript
// buscador.operador.spec.ts
import { TestScheduler } from 'rxjs/testing';
import { of } from 'rxjs';
import { crearPipelineBuscador, ResultadoBusqueda } from './buscador.operador';

describe('crearPipelineBuscador', () => {
  let testScheduler: TestScheduler;

  const mockResultados: ResultadoBusqueda[] = [
    { id: 1, titulo: 'Angular' },
    { id: 2, titulo: 'Angular Material' }
  ];

  const mockHttp = {
    get: jest.fn().mockReturnValue(of(mockResultados))
  } as any;

  beforeEach(() => {
    testScheduler = new TestScheduler((actual, expected) => {
      expect(actual).toEqual(expected);
    });
    jest.clearAllMocks();
  });

  it('debería emitir resultados tras 300ms de debounce', () => {
    testScheduler.run(({ cold, hot, expectObservable }) => {
      // 300ms = 300 frames en modo run (cada - = 1ms)
      const entrada$ = cold('a 299ms b 300ms c|', {
        a: 'an',
        b: 'ang',
        c: 'angu'
      });

      const resultado$ = entrada$.pipe(crearPipelineBuscador(mockHttp));

      // Solo 'c' llega después de 300ms sin más emisiones
      expectObservable(resultado$).toBe(
        '600ms r 300ms s|',
        { r: mockResultados, s: mockResultados }
      );
    });
  });

  it('debería ignorar términos de menos de 2 caracteres', () => {
    testScheduler.run(({ cold, expectObservable }) => {
      const entrada$ = cold('a 300ms b|', { a: 'a', b: 'an' });
      const resultado$ = entrada$.pipe(crearPipelineBuscador(mockHttp));

      // 'a' (1 char) se filtra; 'an' (2 chars) pasa tras 300ms
      expectObservable(resultado$).toBe('600ms r|', { r: mockResultados });
    });
  });

  it('debería cancelar petición anterior con switchMap', () => {
    testScheduler.run(({ cold, hot, expectObservable }) => {
      // Dos búsquedas rápidas: la primera debe cancelarse
      const primeraRespuesta$ = cold('200ms r|', { r: [{ id: 1, titulo: 'Viejo' }] });
      const segundaRespuesta$ = cold('100ms r|', { r: mockResultados });

      let llamada = 0;
      const httpMock = {
        get: jest.fn().mockImplementation(() => {
          return llamada++ === 0 ? primeraRespuesta$ : segundaRespuesta$;
        })
      } as any;

      const entrada$ = hot('a 200ms b 300ms |', { a: 'an', b: 'ang' });
      const resultado$ = entrada$.pipe(crearPipelineBuscador(httpMock));

      // Solo vemos el resultado de 'ang', no de 'an'
      expectObservable(resultado$).toBe('800ms r |', { r: mockResultados });
    });
  });
});
```

## Integración con Jest: configuración mínima

```typescript
// jest.config.js o jest.config.ts
import type { Config } from 'jest';

const config: Config = {
  preset: 'jest-preset-angular',
  setupFilesAfterFramework: ['<rootDir>/setup-jest.ts'],
  transform: {
    '^.+\\.(ts|mjs|js|html)$': [
      'jest-preset-angular',
      {
        tsconfig: '<rootDir>/tsconfig.spec.json',
        stringifyContentPathRegex: '\\.(html|svg)$'
      }
    ]
  }
};

export default config;
```

```typescript
// setup-jest.ts
import 'jest-preset-angular/setup-jest';
// TestScheduler ya está disponible desde 'rxjs/testing', no requiere setup extra
```

## Testear operadores de error con marbles

```typescript
import { TestScheduler } from 'rxjs/testing';
import { catchError } from 'rxjs/operators';
import { EMPTY } from 'rxjs';

describe('manejo de errores con marbles', () => {
  let testScheduler: TestScheduler;

  beforeEach(() => {
    testScheduler = new TestScheduler((actual, expected) => {
      expect(actual).toEqual(expected);
    });
  });

  it('catchError debería retornar EMPTY en caso de error', () => {
    testScheduler.run(({ cold, expectObservable }) => {
      const fuenteConError$ = cold('--a--#', { a: 1 }, new Error('Fallo de red'));

      const resultado$ = fuenteConError$.pipe(
        catchError(() => EMPTY)
      );

      // Después del error, EMPTY completa inmediatamente
      expectObservable(resultado$).toBe('--a--|', { a: 1 });
    });
  });
});
```

## Puntos clave

- El testing asíncrono tradicional de Observables es lento y frágil; los marble tests son deterministas y se ejecutan en microsegundos reales.
- `TestScheduler` controla el tiempo virtual: podemos "avanzar" 300ms de debounce sin esperar 300ms reales.
- La sintaxis de marble strings usa `-` para frames, letras para valores, `|` para completar y `#` para error; los espacios en blanco son ignorados y mejoran la legibilidad.
- `cold` crea un Observable cuyo tiempo empieza al suscribirse; `hot` crea uno que ya está "en vuelo" (usa `^` para marcar el inicio de la suscripción).
- En el modo `testScheduler.run()`, cada `-` representa 1ms de tiempo virtual, lo que hace los marble strings más legibles para debounces y delays reales.

## ¿Qué sigue?

Con esto completamos la Parte IX de programación reactiva con RxJS. El siguiente paso natural es aplicar estos patrones en una arquitectura completa con NgRx: store, actions, reducers, effects y selectors, donde todo lo que aprendimos aquí se convierte en los bloques de construcción de una aplicación Angular escalable.
