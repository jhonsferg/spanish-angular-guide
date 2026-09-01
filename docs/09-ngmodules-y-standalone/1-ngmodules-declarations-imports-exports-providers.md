# Capítulo 9 - Parte 1: NgModules: declarations, imports, exports, providers

> **Parte 1 de 4** · Capítulo 9 · PARTE V - Servicios e Inyección de Dependencias

`@NgModule` fue durante años la unidad de organización fundamental de Angular. Aunque los componentes standalone (→ Ver Capítulo 4, Parte 3) han reducido la necesidad de módulos para código nuevo, los `NgModule` siguen siendo la realidad de millones de líneas de código Angular existente. Entender su anatomía no es solo arqueología: es imprescindible para trabajar en proyectos reales, para integrar librerías que aún los requieren, y para llevar a cabo migraciones informadas.

## La anatomía de @NgModule

Un módulo Angular es una clase decorada con `@NgModule` que agrupa piezas relacionadas de la aplicación. El decorador acepta un objeto de metadatos con cuatro propiedades principales, cada una con un propósito preciso y un conjunto de errores comunes asociados a usarla mal.

```typescript
import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClientModule } from '@angular/common/http';

import { ProductoCardComponent } from './components/producto-card.component';
import { PrecioFormateadoPipe } from './pipes/precio-formateado.pipe';
import { ProductoDirectivaDestacado } from './directives/destacado.directive';
import { ProductosService } from './services/productos.service';
import { CatalogoComponent } from './components/catalogo.component';

@NgModule({
  // Solo componentes, directivas y pipes propios de este módulo
  declarations: [
    ProductoCardComponent,
    PrecioFormateadoPipe,
    ProductoDirectivaDestacado,
    CatalogoComponent
  ],
  // Otros módulos cuyas exportaciones necesitamos usar en templates de este módulo
  imports: [
    CommonModule,   // ngIf, ngFor, AsyncPipe, etc.
    HttpClientModule
  ],
  // Qué declaraciones de este módulo queremos que otros módulos puedan usar
  exports: [
    ProductoCardComponent,
    PrecioFormateadoPipe
    // CatalogoComponent NO se exporta: es de uso interno
  ],
  // Servicios registrados en el inyector de este módulo
  providers: [
    ProductosService
  ]
})
export class ProductosModule {}
```

Cada propiedad tiene una responsabilidad específica. `declarations` registra las piezas de UI propias. `imports` trae piezas de otros módulos. `exports` decide cuáles de las propias piezas son visibles hacia afuera. `providers` registra servicios en el inyector del módulo.

## declarations: qué va aquí y qué no

`declarations` acepta únicamente tres tipos de elementos: componentes, directivas y pipes. Los servicios, los módulos y las clases utilitarias no van aquí. Un error frecuente es intentar declarar un servicio en `declarations`, lo que produce un error de compilación críptico en lugar de uno claro.

La regla de exclusividad es absoluta: cada componente, directiva y pipe puede estar declarado en exactamente un módulo. Si intentas declarar el mismo componente en dos módulos diferentes, Angular lanza un error en tiempo de compilación. Cuando varias partes de la aplicación necesitan usar un componente, la solución correcta es exportarlo desde su módulo y que los demás módulos importen ese módulo.

## imports: trayendo el mundo exterior

`imports` acepta módulos. Cuando importas un módulo, ganas acceso a todo lo que ese módulo exporta en sus `exports`. No ganas acceso a sus `declarations` que no están en `exports`, ni a sus `providers` (que se registran a nivel de inyector y son visibles globalmente para los módulos eager).

Un error clásico es importar un módulo pero olvidar que el componente que necesitas está en los `exports` del módulo importado, no en sus `declarations`. La solución es siempre revisar qué exporta el módulo importado, no qué declara.

## exports: la API pública del módulo

`exports` define qué piezas del módulo son accesibles desde fuera. Solo lo que está en `exports` puede usarse en los templates de otros módulos que importen este. El patrón de buen diseño es hacer que `exports` sea pequeño y deliberado: solo exponer lo que otras partes de la aplicación realmente necesitan.

También es posible reexportar módulos completos en `exports`. Esto es lo que hace `SharedModule` con `CommonModule`: importa `CommonModule` para uso interno y lo reexporta para que cualquier módulo que importe `SharedModule` también obtenga `CommonModule` sin tener que declararlo explícitamente.

```typescript
@NgModule({
  imports: [CommonModule, ReactiveFormsModule],
  declarations: [/* componentes compartidos */],
  // Reexportamos los módulos para no forzar a los consumidores a importarlos por separado
  exports: [CommonModule, ReactiveFormsModule, /* componentes compartidos */]
})
export class SharedModule {}
```

## AppModule vs módulos de funcionalidad

`AppModule` es el módulo raíz que Angular usa para arrancar la aplicación. Históricamente contenía todo, pero en aplicaciones bien organizadas es un módulo delgado que solo declara `AppComponent` e importa los módulos de funcionalidad. Los módulos de funcionalidad encapsulan un dominio específico: `ProductosModule`, `UsuariosModule`, `PedidosModule`.

```typescript
import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { AppComponent } from './app.component';
import { ProductosModule } from './productos/productos.module';

@NgModule({
  declarations: [AppComponent], // Solo el componente raíz
  imports: [
    BrowserModule,      // Solo va en AppModule - provee el DOM y servicios base
    ProductosModule     // Módulo de funcionalidad
  ],
  bootstrap: [AppComponent]
})
export class AppModule {}
```

`BrowserModule` es especial: solo puede importarse una vez, en `AppModule`. Provee las directivas de `CommonModule` más servicios específicos del navegador. Los módulos de funcionalidad nunca deben importar `BrowserModule`; usan `CommonModule` en su lugar.

## Errores comunes con NgModules

Olvidar declarar un componente hace que Angular no reconozca su selector en ningún template y lanza el error "X is not a known element". Importar un módulo sin exportar el componente que se necesita hace que el componente parezca inexistente para el módulo importador. Declarar el mismo componente en dos módulos genera un error de compilación sobre "declarados en múltiples NgModules".

## Cuándo todavía necesitas NgModules en 2026

Los módulos siguen siendo necesarios en tres escenarios concretos. El primero: cuando integras librerías de terceros que exponen sus componentes a través de NgModules (Angular Material usa esta arquitectura). El segundo: cuando tienes código existente basado en módulos que aún no ha sido migrado. El tercero: cuando usas lazy loading con módulos (aunque Angular 15+ permite lazy loading de componentes standalone sin módulos, → Ver Capítulo 11, Parte 1).

Para código nuevo, la recomendación oficial de Angular desde la versión 17 es usar componentes standalone. Los NgModules no desaparecerán a corto plazo, pero la dirección del framework es clara.

## Puntos clave

- `declarations` solo acepta componentes, directivas y pipes; cada uno puede pertenecer a un único módulo.
- `imports` trae las exportaciones de otros módulos; no da acceso a lo que esos módulos no exportan.
- `exports` define la API pública del módulo; los módulos también pueden reexportarse enteros.
- `AppModule` debe ser delgado: solo `AppComponent` y los módulos que arrancan la app.
- `BrowserModule` va solo en `AppModule`; los módulos de funcionalidad usan `CommonModule`.

## ¿Qué sigue?

En la Parte 2 vemos cómo organizar los módulos en tres categorías con responsabilidades bien definidas: Core, Shared y Feature, y por qué esta organización previene problemas comunes de arquitectura.
