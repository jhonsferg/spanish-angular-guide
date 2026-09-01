# Capítulo 19 - Parte 3: Signal Inputs (`input()`), Model Signals (`model()`) y `output()`

> **Parte 3 de 4** · Capítulo 19 · PARTE X - Angular Signals: Reactividad Moderna

La comunicación entre componentes padre e hijo siempre ha sido uno de los pilares de Angular. El sistema clásico usa `@Input()` para recibir datos del padre y `@Output() EventEmitter` para emitir eventos hacia él. Angular 17.1 introdujo una alternativa basada en Signals: `input()`, `model()` y `output()`. Estas funciones no solo reemplazan la sintaxis de decoradores, sino que integran la comunicación entre componentes directamente en el grafo reactivo de Signals, haciendo que los inputs sean Signals de verdad y que el tracking de cambios sea más preciso.

## `input<T>()` vs `@Input()`: la diferencia fundamental

Con el decorador `@Input()`, Angular inyecta el valor en una propiedad de clase ordinaria. Cuando el padre actualiza ese valor, Angular notifica al hijo a través del ciclo de Change Detection y llama a `ngOnChanges`. El valor en sí es un dato plano, no reactivo: si el hijo quiere reaccionar al cambio, debe implementar la interfaz `OnChanges` o usar un setter.

Con `input()`, el valor entrante se envuelve automáticamente en un Signal de solo lectura. El hijo puede leerlo en cualquier lugar -template, `computed`, `effect`- y Angular sabrá exactamente cuándo ese valor cambió y qué partes del componente dependen de él.

```typescript
import { Component, input, computed } from '@angular/core';

@Component({
  selector: 'app-tarjeta-producto',
  standalone: true,
  template: `
    <div class="tarjeta">
      <h2>{{ nombre() }}</h2>
      <p>Precio: {{ precioFormateado() }}</p>
      @if (enOferta()) {
        <span class="badge">¡Oferta!</span>
      }
    </div>
  `
})
export class TarjetaProductoComponent {
  // Input opcional con valor por defecto
  nombre = input<string>('Sin nombre');

  // Input opcional sin valor por defecto - el tipo es string | undefined
  precio = input<number>();

  // Input requerido: Angular lanza error si el padre no lo provee
  enOferta = input.required<boolean>();

  // computed que depende de un input signal - actualización automática
  precioFormateado = computed(() => {
    const p = this.precio();
    return p !== undefined ? `$${p.toFixed(2)}` : 'Precio no disponible';
  });
}
```

El padre lo usa con la misma sintaxis de property binding que siempre:

```html
<app-tarjeta-producto
  nombre="Teclado Mecánico"
  [precio]="productoSeleccionado.precio"
  [enOferta]="true"
/>
```

### `input.required<T>()`: inputs obligatorios

`input.required<T>()` crea un Signal de entrada que Angular verifica en tiempo de compilación. Si el componente padre no provee el binding, el compilador de templates de Angular reporta un error. A diferencia del input opcional, el tipo del Signal resultante es `T` directamente (no `T | undefined`), porque se garantiza que siempre habrá un valor.

### Transformaciones en input signals

Los inputs basados en Signal aceptan una opción `transform` que aplica una función al valor recibido antes de almacenarlo. Esto es útil para normalizar datos o convertir tipos:

```typescript
import { Component, input } from '@angular/core';
import { booleanAttribute, numberAttribute } from '@angular/core';

@Component({
  selector: 'app-boton',
  standalone: true,
  template: `
    <button [disabled]="deshabilitado()" [style.font-size.px]="tamano()">
      <ng-content />
    </button>
  `
})
export class BotonComponent {
  // booleanAttribute convierte el string "true"/"false"/"" en boolean real
  deshabilitado = input(false, { transform: booleanAttribute });

  // numberAttribute convierte el string "16" en el número 16
  tamano = input(14, { transform: numberAttribute });

  // Alias: en el template el padre lo usa como [btn-label], pero aquí es etiqueta
  etiqueta = input<string>('', { alias: 'btn-label' });
}
```

Las funciones `booleanAttribute` y `numberAttribute` son helpers de `@angular/core` diseñados específicamente para esta tarea. Antes de `input()`, estas transformaciones requerían setters personalizados con `@Input()`.

## `model<T>()`: two-way binding moderno sin EventEmitter

`model()` es la forma moderna de implementar el patrón de two-way binding<sup>1</sup> entre padre e hijo. En el modelo clásico, un componente hijo necesita declarar un `@Input()` y un `@Output()` con el nombre del input seguido del sufijo `Change` -por ejemplo, `valor` y `valorChange`- para que el padre pueda usar `[(valor)]`.

<sup>1</sup> *Two-way binding*: patrón donde el padre pasa un valor al hijo y el hijo puede actualizar ese valor, propagando el cambio de vuelta al padre automáticamente.

```typescript
import { Component, model } from '@angular/core';

@Component({
  selector: 'app-campo-editable',
  standalone: true,
  template: `
    <input
      [value]="texto()"
      (input)="texto.set($any($event.target).value)"
    />
    <p>Vista previa: {{ texto() }}</p>
  `
})
export class CampoEditableComponent {
  // model() crea un Signal de lectura/escritura enlazado con el padre
  texto = model<string>('');

  // También existe model.required() para modelos obligatorios
  // valorRequerido = model.required<number>();
}
```

El padre lo vincula con la sintaxis de banana-in-a-box, igual que antes, pero ahora funciona con cualquier Signal:

```html
<!-- El padre declara una variable reactiva y la pasa al hijo -->
<app-campo-editable [(texto)]="nombreUsuario" />
```

Cuando el hijo llama a `texto.set('nuevo valor')`, Angular propaga ese cambio al Signal del padre automáticamente. No hay `EventEmitter`, no hay `emit()`, no hay convención de nombres con el sufijo `Change` que recordar. El model signal maneja todo internamente.

La diferencia entre `input()` y `model()` es clara: un `input` es de solo lectura desde el punto de vista del hijo (el padre lo controla). Un `model` es de lectura y escritura tanto para el padre como para el hijo, con la sincronización manejada por Angular.

## `output<T>()`: reemplazo de `@Output() EventEmitter`

`output()` crea un canal de eventos tipado que el componente hijo puede usar para notificar al padre. Reemplaza al patrón `@Output() eventoClick = new EventEmitter<string>()`. A diferencia de `input()` y `model()`, `output()` no es un Signal -no tiene un valor que leer-, sino un emisor de eventos.

```typescript
import { Component, output, input } from '@angular/core';

@Component({
  selector: 'app-item-lista',
  standalone: true,
  template: `
    <li>
      {{ etiqueta() }}
      <button (click)="eliminar()">X</button>
      <button (click)="seleccionar()">Ver</button>
    </li>
  `
})
export class ItemListaComponent {
  etiqueta = input.required<string>();
  id = input.required<number>();

  // output<T>() define el tipo del dato que se emitirá
  eliminado = output<number>();
  seleccionado = output<{ id: number; etiqueta: string }>();

  eliminar(): void {
    // .emit() funciona igual que EventEmitter
    this.eliminado.emit(this.id());
  }

  seleccionar(): void {
    this.seleccionado.emit({ id: this.id(), etiqueta: this.etiqueta() });
  }
}
```

El padre lo escucha con la misma sintaxis de event binding:

```html
<app-item-lista
  [id]="item.id"
  [etiqueta]="item.nombre"
  (eliminado)="onEliminar($event)"
  (seleccionado)="onSeleccionar($event)"
/>
```

También existe `outputFromObservable()` para crear un output a partir de un Observable existente, útil cuando la fuente del evento es un stream RxJS.

## Componente completo con todas las APIs nuevas

Veamos cómo conviven `input()`, `model()`, `output()` y `computed()` en un componente realista:

```typescript
import { Component, input, model, output, computed } from '@angular/core';
import { FormsModule } from '@angular/forms';

interface Tarea {
  id: number;
  titulo: string;
  completada: boolean;
}

@Component({
  selector: 'app-tarea',
  standalone: true,
  imports: [FormsModule],
  template: `
    <div [class.completada]="tarea().completada">
      <input type="checkbox" [(ngModel)]="completadaModel" />
      <span>{{ tarea().titulo }}</span>
      <em>{{ resumen() }}</em>
      <button (click)="solicitudEliminar()">Eliminar</button>
    </div>
  `
})
export class TareaComponent {
  tarea = input.required<Tarea>();

  // model para que el padre pueda leer si la tarea está completada
  completadaModel = model<boolean>(false);

  eliminada = output<number>();

  // Estado derivado del input
  resumen = computed(() =>
    this.tarea().completada ? 'Finalizada' : 'Pendiente'
  );

  solicitudEliminar(): void {
    this.eliminada.emit(this.tarea().id);
  }
}
```

## Puntos clave

- `input<T>()` convierte el input del componente en un Signal de solo lectura; `input.required<T>()` hace obligatorio ese binding a nivel de compilación
- La opción `transform` en `input()` permite normalizar o convertir el valor recibido sin necesidad de setters
- `model<T>()` implementa two-way binding sin `EventEmitter` ni la convención de sufijo `Change`
- `output<T>()` es un emisor tipado que reemplaza `@Output() new EventEmitter<T>()`; se usa igual desde el padre con `(evento)`
- Estos tres mecanismos integran la comunicación entre componentes en el grafo de Signals, habilitando un Change Detection más preciso

## ¿Qué sigue?

En la Parte 4 estudiamos cómo conectar el mundo de Signals con el de RxJS usando `toSignal()` y `toObservable()`, el puente indispensable en proyectos que usan ambos paradigmas.
