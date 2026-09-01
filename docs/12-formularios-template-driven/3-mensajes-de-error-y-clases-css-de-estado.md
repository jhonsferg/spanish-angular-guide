# Capítulo 12 - Parte 3: Mensajes de error y clases CSS de estado

> **Parte 3 de 4** · Capítulo 12 · PARTE VII - Formularios

Ya sabemos que Angular registra el estado de cada campo y del formulario completo, y que expone ese estado a través de propiedades como `invalid`, `touched` y `errors`. El reto real está en decidir cuándo mostrar los errores al usuario. Mostrarlos demasiado pronto produce formularios que parecen agresivos. Mostrarlos demasiado tarde confunde al usuario después del submit. La respuesta correcta depende del contexto, y Angular nos da los bloques para implementar cualquiera de las tres estrategias principales.

## Estrategia 1: Mostrar errores al perder el foco (touched)

La estrategia más común y recomendada para la mayoría de los formularios es mostrar el error cuando el usuario ha interactuado con el campo y luego lo ha abandonado. La combinación `campo.invalid && campo.touched` captura exactamente este momento:

```html
<input
  type="text"
  name="nombre"
  [(ngModel)]="datos.nombre"
  required
  minlength="3"
  #campoNombre="ngModel"
/>

<!-- Solo visible después de que el usuario tocó el campo -->
@if (campoNombre.invalid && campoNombre.touched) {
  <p class="error">{{ mensajeError(campoNombre.errors) }}</p>
}
```

Este enfoque respeta el flujo natural del usuario: completa un campo, pasa al siguiente, y si hay un problema, lo ve de inmediato sin necesidad de llegar al botón de submit.

## Estrategia 2: Mostrar errores solo al hacer submit

Para ciertos formularios, como los de pago o los multi-paso, es preferible mostrar todos los errores juntos al intentar enviar. Para esto necesitamos una variable en el componente que registre si el submit fue intentado:

```typescript
import { Component } from '@angular/core';
import { FormsModule, NgForm } from '@angular/forms';

@Component({
  selector: 'app-pago',
  standalone: true,
  imports: [FormsModule],
  template: `
    <form #formulario="ngForm" (ngSubmit)="alEnviar(formulario)">
      <input
        type="text"
        name="titular"
        [(ngModel)]="datos.titular"
        required
        #campoTitular="ngModel"
      />
      <!-- Error visible solo si se intentó enviar -->
      @if (campoTitular.invalid && submitIntentado) {
        <span class="error">El nombre del titular es obligatorio.</span>
      }
      <button type="submit">Pagar</button>
    </form>
  `
})
export class PagoComponent {
  datos = { titular: '' };
  submitIntentado = false;

  alEnviar(formulario: NgForm): void {
    this.submitIntentado = true; // Marca el intento
    if (formulario.valid) {
      console.log('Procesando pago:', this.datos);
    }
  }
}
```

Con `submitIntentado`, ningún error es visible hasta que el usuario hace clic en "Pagar". En ese momento, todos los campos inválidos muestran sus mensajes simultáneamente.

## Estrategia 3: Mostrar errores inmediatamente (dirty)

Para casos donde el feedback instantáneo es deseable, como buscadores o formularios de filtros, podemos usar `campo.dirty` en lugar de `campo.touched`. `dirty` se vuelve `true` en el momento en que el usuario escribe el primer carácter, sin esperar a que el campo pierda el foco:

```html
<!-- Feedback inmediato mientras el usuario escribe -->
@if (campoBusqueda.invalid && campoBusqueda.dirty) {
  <span class="error">Mínimo 3 caracteres para buscar.</span>
}
```

Esta estrategia es más agresiva y solo tiene sentido cuando el campo tiene validaciones de longitud mínima o formato, y el usuario necesita saber si va por buen camino mientras escribe.

## Componente de campo reutilizable

Repetir la lógica de mostrar mensajes de error en cada campo de cada formulario es una fuente de duplicación. La solución elegante es encapsular un campo con su etiqueta, input y mensajes en un componente reutilizable:

```typescript
import { Component, Input, forwardRef } from '@angular/core';
import { ControlValueAccessor, FormsModule,
         NG_VALUE_ACCESSOR, NgModel } from '@angular/forms';

@Component({
  selector: 'app-campo-texto',
  standalone: true,
  imports: [FormsModule],
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => CampoTextoComponent),
      multi: true
    }
  ],
  template: `
    <div class="campo">
      <label [for]="nombre">{{ etiqueta }}</label>
      <input
        [id]="nombre"
        [name]="nombre"
        [type]="tipo"
        [(ngModel)]="valor"
        [required]="obligatorio"
        [minlength]="minimo ?? ''"
        (ngModelChange)="onChange($event)"
        (blur)="onTouched()"
        #control="ngModel"
      />
      @if (control.invalid && control.touched) {
        <div class="errores">
          @if (control.errors?.['required']) {
            <span>{{ etiqueta }} es obligatorio.</span>
          }
          @if (control.errors?.['minlength']) {
            <span>Mínimo {{ minimo }} caracteres.</span>
          }
          @if (control.errors?.['email']) {
            <span>Formato de correo inválido.</span>
          }
        </div>
      }
    </div>
  `
})
export class CampoTextoComponent implements ControlValueAccessor {
  @Input() nombre = '';
  @Input() etiqueta = '';
  @Input() tipo = 'text';
  @Input() obligatorio = false;
  @Input() minimo?: number;

  valor = '';
  onChange: (v: string) => void = () => {};
  onTouched: () => void = () => {};

  writeValue(val: string): void { this.valor = val ?? ''; }
  registerOnChange(fn: (v: string) => void): void { this.onChange = fn; }
  registerOnTouched(fn: () => void): void { this.onTouched = fn; }
}
```

Con este componente, un formulario completo queda expresivo y limpio:

```html
<form #formulario="ngForm" (ngSubmit)="alEnviar(formulario)">
  <app-campo-texto
    nombre="nombre"
    etiqueta="Nombre completo"
    [obligatorio]="true"
    [minimo]="3"
    [(ngModel)]="datos.nombre"
  />
  <app-campo-texto
    nombre="correo"
    etiqueta="Correo electrónico"
    tipo="email"
    [obligatorio]="true"
    [(ngModel)]="datos.correo"
  />
  <button type="submit">Enviar</button>
</form>
```

`ControlValueAccessor` es la interfaz que permite a un componente participar en el sistema de formularios de Angular, ya sea template-driven o reactivo. Al implementarla, el componente se comporta exactamente como un `<input>` nativo desde la perspectiva del sistema de formularios.

## Reset del formulario con form.reset()

Después de un submit exitoso, limpiar el formulario a su estado inicial es una operación muy común. `NgForm` expone el método `reset()` para esto:

```typescript
alEnviar(formulario: NgForm): void {
  if (formulario.valid) {
    // Procesar los datos...
    console.log('Datos:', this.datos);

    // Resetea los valores Y los estados (touched, dirty, etc.)
    formulario.reset();
    // El formulario vuelve a pristine y untouched
    // Las clases ng-invalid no volverán a mostrarse hasta nueva interacción
  }
}
```

`formulario.reset()` hace dos cosas importantes: limpia los valores de todos los campos y restablece todos los estados a su valor inicial (`pristine`, `untouched`). Esto significa que después del reset, los mensajes de error dejan de mostrarse aunque los campos estén vacíos, porque `touched` vuelve a ser `false`.

También podemos pasar un objeto a `reset()` para establecer valores específicos en lugar de vaciar todo:

```typescript
// Resetear con valores predeterminados
formulario.reset({ nombre: '', correo: 'nuevo@ejemplo.com' });
```

## Acceder al estado desde la clase con @ViewChild

A veces necesitamos interactuar con el formulario desde la clase TypeScript sin esperar a que el usuario haga submit. `@ViewChild` nos permite obtener la referencia al `NgForm` directamente:

```typescript
import { Component, ViewChild } from '@angular/core';
import { FormsModule, NgForm } from '@angular/forms';

@Component({
  selector: 'app-perfil',
  standalone: true,
  imports: [FormsModule],
  template: `
    <form #formulario="ngForm">
      <input name="bio" [(ngModel)]="bio" />
    </form>
    <button (click)="resetearFormulario()">Limpiar</button>
  `
})
export class PerfilComponent {
  // Angular inyecta la referencia después de que la vista se inicializa
  @ViewChild('formulario') formulario!: NgForm;
  bio = '';

  resetearFormulario(): void {
    // Podemos acceder al formulario desde cualquier método
    this.formulario.reset();
  }
}
```

`@ViewChild('formulario')` busca en el template la variable de referencia llamada `formulario` y la inyecta en la propiedad decorada. El signo `!` es necesario porque TypeScript no puede saber que Angular lo llenará después de `ngAfterViewInit`, pero con `strict: true` debemos declararlo como posiblemente indefinido o usar la aserción de no nulidad.

## Puntos clave

- La estrategia `campo.invalid && campo.touched` es la más equilibrada para la mayoría de los formularios: muestra errores sin ser agresiva
- La estrategia `campo.invalid && submitIntentado` retrasa todos los errores hasta el primer intento de envío, útil para formularios críticos
- `ControlValueAccessor` permite crear componentes de campo personalizados que participan nativamente en el sistema de formularios
- `formulario.reset()` limpia tanto los valores como los estados del formulario, incluyendo `touched` y `dirty`
- `@ViewChild` permite acceder al `NgForm` desde la clase TypeScript para operaciones programáticas fuera del contexto del submit

## ¿Qué sigue?

En la Parte 4 conocemos `ngModelGroup`, la directiva que nos permite agrupar campos relacionados dentro de un formulario para organizar datos complejos como direcciones o datos de tarjetas de crédito.
