# Capítulo 4 - Parte 2: ng-content: proyección de contenido simple y múltiple

> **Parte 2 de 4** · Capítulo 4 · PARTE II - Componentes: El Alma de Angular

Los componentes que hemos visto hasta ahora tienen una limitación: su contenido visual está fijo en su propio template. Un componente `<app-tarjeta>` con un título y una imagen en su template siempre mostrará ese título y esa imagen, sin importar qué HTML coloque el padre entre sus etiquetas de apertura y cierre. La proyección de contenido rompe esta limitación: permite que el padre inyecte HTML arbitrario dentro del componente hijo, convirtiéndolo en un contenedor reutilizable de forma mucho más flexible.

## Proyección simple con ng-content

El elemento `<ng-content>` es un marcador de posición. Angular lo reemplaza en tiempo de compilación con el contenido que el padre colocó entre las etiquetas del componente hijo. El componente hijo no necesita saber qué viene: simplemente reserva el espacio.

```typescript
// archivo: panel.component.ts
import { Component } from '@angular/core';

@Component({
  selector: 'app-panel',
  standalone: true,
  template: `
    <div class="panel">
      <div class="panel-cuerpo">
        <!-- El contenido del padre aparece aquí -->
        <ng-content />
      </div>
    </div>
  `,
  styles: [`
    .panel { border: 1px solid #e0e0e0; border-radius: 8px; overflow: hidden; }
    .panel-cuerpo { padding: 16px; }
  `]
})
export class PanelComponent {}
```

El padre lo usa así, colocando cualquier HTML entre las etiquetas del componente:

```html
<app-panel>
  <h3>Resumen mensual</h3>
  <p>Las ventas de este mes superaron el objetivo en un 12%.</p>
  <app-grafico-barras [datos]="datosMensuales" />
</app-panel>
```

Todo el HTML que el padre escriba entre `<app-panel>` y `</app-panel>` se proyectará en el lugar donde esté el `<ng-content>`. El componente padre controla el contenido; el componente hijo controla el envoltorio visual.

## Proyección múltiple con select

Cuando un componente necesita múltiples "ranuras" (slots) para contenido, el atributo `select` de `<ng-content>` actúa como un filtro. Cada `<ng-content select="...">` captura solo los elementos del padre que coincidan con el selector CSS indicado.

```typescript
// archivo: tarjeta.component.ts
import { Component } from '@angular/core';

@Component({
  selector: 'app-tarjeta',
  standalone: true,
  template: `
    <article class="tarjeta">
      <header class="tarjeta-cabecera">
        <!-- Solo captura elementos con atributo slot="cabecera" -->
        <ng-content select="[slot=cabecera]" />
      </header>

      <div class="tarjeta-cuerpo">
        <!-- Captura cualquier elemento que no fue capturado por los otros slots -->
        <ng-content />
      </div>

      <footer class="tarjeta-pie">
        <!-- Solo captura elementos con la clase .pie-tarjeta -->
        <ng-content select=".pie-tarjeta" />
      </footer>
    </article>
  `,
  styles: [`
    .tarjeta { border: 1px solid #ddd; border-radius: 8px; overflow: hidden; }
    .tarjeta-cabecera { background: #f5f5f5; padding: 12px 16px; border-bottom: 1px solid #ddd; }
    .tarjeta-cuerpo { padding: 16px; }
    .tarjeta-pie { padding: 12px 16px; border-top: 1px solid #ddd; text-align: right; }
  `]
})
export class TarjetaComponent {}
```

El padre distribuye el contenido asignando el atributo o clase correcta a cada elemento:

```html
<app-tarjeta>
  <!-- Va al slot [slot=cabecera] -->
  <h2 slot="cabecera">Perfil de usuario</h2>

  <!-- Va al ng-content sin select (slot por defecto) -->
  <p>Nombre: María García</p>
  <p>Email: maria@ejemplo.com</p>

  <!-- Va al slot .pie-tarjeta -->
  <div class="pie-tarjeta">
    <button>Editar perfil</button>
    <button>Cerrar sesión</button>
  </div>
</app-tarjeta>
```

El `select` puede usar cualquier selector CSS válido: nombres de elementos (`h2`, `p`), atributos (`[slot=cabecera]`), clases (`.mi-clase`) o combinaciones. El `<ng-content>` sin `select` actúa como el slot "de desbordamiento": captura todo lo que no fue reclamado por ningún otro slot.

## ng-container: el contenedor invisible

`<ng-container>` es un elemento de Angular que no genera ningún elemento HTML en el DOM. Es útil cuando necesitas agrupar varios elementos para proyectarlos como un bloque, sin añadir un `<div>` o `<span>` extra que pueda romper el layout:

```html
<app-tarjeta>
  <ng-container slot="cabecera">
    <!-- Proyecta AMBOS elementos sin añadir un wrapper al DOM -->
    <h2>Reporte de ventas</h2>
    <span class="subtitulo">Mayo 2026</span>
  </ng-container>

  <p>El contenido principal va aquí...</p>
</app-tarjeta>
```

Sin `ng-container`, tendrías que envolver ambos elementos en un `<div slot="cabecera">`, que añadiría un elemento real al DOM y podría afectar el CSS de la cabecera.

## ContentChild y ContentChildren: acceder al contenido proyectado

Así como `@ViewChild` accede a elementos de la vista propia del componente, `@ContentChild` y `@ContentChildren` acceden al contenido proyectado desde el padre. La distinción es importante: el contenido proyectado pertenece al padre (tiene el contexto de datos del padre), pero vive visualmente dentro del hijo.

```typescript
// archivo: acordeon.component.ts
import { Component, ContentChildren, QueryList, AfterContentInit } from '@angular/core';
import { PanelAcordeonComponent } from './panel-acordeon.component';

@Component({
  selector: 'app-acordeon',
  standalone: true,
  imports: [PanelAcordeonComponent],
  template: `<ng-content />`
})
export class AcordeonComponent implements AfterContentInit {
  // ContentChildren obtiene todos los PanelAcordeonComponent proyectados
  @ContentChildren(PanelAcordeonComponent)
  paneles!: QueryList<PanelAcordeonComponent>;

  ngAfterContentInit(): void {
    // El contenido proyectado está disponible aquí (NO en ngAfterViewInit)
    console.log(`Acordeón con ${this.paneles.length} paneles`);

    // Podemos coordinar el comportamiento de todos los paneles hijos
    this.paneles.forEach((panel, index) => {
      panel.abierto = index === 0; // Solo el primer panel abierto al inicio
    });
  }
}
```

El ciclo de vida para el contenido proyectado usa sus propios hooks:

- **`ngAfterContentInit`**: equivalente a `ngAfterViewInit`, pero para contenido proyectado. `@ContentChild` y `@ContentChildren` están disponibles aquí.
- **`ngAfterContentChecked`**: equivalente a `ngAfterViewChecked`, para el contenido proyectado.

## Ejemplo completo: componente de card reutilizable

Construyamos un componente de card completo que combine todo lo aprendido: proyección múltiple con slots, `ng-container` para agrupar, y un diseño flexible que puede usarse en múltiples contextos.

```typescript
// archivo: card.component.ts
import { Component, Input, ContentChild, AfterContentInit } from '@angular/core';
import { NgIf } from '@angular/common';

@Component({
  selector: 'app-card',
  standalone: true,
  imports: [NgIf],
  template: `
    <div class="card" [class.card--elevada]="elevada">
      @if (tieneCabecera) {
        <div class="card__cabecera">
          <ng-content select="[card-cabecera]" />
        </div>
      }

      <div class="card__cuerpo">
        <ng-content />
      </div>

      <div class="card__pie">
        <ng-content select="[card-pie]" />
      </div>
    </div>
  `,
  styles: [`
    .card { border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,.12); overflow: hidden; }
    .card--elevada { box-shadow: 0 4px 16px rgba(0,0,0,.2); }
    .card__cabecera { padding: 16px; background: #fafafa; border-bottom: 1px solid #eee; }
    .card__cuerpo { padding: 20px; }
    .card__pie { padding: 12px 16px; border-top: 1px solid #eee; display: flex; justify-content: flex-end; gap: 8px; }
  `]
})
export class CardComponent implements AfterContentInit {
  @Input({ transform: (v: unknown) => v !== null && v !== undefined }) elevada: boolean = false;
  tieneCabecera: boolean = false;

  // Detectamos si el padre proyectó contenido en el slot de cabecera
  @ContentChild('[card-cabecera]') cabecera?: unknown;

  ngAfterContentInit(): void {
    this.tieneCabecera = !!this.cabecera;
  }
}
```

Uso del componente en diferentes configuraciones:

```html
<!-- Configuración 1: Card completa con los tres slots -->
<app-card [elevada]="true">
  <h3 card-cabecera>Resumen de cuenta</h3>
  <p>Saldo actual: <strong>$4,250.00</strong></p>
  <p>Última transacción: hace 2 horas</p>
  <div card-pie>
    <button>Ver historial</button>
    <button>Transferir</button>
  </div>
</app-card>

<!-- Configuración 2: Solo cuerpo, sin cabecera ni pie -->
<app-card>
  <p>Una card mínima, solo con cuerpo.</p>
</app-card>
```

## Puntos clave

- `<ng-content>` proyecta el contenido que el padre coloca entre las etiquetas del componente hijo.
- El atributo `select` en `<ng-content select="...">` filtra qué elementos proyectar en cada slot, usando selectores CSS.
- `<ng-container>` permite agrupar elementos para proyectarlos sin añadir nodos extra al DOM.
- `@ContentChild` y `@ContentChildren` dan acceso desde el hijo al contenido proyectado; están disponibles en `ngAfterContentInit`.
- El contenido proyectado pertenece al contexto del padre: sus bindings se evalúan con las variables del padre, no del hijo que lo muestra.

## ¿Qué sigue?

En la Parte 3 exploramos los componentes Standalone en profundidad: cómo funcionan sin módulos, cómo arrancar una aplicación con `bootstrapApplication` y qué ventajas concretas ofrecen sobre el enfoque basado en `NgModule`.
