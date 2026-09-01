# Capítulo 3 - Parte 4: Estilos en componentes: encapsulación y ViewEncapsulation

> **Parte 4 de 4** · Capítulo 3 · PARTE II - Componentes: El Alma de Angular

Una de las mayores frustraciones en el desarrollo web tradicional es la cascada de CSS: un cambio en una clase puede afectar, de forma inesperada, a elementos en partes completamente distintas de la aplicación. Angular resuelve esto con la encapsulación de estilos, un mecanismo que hace que los estilos de cada componente sean privados por defecto. Entender cómo funciona internamente, y cuándo romper esa encapsulación deliberadamente, es una habilidad clave para escribir componentes que sean verdaderamente reutilizables y predecibles.

## Cómo funciona la encapsulación emulada

El modo por defecto de Angular se llama `Emulated` (encapsulación emulada). El nombre viene de que Angular simula el comportamiento del Shadow DOM nativo de los navegadores, pero sin usarlo realmente, lo que garantiza compatibilidad con cualquier entorno.

El mecanismo es directo: en tiempo de compilación, Angular añade un atributo único y autogenerado a cada elemento del template de un componente, algo como `_nghost-abc-1` en el elemento raíz y `_ngcontent-abc-1` en los elementos internos. Luego transforma los selectores CSS del componente para que solo apliquen a elementos que tengan ese atributo:

```css
/* Lo que escribes en el archivo de estilos del componente */
.titulo { color: #1976d2; font-size: 1.5rem; }

/* Lo que Angular genera en el bundle final */
.titulo[_ngcontent-abc-1] { color: #1976d2; font-size: 1.5rem; }
```

El resultado es que `.titulo` dentro de `ComponenteA` nunca colisionará con `.titulo` dentro de `ComponenteB`, aunque compartan el mismo nombre de clase. Cada regla CSS elige únicamente los elementos del componente al que pertenece.

## Las tres opciones de ViewEncapsulation

La propiedad `encapsulation` del decorador `@Component` acepta un valor del enum `ViewEncapsulation`:

```typescript
import { Component, ViewEncapsulation } from '@angular/core';

@Component({
  selector: 'app-ejemplo',
  standalone: true,
  template: `<p class="texto">Hola mundo</p>`,
  styles: [`.texto { color: navy; }`],
  // Cambia el modo de encapsulación aquí:
  encapsulation: ViewEncapsulation.Emulated  // Valor por defecto
})
export class EjemploComponent {}
```

**`ViewEncapsulation.Emulated`** (por defecto): Angular añade los atributos únicos y transforma los selectores. Los estilos del componente quedan aislados. Es la opción correcta para el 95% de los casos.

**`ViewEncapsulation.None`**: Angular no hace ninguna transformación. Los estilos del componente se inyectan como estilos globales en el `<head>` del documento. Úsalo solo cuando necesitas que los estilos del componente afecten deliberadamente al DOM externo, por ejemplo en un componente de reset o en un componente que estiliza contenido externo renderizado dinámicamente (como Markdown convertido a HTML).

**`ViewEncapsulation.ShadowDom`**: Angular usa el Shadow DOM nativo del navegador. Los estilos están completamente aislados y los del exterior no pueden penetrar (salvo CSS custom properties). Es el más puro en términos de aislamiento, pero tiene implicaciones en accesibilidad, compatibilidad y la integración con herramientas como Angular Material.

```typescript
// Ejemplo: componente de reset global que necesita afectar todo el DOM
import { Component, ViewEncapsulation } from '@angular/core';

@Component({
  selector: 'app-estilos-base',
  standalone: true,
  template: '',                           // No tiene template visual
  styles: [`
    *, *::before, *::after { box-sizing: border-box; }
    body { margin: 0; font-family: 'Inter', sans-serif; }
  `],
  encapsulation: ViewEncapsulation.None   // Necesario para que afecte al documento
})
export class EstilosBaseComponent {}
```

## Selectores especiales: :host y :host-context

Dentro de un componente con encapsulación emulada (o ShadowDom), Angular proporciona dos pseudoclases especiales:

**`:host`** selecciona el elemento raíz del componente, es decir, el propio `<app-mi-componente>`. Úsalo para estilizar el elemento host en lugar de añadir un `<div>` wrapper innecesario:

```typescript
@Component({
  selector: 'app-chip',
  standalone: true,
  template: `<span>{{ etiqueta }}</span>`,
  styles: [`
    /* Estiliza el <app-chip> directamente */
    :host {
      display: inline-flex;
      align-items: center;
      padding: 4px 12px;
      border-radius: 16px;
      background: #e0e0e0;
    }

    /* :host con condición: aplica cuando el host tiene la clase "activo" */
    :host(.activo) {
      background: #1976d2;
      color: white;
    }

    /* :host con condición: aplica cuando el host tiene el atributo disabled */
    :host([disabled]) {
      opacity: 0.5;
      pointer-events: none;
    }
  `]
})
export class ChipComponent {
  etiqueta: string = 'Angular';
}
```

**`:host-context(selector)`** selecciona el host cuando algún ancestro en el DOM externo coincide con el selector dado. Es útil para adaptar el componente al tema del contexto en que se inserta, aunque su uso ha disminuido con la popularización de las CSS custom properties:

```typescript
styles: [`
  /* Cuando el componente está dentro de un contenedor con tema oscuro */
  :host-context(.tema-oscuro) {
    background: #424242;
    color: #ffffff;
  }
`]
```

## Variables CSS personalizadas para theming

Las CSS custom properties (variables CSS) son la forma moderna y recomendada de implementar theming en componentes Angular. A diferencia de `:host-context`, las custom properties atraviesan las barreras de encapsulación naturalmente, tanto en el modo Emulated como en ShadowDom. El componente las consume; quien lo usa define los valores.

```typescript
// archivo: boton-primario.component.ts
import { Component, Input, booleanAttribute, ViewEncapsulation } from '@angular/core';

@Component({
  selector: 'app-boton-primario',
  standalone: true,
  template: `
    <button [disabled]="deshabilitado">
      <ng-content />
    </button>
  `,
  styles: [`
    :host {
      /* Valores por defecto usando var() con fallback */
      --color-fondo: #1976d2;
      --color-texto: #ffffff;
      --radio-borde: 4px;
    }

    button {
      background-color: var(--color-fondo);
      color: var(--color-texto);
      border: none;
      border-radius: var(--radio-borde);
      padding: 8px 20px;
      cursor: pointer;
      transition: opacity 0.2s;
    }

    button:hover:not(:disabled) { opacity: 0.88; }
    button:disabled { opacity: 0.4; cursor: default; }
  `],
  encapsulation: ViewEncapsulation.Emulated
})
export class BotonPrimarioComponent {
  @Input({ transform: booleanAttribute }) deshabilitado: boolean = false;
}
```

El componente que lo usa puede sobreescribir el tema simplemente cambiando las variables CSS:

```html
<!-- Botón con colores del tema por defecto -->
<app-boton-primario>Guardar</app-boton-primario>

<!-- Botón con tema personalizado sin tocar el componente -->
<app-boton-primario style="--color-fondo: #e53935; --radio-borde: 24px">
  Eliminar
</app-boton-primario>
```

Este patrón hace que el componente sea extremadamente flexible: los consumidores controlan el aspecto visual sin necesidad de `ViewEncapsulation.None` ni de `::ng-deep`.

## El selector ::ng-deep y por qué evitarlo

`::ng-deep` es un selector especial que "rompe" la encapsulación y permite que un estilo del componente padre penetre en los estilos del componente hijo. Aunque funciona, está marcado como obsoleto desde hace varias versiones y eventualmente dejará de funcionar cuando los navegadores desechen los combinadores Shadow DOM:

```css
/* EVITAR: ::ng-deep es obsoleto */
:host ::ng-deep .mat-button { color: red; }

/* PREFERIR: usar CSS custom properties que el componente hijo ya exponga */
app-mi-componente { --color-boton: red; }
```

Si estás usando `::ng-deep` para estilizar un componente de Angular Material o de una librería de terceros, investiga primero si expone variables CSS o un sistema de theming. Angular Material 3, por ejemplo, está completamente construido sobre CSS tokens personalizados.

## Puntos clave

- Angular usa encapsulación emulada por defecto: añade atributos únicos a los elementos y transforma los selectores CSS para que los estilos sean privados al componente.
- `ViewEncapsulation.None` inyecta los estilos como globales; úsalo solo cuando sea estrictamente necesario.
- `ViewEncapsulation.ShadowDom` usa el Shadow DOM nativo del navegador para un aislamiento real.
- `:host` permite estilizar el elemento raíz del componente; `:host(.clase)` aplica estilos condicionales cuando el host tiene una clase específica.
- Las CSS custom properties son la forma correcta de exponer puntos de personalización en un componente: atraviesan la encapsulación de manera controlada y sin efectos secundarios.

## ¿Qué sigue?

El Capítulo 4 lleva los componentes al siguiente nivel: exploraremos cómo acceder al DOM y a componentes hijos desde la clase TypeScript con `@ViewChild` y `@ViewChildren`, y cómo proyectar contenido externo con `ng-content`.
