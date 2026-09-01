# Capítulo 3 - Parte 3: Comunicación con @Input y @Output

> **Parte 3 de 4** · Capítulo 3 · PARTE II - Componentes: El Alma de Angular

La reutilización real de un componente exige que pueda adaptarse a diferentes contextos. Un componente de contador que siempre empieza en cero y solo muestra su valor interno tiene utilidad limitada. Uno que acepta un valor inicial, un máximo y que notifica al padre cuando cambia de valor, puede reutilizarse en formularios, configuradores de cantidad en un carrito, reproductores de media y decenas de contextos más. `@Input()` y `@Output()` son el mecanismo de Angular para construir ese canal de comunicación entre componentes padre e hijo.

## @Input: el flujo de datos hacia abajo

El decorador `@Input()` marca una propiedad de la clase como un "puerto de entrada" que el componente padre puede configurar desde su template. El flujo siempre es unidireccional: de padre a hijo. El hijo no puede (ni debe) modificar directamente el valor que recibió.

```typescript
// archivo: etiqueta-estado.component.ts
import { Component, Input } from '@angular/core';
import { NgClass } from '@angular/common';

type EstadoPedido = 'pendiente' | 'enviado' | 'entregado' | 'cancelado';

@Component({
  selector: 'app-etiqueta-estado',
  standalone: true,
  imports: [NgClass],
  template: `
    <span class="etiqueta" [ngClass]="estado">
      {{ estado | uppercase }}
    </span>
  `,
  styles: [`
    .etiqueta { padding: 2px 10px; border-radius: 12px; font-size: 0.8rem; }
    .pendiente  { background: #fff9c4; color: #f57f17; }
    .enviado    { background: #e3f2fd; color: #1565c0; }
    .entregado  { background: #e8f5e9; color: #2e7d32; }
    .cancelado  { background: #fce4ec; color: #b71c1c; }
  `]
})
export class EtiquetaEstadoComponent {
  // El padre puede pasar cualquier valor de EstadoPedido
  @Input() estado: EstadoPedido = 'pendiente';
}
```

El componente padre lo usa así:

```html
<!-- En el template del componente padre -->
<app-etiqueta-estado [estado]="pedido.estado" />
<app-etiqueta-estado estado="enviado" />  <!-- También funciona con valor literal -->
```

### Alias y transformaciones de @Input

`@Input()` acepta opciones adicionales. La más útil en Angular 16+ es `transform`, que permite transformar el valor entrante antes de asignarlo a la propiedad. El caso de uso más frecuente es convertir el atributo HTML `disabled` (que llega como string vacío `""` o como la cadena `"true"`) a un booleano real:

```typescript
import { Component, Input, booleanAttribute, numberAttribute } from '@angular/core';

@Component({
  selector: 'app-boton-accion',
  standalone: true,
  template: `
    <button [disabled]="deshabilitado" [style.font-size.px]="tamano">
      <ng-content />
    </button>
  `
})
export class BotonAccionComponent {
  // booleanAttribute convierte "" o "true" -> true, "false" o ausencia -> false
  @Input({ transform: booleanAttribute }) deshabilitado: boolean = false;

  // numberAttribute convierte "16" -> 16
  @Input({ transform: numberAttribute }) tamano: number = 14;

  // alias: el padre usa [etiqueta] pero internamente es "texto"
  @Input({ alias: 'etiqueta' }) texto: string = 'Aceptar';
}
```

Con estas transformaciones, el padre puede escribir `<app-boton-accion deshabilitado tamano="18">` en lugar de tener que pasar `[deshabilitado]="true"`. Es la misma ergonomía que tienen los elementos HTML nativos.

## @Output: el flujo de eventos hacia arriba

Mientras `@Input()` lleva datos del padre al hijo, `@Output()` permite al hijo notificar al padre que algo ocurrió. El decorador `@Output()` marca una propiedad de tipo `EventEmitter<T>`, que funciona como un Observable especial diseñado para emitir eventos dentro del template.

```typescript
// archivo: campo-busqueda.component.ts
import { Component, Input, Output, EventEmitter } from '@angular/core';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-campo-busqueda',
  standalone: true,
  imports: [FormsModule],
  template: `
    <div class="busqueda">
      <input
        type="search"
        [placeholder]="placeholder"
        [(ngModel)]="termino"
        (input)="alEscribir()"
      />
      <button (click)="limpiar()">✕</button>
    </div>
  `
})
export class CampoBusquedaComponent {
  @Input() placeholder: string = 'Buscar...';

  // El padre escuchará este evento con (buscar)="handler($event)"
  @Output() buscar = new EventEmitter<string>();

  // Este evento no emite datos: solo notifica que ocurrió la acción
  @Output() limpiar$ = new EventEmitter<void>();

  termino: string = '';

  alEscribir(): void {
    this.buscar.emit(this.termino);   // Emite el string al padre
  }

  limpiar(): void {
    this.termino = '';
    this.buscar.emit('');             // Notifica al padre que se limpió
    this.limpiar$.emit();             // Evento adicional sin datos
  }
}
```

El padre escucha el evento con la sintaxis de event binding:

```html
<app-campo-busqueda
  placeholder="Buscar productos..."
  (buscar)="filtrarProductos($event)"
  (limpiar$)="reiniciarFiltros()"
/>
```

`$event` contiene el valor que el hijo pasó a `emit()`. En este caso es un `string`, pero puede ser cualquier tipo: un objeto, un número, o `void` si el evento no transporta datos.

## Ejemplo bidireccional completo: componente de contador

Integremos ambos decoradores en un ejemplo real que muestra el patrón padre-hijo completo. El componente `ContadorComponent` recibe un valor inicial y un máximo desde el padre, y emite cambios hacia arriba cada vez que el usuario interactúa.

```typescript
// archivo: contador.component.ts
import { Component, Input, Output, EventEmitter, OnInit, numberAttribute } from '@angular/core';

@Component({
  selector: 'app-contador',
  standalone: true,
  template: `
    <div class="contador">
      <button (click)="decrementar()" [disabled]="valor <= minimo">−</button>
      <span class="valor">{{ valor }}</span>
      <button (click)="incrementar()" [disabled]="valor >= maximo">+</button>
    </div>
  `,
  styles: [`
    .contador { display: flex; gap: 12px; align-items: center; }
    .valor { min-width: 2ch; text-align: center; font-size: 1.4rem; font-weight: bold; }
    button { width: 32px; height: 32px; border-radius: 50%; cursor: pointer; }
  `]
})
export class ContadorComponent implements OnInit {
  @Input({ transform: numberAttribute }) valorInicial: number = 0;
  @Input({ transform: numberAttribute }) maximo: number = 10;
  @Input({ transform: numberAttribute }) minimo: number = 0;

  // Emite el nuevo valor cada vez que cambia
  @Output() valorCambiado = new EventEmitter<number>();

  valor: number = 0;

  ngOnInit(): void {
    // Inicializamos el valor interno a partir del @Input
    this.valor = this.valorInicial;
  }

  incrementar(): void {
    if (this.valor < this.maximo) {
      this.valor++;
      this.valorCambiado.emit(this.valor);
    }
  }

  decrementar(): void {
    if (this.valor > this.minimo) {
      this.valor--;
      this.valorCambiado.emit(this.valor);
    }
  }
}
```

El componente padre que lo utiliza:

```typescript
// archivo: configurador-pedido.component.ts
import { Component } from '@angular/core';
import { ContadorComponent } from './contador.component';

@Component({
  selector: 'app-configurador-pedido',
  standalone: true,
  imports: [ContadorComponent],
  template: `
    <h3>Configurar pedido</h3>
    <label>Cantidad:</label>
    <app-contador
      [valorInicial]="cantidad"
      [maximo]="stockDisponible"
      [minimo]="1"
      (valorCambiado)="alCambiarCantidad($event)"
    />
    <p>Total: {{ cantidad }} × {{ precioPorUnidad | currency }} = {{ total | currency }}</p>
  `
})
export class ConfiguradorPedidoComponent {
  cantidad: number = 1;
  stockDisponible: number = 20;
  precioPorUnidad: number = 49.99;

  get total(): number {
    return this.cantidad * this.precioPorUnidad;
  }

  alCambiarCantidad(nuevaCantidad: number): void {
    this.cantidad = nuevaCantidad;
    // Aquí podría también actualizar el carrito, persistir en localStorage, etc.
  }
}
```

El patrón es claro: el padre es el dueño del estado (`cantidad`). El hijo muestra ese estado y notifica cambios, pero nunca modifica la propiedad del padre directamente. Esta separación hace que ambos componentes sean independientes y predecibles: `ContadorComponent` no sabe nada sobre pedidos o precios, solo sabe contar dentro de los límites que le dan.

## Puntos clave

- `@Input()` define propiedades que el componente padre puede configurar desde el template; el flujo de datos es siempre de padre a hijo.
- `@Output()` con `EventEmitter<T>` permite al hijo notificar eventos al padre; el padre los escucha con `(nombreEvento)="handler($event)"`.
- Las opciones `transform` (`booleanAttribute`, `numberAttribute`) convierten valores de atributos HTML a los tipos correctos automáticamente.
- El patrón recomendado es que el padre sea el dueño del estado y el hijo solo lo muestre y emita cambios, nunca mutando el valor recibido directamente.
- El tipo genérico de `EventEmitter<T>` documenta qué tipo de dato transporta el evento; usa `EventEmitter<void>` cuando el evento no necesita datos.

## ¿Qué sigue?

En la Parte 4 cerramos el capítulo estudiando cómo Angular aísla los estilos de cada componente, qué opciones ofrece `ViewEncapsulation` y cómo aprovechar las variables CSS personalizadas para crear un sistema de theming robusto.
