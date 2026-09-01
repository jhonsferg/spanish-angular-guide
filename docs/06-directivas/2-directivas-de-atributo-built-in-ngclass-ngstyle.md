# Capítulo 6 - Parte 2: Directivas de atributo built-in: ngClass, ngStyle

> **Parte 2 de 4** · Capítulo 6 · PARTE III - Templates y Directivas

Las directivas de atributo no modifican la estructura del DOM sino las propiedades del elemento al que se aplican. `ngClass` y `ngStyle` son las dos más utilizadas del framework: permiten manipular clases CSS y estilos en línea de forma dinámica con una API más expresiva que los class/style bindings directos que vimos en el Capítulo 5. Entender cuándo cada forma es apropiada evita código redundante y difícil de mantener.

## `[ngClass]`: manipulación dinámica de clases

`[ngClass]` acepta tres formas de entrada: un objeto, un array o una cadena de texto. Cada forma tiene su caso de uso óptimo. Para usarla en un componente standalone hay que importar `NgClass` de `@angular/common`:

```typescript
import { Component } from '@angular/core';
import { NgClass } from '@angular/common';

@Component({
  selector: 'app-insignia',
  standalone: true,
  imports: [NgClass],
  template: `
    <!-- Forma con objeto: las claves son clases, los valores son condiciones booleanas -->
    <span [ngClass]="{
      'insignia-admin':    rol === 'admin',
      'insignia-editor':   rol === 'editor',
      'insignia-lector':   rol === 'lector',
      'destacado':         esPrincipal,
      'deshabilitado':     !estaActivo
    }">
      {{ rol }}
    </span>
  `,
  styles: [`
    .insignia-admin   { background: #d32f2f; color: white; }
    .insignia-editor  { background: #1976d2; color: white; }
    .insignia-lector  { background: #388e3c; color: white; }
    .destacado        { font-weight: bold; border: 2px solid gold; }
    .deshabilitado    { opacity: 0.4; pointer-events: none; }
  `]
})
export class InsigniaComponent {
  rol = 'editor';
  esPrincipal = true;
  estaActivo = true;
}
```

La forma con objeto es la más común: cada clave es un nombre de clase CSS y el valor es una expresión booleana. Angular agrega la clase cuando la condición es `true` y la elimina cuando es `false`, de forma eficiente y sin necesidad de lógica manual.

## `[ngClass]` con array y con string

La forma con array permite combinar clases estáticas y condicionales en una lista:

```typescript
import { Component } from '@angular/core';
import { NgClass } from '@angular/common';

@Component({
  selector: 'app-boton-accion',
  standalone: true,
  imports: [NgClass],
  template: `
    <!-- Array: mezcla de strings estáticos y expresiones -->
    <button [ngClass]="['btn', 'btn-' + variante, tamano, estaDeshabilitado ? 'deshabilitado' : '']">
      {{ etiqueta }}
    </button>

    <!-- String: cuando las clases se calculan de forma programática -->
    <button [ngClass]="obtenerClases()">
      Acción alternativa
    </button>
  `
})
export class BotonAccionComponent {
  variante = 'primario';   // genera clase 'btn-primario'
  tamano = 'grande';
  estaDeshabilitado = false;
  etiqueta = 'Guardar';

  obtenerClases(): string {
    // Lógica compleja que produce una string de clases
    const clases = ['btn'];
    if (this.estaDeshabilitado) clases.push('deshabilitado');
    clases.push(`btn-${this.variante}`);
    return clases.join(' ');
  }
}
```

La forma con string es útil cuando la lógica de determinación de clases es compleja y conviene aislarla en un método de la clase. Sin embargo, Angular no puede hacer comparaciones incrementales con strings, por lo que la forma con objeto es más eficiente para condiciones individuales.

## `[ngClass]` con objeto calculado desde la clase

Para casos más complejos, conviene calcular el objeto de clases como una propiedad computed de la clase en lugar de escribirlo inline en el template. Esto también mejora la testabilidad:

```typescript
import { Component } from '@angular/core';
import { NgClass } from '@angular/common';

type EstadoAlerta = 'info' | 'exito' | 'advertencia' | 'error';

@Component({
  selector: 'app-alerta',
  standalone: true,
  imports: [NgClass],
  template: `
    <div [ngClass]="clasesAlerta" role="alert">
      <strong>{{ tituloAlerta }}</strong>
      <p>{{ mensajeAlerta }}</p>
    </div>
  `
})
export class AlertaComponent {
  estado: EstadoAlerta = 'info';
  tituloAlerta = 'Información';
  mensajeAlerta = 'Tu perfil ha sido actualizado.';

  // Getter calculado: el template solo llama a "clasesAlerta"
  get clasesAlerta(): Record<string, boolean> {
    return {
      'alerta':              true,        // siempre presente
      'alerta-info':         this.estado === 'info',
      'alerta-exito':        this.estado === 'exito',
      'alerta-advertencia':  this.estado === 'advertencia',
      'alerta-error':        this.estado === 'error',
    };
  }
}
```

## `[ngStyle]`: estilos en línea dinámicos

`[ngStyle]` acepta un objeto donde las claves son propiedades CSS (en camelCase o kebab-case con comillas) y los valores son las expresiones a aplicar:

```typescript
import { Component } from '@angular/core';
import { NgStyle } from '@angular/common';

@Component({
  selector: 'app-barra-progreso',
  standalone: true,
  imports: [NgStyle],
  template: `
    <div class="contenedor-barra">
      <div
        class="barra"
        [ngStyle]="{
          'width.%':           porcentaje,
          'background-color':  colorBarra,
          'transition':        'width 0.3s ease',
          'border-radius':     '4px'
        }"
      >
      </div>
      <span>{{ porcentaje }}%</span>
    </div>

    <input
      type="range"
      min="0"
      max="100"
      [value]="porcentaje"
      (input)="actualizarProgreso($event)"
    />
  `
})
export class BarraProgresoComponent {
  porcentaje = 65;

  get colorBarra(): string {
    if (this.porcentaje < 30) return '#f44336'; // rojo
    if (this.porcentaje < 70) return '#ff9800'; // naranja
    return '#4caf50';                            // verde
  }

  actualizarProgreso(evento: Event): void {
    this.porcentaje = +(evento.target as HTMLInputElement).value;
  }
}
```

La clave `'width.%'` es una extensión de Angular que permite especificar la unidad directamente: `'width.%': 65` produce `width: 65%`. También funciona con `'font-size.px'`, `'margin.rem'`, etc.

## `NgModel`: directiva de atributo del módulo de formularios

`NgModel` también es técnicamente una directiva de atributo (no estructural), aunque su caso de uso principal ya lo vimos con `[(ngModel)]` en el Capítulo 5. Aquí vale la pena señalar que `NgModel` puede usarse solo como directiva de property binding, sin two-way binding, para establecer el valor de un campo sin escuchar cambios:

```typescript
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-vista-lectura',
  standalone: true,
  imports: [FormsModule],
  template: `
    <!-- ngModel sin two-way binding: solo establece el valor -->
    <input type="text" [ngModel]="nombreUsuario" [disabled]="true" />
  `
})
export class VistaLecturaComponent {
  nombreUsuario = 'Ana García';
}
```

## Diferencias entre `[ngClass]`/`[ngStyle]` y los bindings directos

La elección entre `[ngClass]` y los bindings directos `[class.nombre]`/`[style.propiedad]` depende de la complejidad de lo que se necesita expresar:

```typescript
import { Component } from '@angular/core';
import { NgClass } from '@angular/common';

@Component({
  selector: 'app-comparacion',
  standalone: true,
  imports: [NgClass],
  template: `
    <!-- BINDING DIRECTO: ideal para una o dos condiciones simples -->
    <div
      [class.activo]="estaActivo"
      [class.error]="tieneError"
    >
      Con bindings directos
    </div>

    <!-- NGCLASS: ideal cuando hay múltiples clases o lógica compleja -->
    <div [ngClass]="clasesCalculadas">
      Con ngClass
    </div>

    <!-- BINDING DIRECTO de estilo: ideal para una propiedad -->
    <p [style.color]="colorTexto">Texto con color directo</p>

    <!-- NGSTYLE: ideal cuando hay múltiples estilos o condiciones -->
    <p [ngStyle]="estilosCalculados">Texto con ngStyle</p>
  `
})
export class ComparacionComponent {
  estaActivo = true;
  tieneError = false;
  colorTexto = '#333';

  get clasesCalculadas(): Record<string, boolean> {
    return {
      activo: this.estaActivo,
      error:  this.tieneError,
      grande: this.estaActivo && !this.tieneError,
    };
  }

  get estilosCalculados(): Record<string, string> {
    return {
      color:       this.tieneError ? '#f44336' : '#333',
      fontWeight:  this.estaActivo ? 'bold' : 'normal',
      fontSize:    '16px',
    };
  }
}
```

La regla práctica es: usa `[class.nombre]` y `[style.propiedad]` cuando manejas una sola clase o propiedad de estilo. Usa `[ngClass]` y `[ngStyle]` cuando manejas múltiples clases o estilos, especialmente si hay lógica condicional compleja. Para lógica muy compleja, calcúlala como getter en la clase y expón solo el resultado al template.

## Diagrama: cuándo usar cada forma de manipulación de clases

```mermaid
flowchart TD
    P["¿Cuántas clases necesito manipular?"]
    P --> U["Una sola clase"]
    P --> V["Varias clases"]
    U --> D["[class.nombre]=\"condición\"\nbinding directo - más eficiente"]
    V --> L["¿La lógica es simple?"]
    L --> S["Sí → [ngClass]=\"{ clase: condicion }\""]
    L --> C["No → Getter en la clase\nque devuelve Record<string, boolean>"]
    C --> N["[ngClass]=\"getterDeClases\""]
```

## Puntos clave

- `[ngClass]` acepta objeto `{ clase: condición }`, array `['clase1', expresión]` o string calculada desde la clase.
- `[ngStyle]` acepta un objeto con propiedades CSS en camelCase; soporta la extensión de unidades `'width.%': valor`.
- Para una sola clase o propiedad de estilo, prefiere `[class.nombre]` o `[style.propiedad]` - son más eficientes.
- Para múltiples clases o estilos con condiciones complejas, usa `[ngClass]` o `[ngStyle]` con un getter en la clase.
- En componentes standalone, importa `NgClass` y `NgStyle` de `@angular/common` individualmente.

## ¿Qué sigue?

En la Parte 3 dejamos las directivas built-in para construir nuestras propias directivas de atributo personalizadas: crearemos la directiva `appResaltado` que cambia el color de fondo de un elemento al hacer hover, usando `ElementRef`, `Renderer2` y `@HostListener`.
