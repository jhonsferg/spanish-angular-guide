# Capítulo 6 - Parte 3: Creando directivas de atributo personalizadas

> **Parte 3 de 4** · Capítulo 6 · PARTE III - Templates y Directivas

Las directivas de atributo son uno de los mecanismos más elegantes de Angular para encapsular comportamiento que no pertenece a un componente completo. Cuando queremos que un elemento HTML cambie su apariencia o comportamiento según alguna lógica reutilizable, sin necesidad de envolverlo en un componente nuevo, las directivas de atributo son la herramienta correcta. A diferencia de las directivas estructurales, no modifican el DOM; trabajan sobre el elemento que ya existe, enriqueciéndolo.

## La anatomía de una directiva de atributo

Toda directiva de atributo comienza con el decorador `@Directive` y un selector de atributo. El selector en corchetes `[appNombre]` indica a Angular que esta directiva debe activarse cada vez que encuentre ese atributo en el template, sin importar en qué elemento HTML aparezca.

```typescript
// directivas/resaltado.directive.ts
import { Directive, ElementRef, Renderer2, inject } from '@angular/core';

@Directive({
  selector: '[appResaltado]', // Se activa en cualquier elemento con este atributo
  standalone: true,
})
export class ResaltadoDirective {
  // Renderer2 es la forma correcta de manipular el DOM en Angular
  // Evita manipular ElementRef.nativeElement directamente
  private elementoRef = inject(ElementRef);
  private renderer = inject(Renderer2);

  constructor() {
    // Aplicamos un estilo inicial al elemento host
    this.renderer.setStyle(
      this.elementoRef.nativeElement,
      'cursor',
      'pointer'
    );
  }
}
```

La razón por la que usamos `Renderer2` en lugar de manipular `elementoRef.nativeElement` directamente es importante: `Renderer2` abstrae la capa de renderizado. Esto significa que la misma directiva funciona correctamente en entornos sin DOM real, como en Angular Universal (SSR) o en Web Workers. Manipular el DOM directamente con JavaScript nativo rompe esa abstracción y produce errores difíciles de depurar en renderizado del lado del servidor.

## Respondiendo a eventos con @HostListener

Para que nuestra directiva reaccione a eventos del DOM sobre el elemento host, usamos el decorador `@HostListener`. Cada método decorado con `@HostListener('evento')` se convierte en un manejador que Angular registra y desregistra automáticamente, sin que tengamos que preocuparnos por fugas de memoria.

```typescript
// directivas/resaltado.directive.ts - versión completa
import {
  Directive, ElementRef, Renderer2, HostListener, inject, input
} from '@angular/core';

@Directive({
  selector: '[appResaltado]',
  standalone: true,
})
export class ResaltadoDirective {
  // Input con signal API - permite configurar el color desde el template
  colorResaltado = input<string>('yellow'); // Valor por defecto: amarillo

  private elementoRef = inject(ElementRef);
  private renderer = inject(Renderer2);

  // Se ejecuta cuando el mouse entra al elemento
  @HostListener('mouseenter')
  alEntrarMouse(): void {
    this.renderer.setStyle(
      this.elementoRef.nativeElement,
      'background-color',
      this.colorResaltado() // Accedemos al signal con ()
    );
  }

  // Se ejecuta cuando el mouse sale del elemento
  @HostListener('mouseleave')
  alSalirMouse(): void {
    this.renderer.removeStyle(
      this.elementoRef.nativeElement,
      'background-color'
    );
  }
}
```

Nótese el uso de `input()` de la API de Signals en lugar del decorador `@Input()`. Desde Angular 17, esta es la forma recomendada de declarar inputs en directivas y componentes. El valor es un Signal, por lo que accedemos a él llamándolo como función: `this.colorResaltado()`.

El método `renderer.removeStyle()` elimina el estilo completamente en lugar de establecerlo a vacío, lo cual es más limpio y evita dejar atributos `style` vacíos en el DOM.

## Inputs en directivas: configuración desde el template

Una directiva sin inputs es útil, pero una directiva con inputs es versátil. Podemos configurar su comportamiento desde el template usando la sintaxis de binding estándar de Angular.

```html
<!-- Uso básico - usa el color por defecto (yellow) -->
<p appResaltado>Párrafo resaltable con color por defecto</p>

<!-- Uso con color personalizado vía binding -->
<p [appResaltado]="'lightblue'">Párrafo con resaltado azul</p>

<!-- Usando una variable del componente -->
<p [appResaltado]="colorElegidoPorUsuario">Resaltado dinámico</p>

<!-- Con alias: el nombre del atributo igual al selector -->
<p appResaltado colorResaltado="coral">Con input explícito</p>
```

Podemos hacer que el input principal tenga el mismo nombre que el selector de la directiva usando la opción `alias`. Esto permite la sintaxis `[appResaltado]="'coral'"` donde el valor del atributo selector es directamente el valor del input:

```typescript
// Input con alias que coincide con el selector
colorResaltado = input<string>('yellow', {
  alias: 'appResaltado' // Permite: [appResaltado]="'coral'"
});
```

Con este alias, el template `<p [appResaltado]="'coral'">` funciona: el atributo selector también sirve como input del color, lo que simplifica la sintaxis para el consumidor de la directiva.

## Ejemplo completo: directiva appResaltado en un componente real

Veamos cómo integrar la directiva en un componente standalone completo, que representa el caso de uso real más común.

```typescript
// features/catalogo/lista-productos.component.ts
import { Component, signal } from '@angular/core';
import { ResaltadoDirective } from '../../directivas/resaltado.directive';

interface Producto {
  id: number;
  nombre: string;
  precio: number;
}

@Component({
  selector: 'app-lista-productos',
  standalone: true,
  imports: [ResaltadoDirective], // Importamos la directiva como standalone
  template: `
    <ul class="lista-productos">
      @for (producto of productos(); track producto.id) {
        <li
          appResaltado
          [colorResaltado]="colorActivo()"
          class="item-producto"
        >
          {{ producto.nombre }} - {{ producto.precio | currency:'COP' }}
        </li>
      }
    </ul>

    <div class="selector-color">
      <label>Color de resaltado:</label>
      @for (color of coloresDisponibles; track color) {
        <button
          [style.background-color]="color"
          (click)="colorActivo.set(color)"
        >{{ color }}</button>
      }
    </div>
  `,
})
export class ListaProductosComponent {
  productos = signal<Producto[]>([
    { id: 1, nombre: 'Teclado mecánico', precio: 180000 },
    { id: 2, nombre: 'Monitor 4K', precio: 1250000 },
    { id: 3, nombre: 'Mouse inalámbrico', precio: 95000 },
  ]);

  colorActivo = signal<string>('lightyellow');
  coloresDisponibles = ['lightyellow', 'lightblue', 'lightgreen', 'lightsalmon'];
}
```

Este ejemplo muestra la directiva en acción con un color reactivo: cuando el usuario selecciona un color, el signal `colorActivo` se actualiza, y Angular propaga automáticamente el nuevo valor a todos los inputs `colorResaltado` de los items de la lista.

## Por qué Renderer2 y no nativeElement

Vale la pena reforzar este punto porque es un error frecuente en bases de código Angular. Manipular `elementoRef.nativeElement.style.backgroundColor = 'yellow'` funciona en el navegador, pero tiene consecuencias en otros contextos.

En una aplicación con renderizado del lado del servidor (Angular Universal / SSR), no existe un DOM real en Node.js. El acceso directo a `nativeElement` lanza errores en ese entorno. `Renderer2` está diseñado para ser sustituido por una implementación del servidor que traduce las operaciones de DOM a HTML serializable.

Además, en contextos de Content Security Policy estricta, manipular estilos directamente puede ser bloqueado por el navegador. `Renderer2` aplica las operaciones de forma compatible con CSP cuando Angular está configurado correctamente.

## Puntos clave

- El selector `[appNombre]` en corchetes define una directiva de atributo que se aplica sobre elementos existentes
- `Renderer2` es el mecanismo correcto para manipular el DOM: abstrae el entorno de renderizado y funciona en SSR
- `@HostListener('evento')` registra manejadores de eventos sobre el elemento host, con limpieza automática
- La API `input()` de Signals reemplaza `@Input()` en Angular 17+ y devuelve un Signal que se lee con `()`
- Las directivas standalone se importan directamente en el array `imports` del componente que las usa

## ¿Qué sigue?

En la Parte 4 llevamos las directivas más allá del atributo: exploramos `@HostBinding` para enlazar propiedades del host y construimos nuestra primera directiva estructural personalizada con `TemplateRef` y `ViewContainerRef`.
