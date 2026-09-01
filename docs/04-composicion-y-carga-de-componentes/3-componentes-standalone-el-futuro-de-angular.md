# Capítulo 4 - Parte 3: Componentes Standalone: el futuro de Angular

> **Parte 3 de 4** · Capítulo 4 · PARTE II - Componentes: El Alma de Angular

Desde sus primeras versiones, Angular organizó los componentes en NgModules. Cada componente debía pertenecer a exactamente un módulo que declarara sus dependencias, los exportara para que otros módulos los usaran, y participara en la cadena de resolución del inyector. Este sistema funciona, pero tiene un precio: añade una capa de indirección que dificulta entender qué necesita un componente para funcionar sin leer dos archivos a la vez. Los componentes standalone eliminan esa indirección.

## Qué cambia con standalone: true

La diferencia fundamental es que un componente standalone es su propio descriptor de dependencias. En lugar de delegar en un NgModule que declare qué pipes, directivas y componentes están disponibles, el propio componente los lista en su decorador. El resultado es que para entender qué usa un componente, basta con leer su archivo.

Con el enfoque de módulos:

```typescript
// app.module.ts - había que ir aquí para entender qué tiene disponible el componente
@NgModule({
  declarations: [ProductoListaComponent, ProductoTarjetaComponent],
  imports: [CommonModule, RouterModule, MatButtonModule],
  exports: [ProductoListaComponent]
})
export class ProductosModule {}

// producto-lista.component.ts - no dice nada sobre sus dependencias
@Component({ selector: 'app-producto-lista', templateUrl: '...' })
export class ProductoListaComponent {}
```

Con el enfoque standalone:

```typescript
// producto-lista.component.ts - todo lo necesario está aquí
import { Component } from '@angular/core';
import { RouterLink } from '@angular/router';
import { MatButtonModule } from '@angular/material/button';
import { ProductoTarjetaComponent } from './producto-tarjeta.component';
import { CurrencyPipe } from '@angular/common';

@Component({
  selector: 'app-producto-lista',
  standalone: true,
  // Todo lo que el template necesita está declarado aquí
  imports: [RouterLink, MatButtonModule, ProductoTarjetaComponent, CurrencyPipe],
  templateUrl: './producto-lista.component.html'
})
export class ProductoListaComponent {}
```

El componente es completamente autónomo. Puede moverse a otro proyecto, a otra carpeta, o ser usado en otro componente sin tener que actualizar ningún módulo.

## El array imports del decorador

En un componente standalone, el array `imports` acepta:

- **Otros componentes standalone**: simplemente se importan directamente.
- **Directivas y pipes standalone**: como `NgClass`, `AsyncPipe`, `CurrencyPipe` de `@angular/common`.
- **NgModules**: un componente standalone puede importar un NgModule completo para acceder a todo lo que exporta. Esto facilita la adopción progresiva: puedes usar librerías como Angular Material (que aún exporta módulos como `MatButtonModule`) sin necesidad de que el ecosistema completo sea standalone.

```typescript
import { Component } from '@angular/core';
import { NgClass, AsyncPipe, DatePipe } from '@angular/common';
import { ReactiveFormsModule } from '@angular/forms';
import { MatCardModule } from '@angular/material/card';        // NgModule de Material
import { RouterLink, RouterOutlet } from '@angular/router';
import { MiComponenteStandalone } from './mi-componente.component'; // Standalone

@Component({
  selector: 'app-ejemplo-imports',
  standalone: true,
  imports: [
    // Directivas/pipes individuales de @angular/common
    NgClass,
    AsyncPipe,
    DatePipe,
    // Módulo completo de Angular Forms
    ReactiveFormsModule,
    // NgModule de Material (aún no todos son standalone)
    MatCardModule,
    // Primitivas del router
    RouterLink,
    RouterOutlet,
    // Componente standalone del proyecto
    MiComponenteStandalone,
  ],
  template: `<!-- Template con acceso a todo lo anterior -->`
})
export class EjemploImportsComponent {}
```

## Arrancando la aplicación sin AppModule

El cambio más visible cuando se abandona el enfoque de módulos es en el punto de entrada de la aplicación. En lugar de `platformBrowserDynamic().bootstrapModule(AppModule)`, se usa `bootstrapApplication()` con el componente raíz:

```typescript
// main.ts - punto de entrada moderno sin NgModule
import { bootstrapApplication } from '@angular/platform-browser';
import { provideRouter } from '@angular/router';
import { provideHttpClient } from '@angular/common/http';
import { AppComponent } from './app/app.component';
import { rutas } from './app/app.routes';

bootstrapApplication(AppComponent, {
  providers: [
    // El router se configura aquí con funciones de configuración
    provideRouter(rutas),
    // HttpClient disponible en toda la aplicación
    provideHttpClient(),
    // Cualquier servicio con providedIn: 'root' se registra automáticamente
    // Los demás pueden declararse aquí
  ]
})
.catch(err => console.error(err));
```

`AppComponent` debe ser standalone. Las funciones `provideRouter()`, `provideHttpClient()`, `provideAnimations()` y similares son el equivalente standalone de importar `RouterModule.forRoot()`, `HttpClientModule` y demás en `AppModule`.

## Ventajas concretas sobre NgModules

**Tree shaking más agresivo**: cuando las dependencias se declaran por componente, el compilador de Angular puede determinar con mayor precisión qué código se usa y qué no. Si un componente no usa `DatePipe`, no se incluye en el bundle de ese componente, aunque otro sí la use.

**Testabilidad mejorada**: en los tests unitarios, ya no es necesario configurar un `TestBed` con el módulo completo. Se puede importar el componente directamente con solo sus dependencias reales o sus mocks:

```typescript
// Configuración de test con componente standalone
await TestBed.configureTestingModule({
  imports: [
    ProductoTarjetaComponent,            // El componente a testear
    provideHttpClientTesting(),          // Mock de HttpClient
  ]
}).compileComponents();
```

**Carga diferida más granular**: un componente standalone puede ser cargado de forma diferida directamente en las rutas del router, sin necesidad de crear un módulo de feature solo para envolver el componente.

**Portabilidad**: un componente standalone con todos sus imports declarados puede copiarse entre proyectos con mínimo esfuerzo. No hay que rastrear en qué módulo estaba declarado y qué exportaba ese módulo.

## Migración de un componente basado en módulo a standalone

El proceso de migración es mecánico y predecible. Angular CLI ofrece un schematic automatizado, pero es útil entender los pasos manuales:

**Paso 1** - Añadir `standalone: true` al decorador y declarar los imports en el propio componente:

```typescript
// ANTES: componente dependiente de módulo
// En usuario-perfil.module.ts:
// declarations: [UsuarioPerfilComponent]
// imports: [CommonModule, ReactiveFormsModule]

// DESPUÉS: componente standalone
import { Component } from '@angular/core';
import { NgIf, NgFor } from '@angular/common';
import { ReactiveFormsModule } from '@angular/forms';

@Component({
  selector: 'app-usuario-perfil',
  standalone: true,                          // Paso 1: añadir standalone
  imports: [NgIf, NgFor, ReactiveFormsModule], // Paso 2: mover imports aquí
  templateUrl: './usuario-perfil.component.html',
  styleUrl: './usuario-perfil.component.css'
})
export class UsuarioPerfilComponent {
  // ... lógica sin cambios
}
```

**Paso 2** - Eliminar el componente de las `declarations` del NgModule. Si era el único componente del módulo, el módulo puede eliminarse por completo.

**Paso 3** - Donde se usaba el NgModule (en `imports` de otros módulos o del AppModule), importar directamente el componente standalone.

Angular CLI automatiza esto con:

```bash
# Migra todos los componentes de la aplicación a standalone de forma automática
ng generate @angular/core:standalone

# O en modo interactivo para elegir qué migrar
ng generate @angular/core:standalone --mode=convert-to-standalone
```

## Puntos clave

- `standalone: true` hace que el componente gestione sus propias dependencias en el array `imports`, eliminando la necesidad de un NgModule intermediario.
- El array `imports` acepta componentes standalone, directivas, pipes y NgModules completos mezclados.
- `bootstrapApplication()` reemplaza a `platformBrowserDynamic().bootstrapModule()` en aplicaciones sin NgModules.
- Los componentes standalone permiten lazy loading directo en el router y mejoran el tree shaking del bundle final.
- La migración es progresiva: un componente standalone puede importar NgModules existentes, y un NgModule puede importar componentes standalone.

## ¿Qué sigue?

En la Parte 4 cerramos el capítulo con Deferrable Views: la capacidad de Angular 17+ para cargar fragmentos de UI de forma diferida, controlando exactamente cuándo y bajo qué condición se descarga el JavaScript de un componente pesado.
