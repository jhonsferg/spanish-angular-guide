# Capítulo 31 - Parte 1: Testing Unitario con Jest - Setup y Primeras Pruebas

> **Parte 1 de 4** · Capítulo 31 · PARTE XIII - Librerías Esenciales del Ecosistema

Hablar de testing en Angular históricamente significaba hablar de Karma y Jasmine. Durante años, esa dupla fue el estándar. Sin embargo, la comunidad ha migrado masivamente a Jest, y hay razones muy concretas para ello. En esta parte veamos por qué vale la pena el cambio, cómo configurarlo correctamente y cómo escribir los primeros tests.

## ¿Por qué migrar de Karma + Jasmine a Jest?

La diferencia más inmediata es la **velocidad**. Karma necesita abrir un navegador real (o headless), compilar el proyecto y ejecutar los tests en ese contexto. Jest, en cambio, usa jsdom para simular el DOM en Node.js, lo que elimina el overhead de arrancar un navegador. Un proyecto mediano que tarda 45 segundos con Karma puede bajar a 8 segundos con Jest.

Otras ventajas concretas:

- **Snapshot testing**: Jest permite guardar una "foto" del output de un componente y detectar cambios no intencionales en el template.
- **Mejor DX**: mensajes de error más claros, modo watch más inteligente (solo re-ejecuta los tests afectados por los cambios).
- **Sin configuración de navegador**: no hay que mantener chromedriver ni preocuparse por versiones.
- **Mocking integrado**: `jest.fn()`, `jest.spyOn()` y `jest.mock()` son más poderosos que los spies de Jasmine.
- **Ecosistema más activo**: Jest es mantenido por Meta y usado en la mayoría de proyectos React y Node modernos.

## Instalación

Primero eliminamos Karma del proyecto:

```bash
npm uninstall karma karma-chrome-launcher karma-coverage karma-jasmine karma-jasmine-html-reporter
```

Luego instalamos Jest y el preset para Angular:

```bash
npm install -D jest jest-preset-angular @types/jest
```

El paquete `jest-preset-angular` es el que conecta Jest con el compilador de Angular. Maneja la transformación de TypeScript, los decoradores y los templates en línea.

## Configuración de `jest.config.ts`

```typescript
// jest.config.ts
import type { Config } from 'jest';

const config: Config = {
  preset: 'jest-preset-angular',
  setupFilesAfterFramework: ['<rootDir>/setup-jest.ts'],
  testEnvironment: 'jsdom',
  transform: {
    '^.+\\.(ts|mjs|js|html)$': [
      'jest-preset-angular',
      {
        tsconfig: '<rootDir>/tsconfig.spec.json',
        stringifyContentPathRegex: '\\.html$',
      },
    ],
  },
  moduleNameMapper: {
    // Mapear aliases de paths de TypeScript si los usamos
    '^@app/(.*)$': '<rootDir>/src/app/$1',
    '^@env/(.*)$': '<rootDir>/src/environments/$1',
  },
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.module.ts',
    '!src/main.ts',
    '!src/environments/**',
  ],
  coverageDirectory: 'coverage',
  coverageReporters: ['html', 'lcov', 'text-summary'],
};

export default config;
```

Creamos el archivo de setup:

```typescript
// setup-jest.ts
import 'jest-preset-angular/setup-jest';
```

## Actualización de `tsconfig.spec.json`

```json
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "outDir": "./out-tsc/spec",
    "types": ["jest"],
    "emitDecoratorMetadata": true
  },
  "include": [
    "src/**/*.spec.ts",
    "src/**/*.d.ts",
    "setup-jest.ts"
  ]
}
```

El cambio clave es reemplazar `"types": ["jasmine"]` por `"types": ["jest"]`. Esto garantiza que los tipos de Jest (como `describe`, `it`, `expect`) sean reconocidos por TypeScript.

## Actualizar `package.json`

```json
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "test:ci": "jest --ci --coverage --watchAll=false"
  }
}
```

También debemos eliminar la configuración de Karma del `angular.json` o actualizar la sección de `test` para que apunte al builder de Jest (si usamos `@angular-builders/jest`). La alternativa más simple es simplemente correr Jest directamente desde npm scripts, sin integrarlo con `ng test`.

## Diferencias de sintaxis: Jasmine vs Jest

La buena noticia es que la sintaxis es casi idéntica. Los cambios principales son:

```typescript
// JASMINE (antes)
describe('MiComponente', () => {
  it('debería crearse', () => {
    expect(component).toBeTruthy();
  });

  it('debería llamar al servicio', () => {
    const spy = spyOn(servicio, 'obtenerDatos').and.returnValue(of([]));
    expect(spy).toHaveBeenCalled();
  });
});

// JEST (ahora)
describe('MiComponente', () => {
  it('debería crearse', () => {
    expect(component).toBeTruthy();
  });

  it('debería llamar al servicio', () => {
    const spy = jest.spyOn(servicio, 'obtenerDatos').mockReturnValue(of([]));
    expect(spy).toHaveBeenCalled();
  });
});
```

Las diferencias principales:
- `spyOn(...).and.returnValue(x)` → `jest.spyOn(...).mockReturnValue(x)`
- `spyOn(...).and.callFake(fn)` → `jest.spyOn(...).mockImplementation(fn)`
- `jasmine.createSpy()` → `jest.fn()`
- `done` callbacks siguen funcionando igual para async

## Primer test de componente standalone con Jest

Construyamos un test completo para un componente standalone:

```typescript
// contador.component.ts
import { Component, signal } from '@angular/core';

@Component({
  selector: 'app-contador',
  standalone: true,
  template: `
    <div class="contador">
      <p data-testid="valor">Valor: {{ cuenta() }}</p>
      <button (click)="incrementar()">Incrementar</button>
      <button (click)="decrementar()" [disabled]="cuenta() === 0">
        Decrementar
      </button>
      <button (click)="reiniciar()">Reiniciar</button>
    </div>
  `
})
export class ContadorComponent {
  readonly cuenta = signal(0);

  incrementar(): void { this.cuenta.update(n => n + 1); }
  decrementar(): void { this.cuenta.update(n => Math.max(0, n - 1)); }
  reiniciar(): void  { this.cuenta.set(0); }
}
```

```typescript
// contador.component.spec.ts
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ContadorComponent } from './contador.component';

describe('ContadorComponent', () => {
  let componente: ContadorComponent;
  let fixture: ComponentFixture<ContadorComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ContadorComponent], // Standalone: va en imports, no en declarations
    }).compileComponents();

    fixture = TestBed.createComponent(ContadorComponent);
    componente = fixture.componentInstance;
    fixture.detectChanges(); // Dispara el ciclo de detección inicial
  });

  it('debería crearse correctamente', () => {
    expect(componente).toBeTruthy();
  });

  it('debería iniciar con cuenta en 0', () => {
    const parrafo = fixture.nativeElement.querySelector('[data-testid="valor"]');
    expect(parrafo.textContent).toContain('Valor: 0');
  });

  it('debería incrementar la cuenta al hacer clic', () => {
    const boton = fixture.nativeElement.querySelector('button');
    boton.click();
    fixture.detectChanges();

    expect(componente.cuenta()).toBe(1);
    const parrafo = fixture.nativeElement.querySelector('[data-testid="valor"]');
    expect(parrafo.textContent).toContain('Valor: 1');
  });

  it('no debería decrementar por debajo de 0', () => {
    const [, btnDecrementar] = fixture.nativeElement.querySelectorAll('button');
    expect(btnDecrementar.disabled).toBe(true);
    componente.decrementar();
    expect(componente.cuenta()).toBe(0);
  });

  it('debería reiniciar la cuenta', () => {
    componente.cuenta.set(5);
    fixture.detectChanges();
    const [,, btnReiniciar] = fixture.nativeElement.querySelectorAll('button');
    btnReiniciar.click();
    fixture.detectChanges();
    expect(componente.cuenta()).toBe(0);
  });
});
```

## Snapshot testing

Una capacidad exclusiva de Jest que no existe en Jasmine:

```typescript
it('debería coincidir con el snapshot', () => {
  const html = fixture.nativeElement.innerHTML;
  expect(html).toMatchSnapshot();
});
```

La primera vez que se ejecuta, Jest guarda el HTML en un archivo `__snapshots__/contador.component.spec.ts.snap`. En ejecuciones siguientes, compara el HTML actual con el guardado. Si difieren, el test falla, avisándonos de un cambio no intencional en el template.

## Puntos clave

- Jest es significativamente más rápido que Karma porque usa jsdom en lugar de un navegador real.
- `jest-preset-angular` es el puente entre Jest y el compilador de Angular; sin él los decoradores y templates no funcionan.
- En `tsconfig.spec.json`, cambiar `"types": ["jasmine"]` por `"types": ["jest"]` es obligatorio.
- Los componentes standalone van en `imports: [ComponenteStandalone]` dentro de `configureTestingModule`, no en `declarations`.
- `fixture.detectChanges()` es necesario después de cada cambio de estado para que el DOM se actualice.

## ¿Qué sigue?

En la siguiente parte adoptamos Angular Testing Library, una capa sobre TestBed que nos guía a escribir tests más resilientes que verifican comportamiento observable, no detalles de implementación.
