# Capítulo 30 - Parte 2: Construyendo componentes UI con clases utilitarias

> **Parte 2 de 4** · Capítulo 30 · PARTE XIII - Librerías Esenciales del Ecosistema

Una vez que Tailwind está instalado, la pregunta natural es: ¿cómo organizo mis estilos para que el código no se convierta en un caos de clases interminables? En esta parte veamos la filosofía detrás de Tailwind, cómo integrarla de forma idiomática con Angular, y cuándo tiene sentido extraer clases reutilizables.

## Utility-first vs. component-based CSS

La filosofía **utility-first** propone que cada clase hace exactamente una cosa. En lugar de crear una clase `.tarjeta` con múltiples propiedades CSS, componemos el estilo en el template usando muchas clases pequeñas:

```html
<!-- Enfoque utility-first -->
<div class="flex flex-col gap-4 p-6 bg-white rounded-xl shadow-md border border-gray-100">
  Contenido
</div>
```

La crítica más común es que los templates se "ensucian". La respuesta es que esa complejidad siempre existió, solo estaba escondida en un archivo CSS separado. La ventaja es que **todo el contexto visual está en un solo lugar**, sin saltar entre archivos.

El enfoque **component-based** tradicional abstrae los estilos detrás de nombres semánticos (`.tarjeta`, `.boton-primario`). Tailwind no elimina este enfoque, lo complementa: cuando un patrón de clases se repite mucho, lo extraemos.

En Angular, la abstracción natural ya existe: **el componente**. Si `.tarjeta` se repite, la encapsulamos en `<app-tarjeta>` y las clases quedan en un solo template. No necesitamos `@apply` para cada caso.

## Clases en templates de Angular

Veamos cómo trabajar con clases Tailwind en los distintos escenarios de Angular:

```typescript
// card-producto.component.ts
import { Component, Input } from '@angular/core';
import { CurrencyPipe } from '@angular/common';

interface Producto {
  nombre: string;
  precio: number;
  imagen: string;
  enStock: boolean;
}

@Component({
  selector: 'app-card-producto',
  standalone: true,
  imports: [CurrencyPipe],
  template: `
    <article class="flex flex-col bg-white rounded-xl shadow-sm border
                    border-gray-200 overflow-hidden hover:shadow-md
                    transition-shadow duration-200">
      <img
        [src]="producto.imagen"
        [alt]="producto.nombre"
        class="w-full h-48 object-cover"
      />
      <div class="flex flex-col gap-2 p-4">
        <h3 class="text-lg font-semibold text-gray-900 line-clamp-2">
          {{ producto.nombre }}
        </h3>
        <p class="text-2xl font-bold text-blue-600">
          {{ producto.precio | currency:'COP':'symbol':'1.0-0' }}
        </p>
        <app-insignia-estado [enStock]="producto.enStock" />
      </div>
    </article>
  `
})
export class CardProductoComponent {
  @Input({ required: true }) producto!: Producto;
}
```

Notemos que usamos `class` estático para los estilos base y reservamos el binding dinámico para los casos donde el estilo cambia según datos.

## `[class]` binding vs `[ngClass]`

Angular ofrece dos formas de aplicar clases condicionalmente. Veamos cuándo usar cada una:

```typescript
// insignia-estado.component.ts
import { Component, Input } from '@angular/core';

@Component({
  selector: 'app-insignia-estado',
  standalone: true,
  template: `
    <!-- Opción 1: class binding con expresión ternaria (simple) -->
    <span [class]="claseInsignia">
      {{ enStock ? 'Disponible' : 'Agotado' }}
    </span>

    <!-- Opción 2: ngClass con objeto (múltiples condiciones) -->
    <span [ngClass]="{
      'bg-green-100 text-green-800': enStock,
      'bg-red-100 text-red-800': !enStock,
      'px-3 py-1 rounded-full text-sm font-medium': true
    }">
      {{ enStock ? 'Disponible' : 'Agotado' }}
    </span>
  `
})
export class InsigniaEstadoComponent {
  @Input({ required: true }) enStock!: boolean;

  get claseInsignia(): string {
    const base = 'px-3 py-1 rounded-full text-sm font-medium';
    return enStock
      ? `${base} bg-green-100 text-green-800`
      : `${base} bg-red-100 text-red-800`;
  }
}
```

La recomendación general:
- **`[class]="expresion"`**: para una sola condición o cuando construimos la clase completa en el componente.
- **`[ngClass]`**: cuando manejamos múltiples clases condicionales independientes en el template.
- **`class` estático + `[class.nombre]` individual**: para togglear una sola clase.

```html
<!-- Toggle de una clase individual -->
<button
  class="px-4 py-2 rounded-lg font-medium transition-colors"
  [class.bg-blue-600]="activo"
  [class.text-white]="activo"
  [class.bg-gray-100]="!activo"
  [class.text-gray-700]="!activo"
>
  Filtrar
</button>
```

## Extracción con `@apply` en SCSS

Cuando un patrón de clases aparece en **múltiples templates** y no queremos repetirlo, o cuando trabajamos con elementos que no podemos controlar directamente (como markdown renderizado), `@apply` es la herramienta correcta:

```scss
/* src/styles.scss */
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer components {
  .btn-primario {
    @apply bg-blue-600 text-white px-4 py-2 rounded-lg font-medium
           hover:bg-blue-700 active:bg-blue-800
           transition-colors duration-150
           disabled:opacity-50 disabled:cursor-not-allowed;
  }

  .btn-secundario {
    @apply bg-white text-blue-600 px-4 py-2 rounded-lg font-medium
           border border-blue-600
           hover:bg-blue-50
           transition-colors duration-150;
  }

  .input-campo {
    @apply w-full px-3 py-2 border border-gray-300 rounded-lg
           text-gray-900 placeholder-gray-400
           focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent
           disabled:bg-gray-50 disabled:text-gray-500;
  }
}
```

El uso de `@layer components` es importante: coloca las clases en la capa correcta de la cascada CSS, entre `base` y `utilities`. Esto significa que las clases utilitarias siempre pueden sobrescribir los componentes cuando necesitemos hacer ajustes puntuales.

## Componente `AlertaMensaje` completo

Veamos un ejemplo más elaborado que combina todo lo anterior:

```typescript
// alerta-mensaje.component.ts
import { Component, Input, Output, EventEmitter } from '@angular/core';

type TipoAlerta = 'info' | 'exito' | 'advertencia' | 'error';

interface ConfigAlerta {
  icono: string;
  claseFondo: string;
  claseTexto: string;
  claseBorde: string;
}

@Component({
  selector: 'app-alerta-mensaje',
  standalone: true,
  template: `
    <div
      role="alert"
      [class]="claseContenedor"
    >
      <span class="text-xl" [attr.aria-hidden]="true">
        {{ config.icono }}
      </span>
      <p class="flex-1 text-sm font-medium" [class]="config.claseTexto">
        {{ mensaje }}
      </p>
      @if (descartable) {
        <button
          (click)="descartar.emit()"
          class="ml-auto -mr-1 p-1 rounded-md opacity-60 hover:opacity-100
                 transition-opacity focus:outline-none focus:ring-2"
          [class]="config.claseTexto"
          aria-label="Cerrar alerta"
        >
          ✕
        </button>
      }
    </div>
  `
})
export class AlertaMensajeComponent {
  @Input({ required: true }) mensaje!: string;
  @Input() tipo: TipoAlerta = 'info';
  @Input() descartable = false;
  @Output() descartar = new EventEmitter<void>();

  private readonly configuraciones: Record<TipoAlerta, ConfigAlerta> = {
    info:        { icono: 'ℹ️', claseFondo: 'bg-blue-50',   claseTexto: 'text-blue-800',  claseBorde: 'border-blue-200' },
    exito:       { icono: '✅', claseFondo: 'bg-green-50',  claseTexto: 'text-green-800', claseBorde: 'border-green-200' },
    advertencia: { icono: '⚠️', claseFondo: 'bg-yellow-50', claseTexto: 'text-yellow-800',claseBorde: 'border-yellow-200' },
    error:       { icono: '❌', claseFondo: 'bg-red-50',    claseTexto: 'text-red-800',   claseBorde: 'border-red-200' },
  };

  get config(): ConfigAlerta {
    return this.configuraciones[this.tipo];
  }

  get claseContenedor(): string {
    return `flex items-start gap-3 p-4 rounded-lg border
            ${this.config.claseFondo} ${this.config.claseBorde}`;
  }
}
```

Este enfoque mantiene las clases completas (sin interpolación parcial), lo que garantiza que el purger de Tailwind las detecte correctamente.

## Puntos clave

- La filosofía utility-first no "ensucia" el código, simplemente lleva la complejidad visual al lugar donde corresponde: el template.
- En Angular, el componente ya es la abstracción natural. No necesitamos `@apply` para cada patrón repetido.
- Usar `[class]` para condiciones simples y `[ngClass]` para múltiples condiciones independientes en el template.
- Reservar `@apply` con `@layer components` para clases que se usan en muchos templates o en HTML que no controlamos directamente.
- Siempre usar clases completas en las cadenas de texto, nunca construir nombres de clase parciales con interpolación.

## ¿Qué sigue?

En la siguiente parte exploraremos el sistema responsive de Tailwind y cómo implementar Dark Mode de forma elegante con signals de Angular.
