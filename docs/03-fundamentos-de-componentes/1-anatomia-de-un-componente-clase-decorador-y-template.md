# Capítulo 3 - Parte 1: Anatomía de un componente: clase, decorador y template

> **Parte 1 de 4** · Capítulo 3 · PARTE II - Componentes: El Alma de Angular

Un componente en Angular es la unidad mínima de interfaz de usuario. Todo lo que el usuario ve y con lo que interactúa, desde un botón hasta una página completa, es un componente. Pero más allá de ser "un fragmento de HTML", un componente combina tres piezas que trabajan juntas: la lógica en TypeScript, la plantilla HTML y los estilos CSS. Entender cómo estas tres partes se ensamblan es el punto de partida para dominar Angular.

## La clase TypeScript: el cerebro del componente

La clase TypeScript es donde vive la lógica del componente: las propiedades que almacenan datos, los métodos que responden a eventos del usuario, y las dependencias que se inyectan. Esta clase es simplemente una clase TypeScript estándar; Angular la convierte en componente gracias al decorador que la precede.

```typescript
// archivo: tarjeta-producto.component.ts
import { Component } from '@angular/core';
import { CurrencyPipe } from '@angular/common';

@Component({
  selector: 'app-tarjeta-producto',
  standalone: true,
  imports: [CurrencyPipe],         // Pipes y otros componentes que usa el template
  templateUrl: './tarjeta-producto.component.html',
  styleUrl: './tarjeta-producto.component.css'
})
export class TarjetaProductoComponent {
  nombre: string = 'Monitor Ultrawide';
  precio: number = 599.99;
  disponible: boolean = true;

  agregarAlCarrito(): void {
    console.log(`Agregando "${this.nombre}" al carrito`);
  }
}
```

La clase exporta el componente para que pueda ser importado por otros componentes. Las propiedades públicas (`nombre`, `precio`, `disponible`) son automáticamente accesibles desde el template, y los métodos pueden enlazarse a eventos del DOM. Nada de magia: es TypeScript puro con la adición del decorador.

## El decorador `@Component`: la firma del componente

El decorador `@Component` es lo que transforma una clase TypeScript ordinaria en un componente de Angular. Actúa como un descriptor de metadatos que Angular lee en tiempo de compilación para saber cómo debe comportarse esa clase dentro del framework.

Las propiedades más importantes del decorador son estas:

**`selector`**: define el nombre del elemento HTML personalizado con el que se usará el componente. Por convención, siempre lleva el prefijo `app-` (o el prefijo del proyecto) para evitar colisiones con elementos HTML nativos. Cuando Angular encuentra `<app-tarjeta-producto>` en cualquier template, sabe que debe instanciar este componente.

**`template` o `templateUrl`**: define el HTML del componente. Con `template` se escribe el HTML directamente en el decorador (útil para plantillas muy cortas), y con `templateUrl` se apunta a un archivo externo `.html`. Ambas son equivalentes en funcionalidad; la diferencia es organizativa.

**`styles` o `styleUrl` / `styleUrls`**: funciona igual que el template. Con `styles` se escriben los estilos directamente como un array de strings, y con `styleUrl` (singular, Angular 17+) o `styleUrls` (array) se apuntan a archivos externos. Los estilos de un componente están encapsulados por defecto y no afectan al resto de la aplicación (exploraremos esto en la Parte 4).

**`standalone`**: esta propiedad, obligatoria en Angular 17+ para el enfoque moderno, indica que el componente no pertenece a ningún `NgModule`. Los componentes standalone gestionan sus propias dependencias a través del array `imports`, lo que los hace más portables y fáciles de entender de forma aislada.

**`imports`**: exclusivo de los componentes standalone, este array declara los otros componentes, directivas y pipes que el template de este componente necesita para funcionar. Si el template usa `CurrencyPipe`, `RouterLink` o un componente hijo, deben listarse aquí.

```typescript
// Ejemplo mostrando las formas alternativas de template y estilos
import { Component } from '@angular/core';

@Component({
  selector: 'app-insignia',
  standalone: true,
  // Template inline: adecuado para plantillas pequeñas de 2-5 líneas
  template: `
    <span class="insignia" [class.activa]="activa">
      {{ etiqueta }}
    </span>
  `,
  // Estilos inline: el array admite múltiples strings de CSS
  styles: [`
    .insignia { padding: 4px 8px; border-radius: 4px; }
    .activa { background-color: #4caf50; color: white; }
  `]
})
export class InsigniaComponent {
  etiqueta: string = 'Nuevo';
  activa: boolean = true;
}
```

## El template HTML: lo que el usuario ve

El template define la estructura visual del componente. En Angular, el HTML del template es HTML estándar extendido con sintaxis propia del framework: interpolación `{{ }}`, binding de propiedades `[propiedad]`, binding de eventos `(evento)`, y el nuevo bloque de control de flujo (`@if`, `@for`).

El template tiene acceso directo a todas las propiedades y métodos públicos de la clase. No es necesario ningún paso de configuración adicional: si la propiedad existe en la clase, el template puede leerla.

```html
<!-- archivo: tarjeta-producto.component.html -->
<article class="tarjeta">
  <h2>{{ nombre }}</h2>

  <!-- Interpolación: muestra el valor de la propiedad "precio" -->
  <p class="precio">{{ precio | currency:'USD' }}</p>

  <!-- Property binding: aplica o no la clase CSS según el valor booleano -->
  <span [class.disponible]="disponible">
    {{ disponible ? 'En stock' : 'Agotado' }}
  </span>

  <!-- Event binding: llama al método cuando el usuario hace clic -->
  <button (click)="agregarAlCarrito()" [disabled]="!disponible">
    Agregar al carrito
  </button>
</article>
```

El template conoce el estado actual del componente en todo momento. Cuando `disponible` cambia de `true` a `false`, Angular actualiza automáticamente el DOM: deshabilita el botón y actualiza el texto del span. Esta sincronización reactiva entre clase y template es el núcleo del modelo de programación de Angular.

## Estilos: encapsulados por diseño

Los estilos declarados en `styles` o `styleUrl` aplican exclusivamente al componente que los declara. Angular logra esto añadiendo un atributo único al elemento host y a todos los elementos del template en tiempo de compilación. El resultado es que `.tarjeta { ... }` en `TarjetaProductoComponent` nunca colisionará con otra clase `.tarjeta` definida en cualquier otro lugar de la aplicación. Este mecanismo se denomina encapsulación de estilos, y lo exploraremos en detalle en la Parte 4 de este capítulo.

## Ejemplo completo: un componente standalone funcional

Veamos un componente de contador que integra las tres partes: la clase gestiona el estado, el decorador lo conecta todo, y el template refleja ese estado de forma reactiva.

```typescript
// archivo: contador.component.ts
import { Component } from '@angular/core';
import { NgClass } from '@angular/common';

@Component({
  selector: 'app-contador',
  standalone: true,
  imports: [NgClass],
  template: `
    <div class="contador" [ngClass]="{ negativo: valor < 0 }">
      <button (click)="decrementar()">−</button>
      <span class="valor">{{ valor }}</span>
      <button (click)="incrementar()">+</button>
      <button (click)="reiniciar()">Reiniciar</button>
    </div>
  `,
  styles: [`
    .contador { display: flex; gap: 8px; align-items: center; }
    .valor { min-width: 3ch; text-align: center; font-size: 1.5rem; }
    .negativo .valor { color: #e53935; }
  `]
})
export class ContadorComponent {
  valor: number = 0;

  incrementar(): void { this.valor++; }
  decrementar(): void { this.valor--; }
  reiniciar(): void { this.valor = 0; }
}
```

Este componente es completamente autónomo. Para usarlo en cualquier otro componente standalone, basta con añadirlo al array `imports` del componente padre y escribir `<app-contador />` en su template. No necesita ningún módulo intermediario.

## Puntos clave

- Un componente Angular está compuesto por tres partes: clase TypeScript (lógica), template HTML (vista) y estilos CSS (presentación).
- El decorador `@Component` proporciona los metadatos que Angular necesita: `selector`, `template`/`templateUrl`, `styles`/`styleUrl` y `standalone`.
- En Angular 17+, los componentes standalone son el estándar: declaran sus propias dependencias en el array `imports` y no pertenecen a ningún `NgModule`.
- El template tiene acceso directo a las propiedades y métodos públicos de la clase sin configuración adicional.
- Los estilos de un componente están encapsulados por defecto y no afectan a otros componentes de la aplicación.

## ¿Qué sigue?

En la Parte 2 exploramos el ciclo de vida del componente: los ocho hooks que Angular llama en momentos clave, y cómo sacarles partido para inicializar datos, reaccionar a cambios y limpiar recursos.
