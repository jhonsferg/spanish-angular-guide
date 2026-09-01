# Capítulo 32 - Parte 2: Smart Components y Dumb Components: separación de responsabilidades

> **Parte 2 de 4** · Capítulo 32 · PARTE XIV - Arquitectura y Patrones Avanzados

Existe un patrón que, una vez que lo internalizamos, cambia la forma en que pensamos cada componente que escribimos. No es nuevo ni exclusivo de Angular, pero en el ecosistema Angular con NgRx o Signals se vuelve especialmente poderoso: la distinción entre componentes inteligentes (Smart) y componentes tontos (Dumb). El nombre puede sonar condescendiente, pero la idea es hermosa: algunos componentes saben del mundo, otros solo saben mostrarse bien.

## Los dos roles en el teatro de la UI

Pensemos en una obra de teatro. Hay personajes que toman decisiones, coordinan la acción, hablan con otros actores fuera del escenario. Y hay decorados: perfectamente detallados, visuales, pero que no deciden nada por sí solos. Los componentes Smart son los actores con agencia. Los Dumb son el decorado precioso y reutilizable.

**Container Component (Smart)**: sabe dónde vive el estado. Inyecta servicios o facades, suscribe Observables o lee Signals del store, despacha acciones, orquesta la lógica. No recibe sus datos principales por `@Input` desde un padre; los obtiene directamente de la fuente de verdad.

**Presentational Component (Dumb)**: no sabe nada del store ni de los servicios. Recibe todo por `@Input`, comunica hacia arriba solo por `@Output`. Es una función pura en forma de componente: mismos inputs, siempre el mismo resultado visual.

## Implementando el Container Component

Veamos el componente Container para nuestra lista de productos:

```typescript
// features/productos/pages/productos-page.component.ts
import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ProductosFacade } from '../services/productos.facade';
import { ProductoListaComponent } from '../components/producto-lista.component';
import { ProductoFiltrosComponent } from '../components/producto-filtros.component';
import { FiltroProductos, Producto } from '../models/producto.model';

@Component({
  selector: 'app-productos-page',
  standalone: true,
  imports: [CommonModule, ProductoListaComponent, ProductoFiltrosComponent],
  template: `
    <div class="pagina-productos">
      <app-producto-filtros
        [filtroActual]="(facade.filtroActual$ | async)!"
        (filtroAplicado)="onFiltroAplicado($event)"
      />
      <app-producto-lista
        [productos]="(facade.productos$ | async) ?? []"
        [cargando]="(facade.cargando$ | async) ?? false"
        [error]="(facade.error$ | async) ?? null"
        (productoSeleccionado)="onProductoSeleccionado($event)"
        (productoEliminado)="onProductoEliminado($event)"
      />
    </div>
  `
})
export class ProductosPageComponent implements OnInit {
  protected readonly facade = inject(ProductosFacade);

  ngOnInit(): void {
    this.facade.cargarProductos();
  }

  protected onFiltroAplicado(filtro: FiltroProductos): void {
    this.facade.aplicarFiltro(filtro);
  }

  protected onProductoSeleccionado(producto: Producto): void {
    this.facade.seleccionarProducto(producto.id);
  }

  protected onProductoEliminado(id: string): void {
    this.facade.eliminarProducto(id);
  }
}
```

Notemos lo que **no** hace este componente: no tiene lógica de presentación, no calcula nada para la UI, no filtra listas localmente. Solo orquesta.

## Implementando el Presentational Component

El componente Dumb recibe datos y emite eventos. No sabe de dónde vienen los datos ni qué pasará cuando emite:

```typescript
// features/productos/components/producto-lista.component.ts
import {
  Component, Input, Output, EventEmitter,
  ChangeDetectionStrategy
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { Producto } from '../models/producto.model';
import { ProductoTarjetaComponent } from './producto-tarjeta.component';
import { SpinnerComponent } from '../../../shared/ui/spinner.component';

@Component({
  selector: 'app-producto-lista',
  standalone: true,
  imports: [CommonModule, ProductoTarjetaComponent, SpinnerComponent],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @if (cargando) {
      <app-spinner mensaje="Cargando productos..." />
    } @else if (error) {
      <div class="error-mensaje">{{ error }}</div>
    } @else if (productos.length === 0) {
      <div class="vacio">No hay productos disponibles.</div>
    } @else {
      <ul class="lista-productos">
        @for (producto of productos; track producto.id) {
          <li>
            <app-producto-tarjeta
              [producto]="producto"
              (seleccionado)="productoSeleccionado.emit(producto)"
              (eliminado)="productoEliminado.emit(producto.id)"
            />
          </li>
        }
      </ul>
    }
  `
})
export class ProductoListaComponent {
  @Input({ required: true }) productos: Producto[] = [];
  @Input() cargando: boolean = false;
  @Input() error: string | null = null;
  @Output() productoSeleccionado = new EventEmitter<Producto>();
  @Output() productoEliminado = new EventEmitter<string>();
}
```

Este componente es completamente reutilizable. Podría usarse en la página principal, en un modal de selección, en un panel de administración; siempre que alguien le pase la lista y escuche sus eventos.

## La relación perfecta con OnPush

Los componentes Dumb son candidatos naturales para `ChangeDetectionStrategy.OnPush`. La razón es matemática: si el componente solo depende de sus `@Input`, Angular solo necesita re-renderizarlo cuando esos inputs cambian. Con OnPush, Angular verifica referencias, no valores profundos. Esto significa que si pasamos el mismo arreglo mutado, Angular no detectará el cambio, lo que nos obliga a una buena práctica: siempre crear nuevos objetos en el store (inmutabilidad).

```typescript
// Mal: muta el arreglo existente (OnPush no lo detecta)
this.productosLocales.push(nuevoProducto);

// Bien: crea una nueva referencia
this.productosLocales = [...this.productosLocales, nuevoProducto];
```

Los componentes Smart, en cambio, suelen quedarse con `ChangeDetectionStrategy.Default` o usar el `async` pipe que marca automáticamente para chequeo.

## Reglas para decidir cuál usar

Cuando vamos a crear un nuevo componente, nos hacemos estas preguntas:

| Pregunta | Respuesta | Tipo |
|---|---|---|
| ¿Necesita hablar con el store o servicios? | Sí | Smart |
| ¿Solo muestra datos que recibe? | Sí | Dumb |
| ¿Podría usarse en otro contexto con datos diferentes? | Sí | Dumb |
| ¿Contiene la lógica de "qué hacer"? | Sí | Smart |
| ¿Solo contiene la lógica de "cómo mostrarse"? | Sí | Dumb |

## Cuándo es correcto romper la regla

La arquitectura Smart/Dumb es una guía, no una ley. Hay casos legítimos para romperla:

**Formularios complejos con mucha interacción local**: un formulario de checkout con validaciones cruzadas, cálculos en tiempo real y lógica de UI compleja puede ser razonable como un componente único que maneja tanto la UI como algo de estado local. Crear un container solo para delegarle un `FormGroup` no siempre agrega valor.

**Componentes de infraestructura**: un componente de scroll infinito necesita saber cuándo está cerca del fondo y pedir más datos. Separarlo en dos capas podría resultar más complicado que simplemente inyectar el servicio directamente.

**Prototipos y features de muy corta vida**: el overhead de la separación tiene un costo. Si estamos haciendo spike técnico o una feature que sabemos que va a cambiar completamente, la pureza arquitectónica puede esperar.

## El impacto en el testing

La diferencia en testing es donde el patrón demuestra su valor más claramente.

Testear un componente Smart requiere mockear el store, los efectos, los servicios. Es posible pero verboso:

```typescript
// Test del Container (necesita mocks del store)
describe('ProductosPageComponent', () => {
  let facade: jasmine.SpyObj<ProductosFacade>;

  beforeEach(async () => {
    facade = jasmine.createSpyObj('ProductosFacade', [
      'cargarProductos', 'aplicarFiltro', 'eliminarProducto'
    ], {
      productos$: of([]),
      cargando$: of(false),
      error$: of(null),
      filtroActual$: of({})
    });

    await TestBed.configureTestingModule({
      imports: [ProductosPageComponent],
      providers: [{ provide: ProductosFacade, useValue: facade }]
    }).compileComponents();
  });
});
```

Testear un componente Dumb es trivial: solo pasamos datos y verificamos el template:

```typescript
// Test del Presentational (sin mocks, puro)
describe('ProductoListaComponent', () => {
  it('muestra un mensaje cuando no hay productos', async () => {
    const fixture = await render(ProductoListaComponent, {
      componentInputs: {
        productos: [],
        cargando: false,
        error: null
      }
    });
    expect(fixture.getByText('No hay productos disponibles.')).toBeTruthy();
  });

  it('emite productoEliminado cuando se elimina', async () => {
    const onEliminado = jest.fn();
    const fixture = await render(ProductoListaComponent, {
      componentInputs: { productos: [mockProducto], cargando: false, error: null },
      componentOutputs: { productoEliminado: { emit: onEliminado } as EventEmitter<string> }
    });
    // interactuar con el UI y verificar la emisión
  });
});
```

## Puntos clave

- Los componentes Smart (Container) obtienen su estado del store o servicios; los Dumb (Presentational) solo reciben `@Input` y emiten `@Output`, sin saber de dónde vienen los datos.
- Los componentes Dumb con `ChangeDetectionStrategy.OnPush` son la combinación de mayor rendimiento en Angular: mínimos re-renders, fácil razonamiento.
- La reutilización real viene de los componentes Dumb: el mismo componente de lista puede funcionar en diferentes contextos simplemente porque no está acoplado a ningún store ni servicio.
- El testing de componentes Dumb es casi trivial comparado con el de componentes Smart; una buena proporción de Dumb vs Smart mejora dramáticamente la cobertura de tests.
- Romper la regla está permitido cuando el overhead de la separación supera el beneficio: formularios complejos, prototipos o componentes de infraestructura son candidatos legítimos.

## ¿Qué sigue?

En la siguiente parte introduciremos el Facade Pattern, que simplifica aún más la relación entre los componentes Smart y el store, ocultando la complejidad de NgRx detrás de una API limpia y estable.
