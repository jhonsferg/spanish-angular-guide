# Capítulo 6 - Parte 1: Directivas estructurales built-in: ngIf, ngFor, ngSwitch

> **Parte 1 de 4** · Capítulo 6 · PARTE III - Templates y Directivas

Las directivas estructurales son un tipo especial de directiva que modifica la estructura del DOM: agregan, eliminan o reorganizan elementos. Se reconocen por el asterisco `*` que precede su nombre en el template. Aunque Angular 17 introdujo la nueva sintaxis `@if`/`@for` (→ Ver Capítulo 5, Parte 4), las directivas estructurales clásicas son esencia del lenguaje y siguen apareciendo en millones de proyectos activos. Entenderlas bien es indispensable para trabajar con bases de código existentes y para comprender qué hace el compilador detrás de la nueva sintaxis.

## `*ngIf` y el secreto del asterisco

El asterisco en `*ngIf` no es decorativo: es una abreviatura que el compilador de Angular expande en sintaxis de `<ng-template>`. Estas dos formas son equivalentes:

```html
<!-- Forma abreviada con asterisco -->
<p *ngIf="estaAutenticado">Bienvenido, usuario.</p>

<!-- Forma expandida que el compilador genera internamente -->
<ng-template [ngIf]="estaAutenticado">
  <p>Bienvenido, usuario.</p>
</ng-template>
```

El compilador toma el elemento con `*ngIf`, lo envuelve en un `<ng-template>` y convierte la directiva estructural en un property binding normal. Esto explica la "microsyntax" de las directivas estructurales: es un mini-lenguaje que el compilador traduce a property bindings sobre `<ng-template>`.

Para usar `*ngIf` en un componente standalone, hay que importar `NgIf` o `CommonModule`:

```typescript
import { Component } from '@angular/core';
import { NgIf } from '@angular/common'; // Importación específica (recomendada)

@Component({
  selector: 'app-estado-sesion',
  standalone: true,
  imports: [NgIf],
  template: `
    <p *ngIf="estaAutenticado">Bienvenido al sistema.</p>
    <p *ngIf="!estaAutenticado">Por favor inicia sesión.</p>
  `
})
export class EstadoSesionComponent {
  estaAutenticado = true;
}
```

## `*ngIf` con `then` y `else`

La directiva `*ngIf` acepta los modificadores `then` y `else` que referencian `<ng-template>` con nombre. Es la forma clásica de manejar ramas condicionales alternativas:

```typescript
import { Component } from '@angular/core';
import { NgIf } from '@angular/common';

@Component({
  selector: 'app-carga-datos',
  standalone: true,
  imports: [NgIf],
  template: `
    <!-- then y else apuntan a ng-template por su #nombre -->
    <div *ngIf="!cargando; then contenido; else cargador"></div>

    <ng-template #contenido>
      <ul>
        <li *ngFor="let item of datos">{{ item }}</li>
      </ul>
    </ng-template>

    <ng-template #cargador>
      <p>Cargando datos...</p>
    </ng-template>
  `
})
export class CargaDatosComponent {
  cargando = false;
  datos = ['Producto A', 'Producto B', 'Producto C'];
}
```

También existe la variante `as` que captura el valor para usarlo dentro del bloque, equivalente al `; as variable` de la nueva sintaxis:

```html
<!-- Captura el resultado de la expresión en la variable "usuario" -->
<div *ngIf="obtenerUsuario() as usuario">
  <p>{{ usuario.nombre }}</p>
</div>
```

## `*ngFor` con variables de contexto

`*ngFor` itera sobre cualquier iterable y crea una copia del elemento del template por cada ítem. La microsyntax expone varias variables locales que enriquecen la iteración:

```typescript
import { Component } from '@angular/core';
import { NgFor } from '@angular/common';

interface Empleado {
  id: number;
  nombre: string;
  departamento: string;
}

@Component({
  selector: 'app-lista-empleados',
  standalone: true,
  imports: [NgFor],
  template: `
    <table>
      <tbody>
        <tr
          *ngFor="
            let empleado of empleados;
            index as i;
            first as esPrimero;
            last as esUltimo;
            even as esPar;
            odd as esImpar;
            trackBy: identificarEmpleado
          "
          [class.primera-fila]="esPrimero"
          [class.ultima-fila]="esUltimo"
          [class.fila-par]="esPar"
        >
          <td>{{ i + 1 }}</td>
          <td>{{ empleado.nombre }}</td>
          <td>{{ empleado.departamento }}</td>
        </tr>
      </tbody>
    </table>
  `
})
export class ListaEmpleadosComponent {
  empleados: Empleado[] = [
    { id: 1, nombre: 'Ana Martínez', departamento: 'Ingeniería' },
    { id: 2, nombre: 'Carlos López', departamento: 'Diseño' },
    { id: 3, nombre: 'María Rodríguez', departamento: 'Marketing' },
  ];

  // trackBy equivale al track de @for; recibe el índice y el elemento
  identificarEmpleado(indice: number, empleado: Empleado): number {
    return empleado.id;
  }
}
```

Las variables de contexto se declaran con `let variable of` para el ítem principal y con `variable as alias` para los valores contextuales. `trackBy` recibe una función que devuelve el identificador único, con la misma función de optimización que `track` en la nueva sintaxis.

## La microsyntax de las directivas estructurales

La microsyntax es el mini-lenguaje que Angular define para la expresión dentro de un `*directiva`. El compilador la parsea y la convierte en `<ng-template>` con property bindings. Para `*ngFor` la expansión completa es:

```html
<!-- Microsyntax abreviada -->
<li *ngFor="let empleado of empleados; trackBy: identificarEmpleado">

<!-- Lo que el compilador genera -->
<ng-template
  ngFor
  let-empleado
  [ngForOf]="empleados"
  [ngForTrackBy]="identificarEmpleado"
>
  <li>...</li>
</ng-template>
```

Cada palabra clave de la microsyntax se mapea a un property binding en el `<ng-template>`. Esto permite que las directivas estructurales sean altamente extensibles: la directiva declara qué palabras clave acepta y qué hacen.

## `*ngSwitch`, `ngSwitchCase` y `ngSwitchDefault`

`*ngSwitch` es la variante de switch para templates. A diferencia de `*ngIf` y `*ngFor`, el switch se implementa con tres directivas que trabajan juntas:

```typescript
import { Component } from '@angular/core';
import { NgSwitch, NgSwitchCase, NgSwitchDefault } from '@angular/common';

type Tema = 'claro' | 'oscuro' | 'sistema';

@Component({
  selector: 'app-selector-tema',
  standalone: true,
  // Las tres directivas deben importarse por separado si no se usa CommonModule
  imports: [NgSwitch, NgSwitchCase, NgSwitchDefault],
  template: `
    <!-- ngSwitch evalúa la expresión -->
    <div [ngSwitch]="temaActual">

      <!-- *ngSwitchCase compara con cada valor posible -->
      <div *ngSwitchCase="'claro'">
        <p>Tema claro activado. Fondo blanco, texto oscuro.</p>
      </div>

      <div *ngSwitchCase="'oscuro'">
        <p>Tema oscuro activado. Fondo negro, texto claro.</p>
      </div>

      <div *ngSwitchCase="'sistema'">
        <p>Siguiendo la preferencia del sistema operativo.</p>
      </div>

      <!-- *ngSwitchDefault cuando ningún case coincide -->
      <div *ngSwitchDefault>
        <p>Tema no reconocido. Usando tema claro por defecto.</p>
      </div>
    </div>

    <div>
      <button (click)="temaActual = 'claro'">Claro</button>
      <button (click)="temaActual = 'oscuro'">Oscuro</button>
      <button (click)="temaActual = 'sistema'">Sistema</button>
    </div>
  `
})
export class SelectorTemaComponent {
  temaActual: Tema = 'claro';
}
```

Nótese que `[ngSwitch]` usa corchetes (property binding) mientras que `*ngSwitchCase` y `*ngSwitchDefault` usan asterisco (directivas estructurales). El contenedor recibe la expresión a evaluar y los hijos determinan qué se muestra.

## Cuándo migrar a `@if` y `@for`

La migración a la nueva sintaxis es recomendable para proyectos en activo desarrollo, pero no es urgente para proyectos estables. Angular provee un schematic de migración automática:

```bash
ng generate @angular/core:control-flow
```

Este comando convierte automáticamente `*ngIf`, `*ngFor` y `*ngSwitch` a la nueva sintaxis en todos los templates del proyecto. Las razones para migrar incluyen:

- Eliminación de las importaciones `NgIf`, `NgFor`, `NgSwitch` en cada componente standalone.
- Mejor análisis de tipos por parte del compilador (TypeScript puede inferir el tipo dentro del bloque `@if`).
- La obligatoriedad de `track` en `@for` evita errores de rendimiento por omisión.
- El bloque `@empty` simplifica el patrón de lista vacía.

Para proyectos que usan `NgModule` en lugar de standalone, `CommonModule` sigue siendo la forma estándar de importar estas directivas, y la migración es opcional.

## Diagrama: expansión de la microsyntax por el compilador

```mermaid
flowchart TD
    M["Microsyntax en el template\n*ngFor=\"let x of lista; trackBy: fn\""]
    M --> C["Compilador Angular"]
    C --> T["&lt;ng-template\n  ngFor\n  let-x\n  [ngForOf]=\"lista\"\n  [ngForTrackBy]=\"fn\"\n&gt;"]
    T --> R["Directiva NgFor\ninstanciada en tiempo de ejecución"]
    R --> D["Nodos DOM creados\npara cada elemento"]
```

## Puntos clave

- El asterisco `*` en directivas estructurales es azúcar sintáctica para `<ng-template>` con property bindings.
- `*ngIf` acepta `then`, `else` y `as` para manejar ramas y capturar valores.
- `*ngFor` expone `index`, `first`, `last`, `even`, `odd` como variables de contexto; `trackBy` optimiza el rendimiento.
- `*ngSwitch` requiere tres directivas coordinadas: `[ngSwitch]`, `*ngSwitchCase` y `*ngSwitchDefault`.
- En componentes standalone se importan individualmente (`NgIf`, `NgFor`, `NgSwitch`) o juntos con `CommonModule`.
- La migración a `@if`/`@for` es automatizable con `ng generate @angular/core:control-flow`.

## ¿Qué sigue?

En la Parte 2 estudiamos las directivas de atributo built-in: `ngClass` y `ngStyle`, que permiten manipular clases CSS y estilos de forma dinámica con una sintaxis más expresiva que los bindings directos `[class]` y `[style]`.
