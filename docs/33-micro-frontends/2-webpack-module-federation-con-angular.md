# Capítulo 33 - Parte 2: Webpack Module Federation con Angular

> **Parte 2 de 4** · Capítulo 33 · PARTE XIV - Arquitectura y Patrones Avanzados

Module Federation es una funcionalidad de Webpack 5 que permite que un bundle de JavaScript cargue código de otro bundle en runtime, como si fuera parte del mismo proyecto. Para los micro-frontends Angular es, a la fecha, el mecanismo más maduro y ampliamente usado. La librería `@angular-architects/module-federation` envuelve esta funcionalidad con una API amigable para Angular y resuelve la mayoría de los problemas comunes de configuración.

## El modelo mental

Antes de entrar en código, necesitamos entender los dos roles en una arquitectura Module Federation:

**Host (Shell)**: la aplicación principal. Conoce los remotes y sabe dónde encontrarlos. Define en su configuración de Webpack qué remotes existen y en qué URL viven. Cuando el usuario navega a una ruta que pertenece a un MFE, el Host descarga el `remoteEntry.js` de ese MFE y carga el módulo expuesto.

**Remote (MFE)**: una aplicación Angular que expone partes de sí misma (módulos, componentes, rutas) para que el Host las consuma. Define en su configuración de Webpack qué expone y bajo qué nombre.

La magia es que el Remote ni sabe ni le importa quién lo consume. Podría ser consumido por múltiples Hosts.

## Configuración del proyecto: instalación

```bash
# En el proyecto Host (shell)
ng add @angular-architects/module-federation \
  --project=shell \
  --port=4200 \
  --type=host

# En el proyecto Remote (MFE de productos)
ng add @angular-architects/module-federation \
  --project=productos-mfe \
  --port=4201 \
  --type=remote
```

El schematic genera automáticamente el `webpack.config.js` en cada proyecto y modifica `angular.json` para usar el builder de Webpack personalizado.

## Configuración del Remote

El Remote define qué expone. La configuración es la parte más importante:

```javascript
// productos-mfe/webpack.config.js
const { shareAll, withModuleFederationPlugin } = require(
  '@angular-architects/module-federation/webpack'
);

module.exports = withModuleFederationPlugin({
  name: 'productosMfe',

  exposes: {
    // './NombrePublico': 'ruta al archivo que se expone'
    './ProductosModule': './src/app/productos/productos.module.ts',
    './ProductoDetalleComponent':
      './src/app/productos/detalle/producto-detalle.component.ts',
  },

  shared: {
    ...shareAll({
      singleton: true,
      strictVersion: true,
      requiredVersion: 'auto'
    })
  }
});
```

El archivo generado en el Remote es el `remoteEntry.js`. Este archivo es el manifiesto público del Remote: lista qué expone y qué dependencias compartidas tiene. El Host lo descarga primero para saber qué puede pedir.

## Configuración del Host

El Host declara todos sus Remotes y sus URLs. En desarrollo, esas URLs apuntan a `localhost`. En producción, apuntan a los dominios reales de cada MFE:

```javascript
// shell/webpack.config.js
const { shareAll, withModuleFederationPlugin } = require(
  '@angular-architects/module-federation/webpack'
);

module.exports = withModuleFederationPlugin({
  remotes: {
    // 'nombreLocal': 'nombreGlobal@URL/remoteEntry.js'
    productosMfe: 'productosMfe@http://localhost:4201/remoteEntry.js',
    pedidosMfe: 'pedidosMfe@http://localhost:4202/remoteEntry.js',
    adminMfe: 'adminMfe@http://localhost:4203/remoteEntry.js',
  },

  shared: {
    ...shareAll({
      singleton: true,
      strictVersion: true,
      requiredVersion: 'auto'
    })
  }
});
```

## Las rutas lazy en el Host

Con la configuración de Webpack lista, el Host puede cargar los módulos del Remote en sus rutas lazy como si fueran módulos locales:

```typescript
// shell/src/app/app.routes.ts
import { Routes } from '@angular/router';
import { loadRemoteModule } from '@angular-architects/module-federation';

export const appRoutes: Routes = [
  {
    path: 'productos',
    loadChildren: () =>
      loadRemoteModule({
        type: 'module',
        remoteEntry: 'http://localhost:4201/remoteEntry.js',
        exposedModule: './ProductosModule'
      }).then(modulo => modulo.ProductosModule)
  },
  {
    path: 'pedidos',
    loadChildren: () =>
      loadRemoteModule({
        type: 'module',
        remoteEntry: 'http://localhost:4202/remoteEntry.js',
        exposedModule: './PedidosModule'
      }).then(modulo => modulo.PedidosModule)
  },
  { path: '', redirectTo: 'productos', pathMatch: 'full' }
];
```

`loadRemoteModule` hace varias cosas de forma transparente: primero descarga el `remoteEntry.js`, luego negocia las dependencias compartidas, y finalmente carga el módulo específico que pedimos.

## Compartir dependencias Angular: la clave del rendimiento

El punto más crítico de toda la configuración es el bloque `shared`. Si no lo configuramos bien, el usuario descarga Angular completo múltiples veces (una por cada MFE), lo cual es inaceptable.

```javascript
// Configuración shared más explícita para entender qué ocurre
shared: share({
  '@angular/core': {
    singleton: true,       // Solo una instancia en toda la página
    strictVersion: true,   // Las versiones deben ser compatibles
    requiredVersion: 'auto' // Toma la versión del package.json automáticamente
  },
  '@angular/common': {
    singleton: true,
    strictVersion: true,
    requiredVersion: 'auto'
  },
  '@angular/router': {
    singleton: true,
    strictVersion: true,
    requiredVersion: 'auto'
  },
  '@angular/forms': {
    singleton: true,
    strictVersion: true,
    requiredVersion: 'auto'
  },
  '@ngrx/store': {
    singleton: true,
    strictVersion: false  // NgRx puede ser más permisivo
  }
})
```

`singleton: true` es el parámetro crítico. Le dice a Webpack que aunque múltiples bundles declaren esta dependencia, solo debe cargar una instancia. El primer bundle que la necesite la carga; los siguientes la reutilizan.

## El problema del versioning

`strictVersion: true` significa que si el Host usa Angular 17.3 y el Remote usa Angular 17.1, Webpack lanzará un error en runtime porque las versiones no coinciden exactamente. Esto puede parecer restrictivo, pero es una protección importante: mezclar versiones de Angular en el mismo proceso de JavaScript causa bugs sutiles y difíciles de diagnosticar.

La consecuencia organizacional es que todos los MFEs de una organización deben actualizar Angular en sincronía (o de forma muy coordinada). No es un problema técnico sino de proceso:

```bash
# En el monorepo con Nx, esto actualiza todo a la vez
nx migrate @angular/core@latest
nx migrate --run-migrations
```

Con `strictVersion: false`, Webpack emitirá solo un warning y usará la versión que encuentre primero. Es menos seguro pero permite más flexibilidad en el versionado entre MFEs.

## El Remote como aplicación Angular independiente

Una ventaja importante: el MFE de Productos es una aplicación Angular completamente funcional por sí sola. Tiene su propio `main.ts`, puede correr en `localhost:4201` de forma independiente, tiene sus propias rutas y puede bootstrappearse solo:

```typescript
// productos-mfe/src/app/productos/productos.module.ts
import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { ProductosListaComponent } from './lista/productos-lista.component';
import { ProductoDetalleComponent } from './detalle/producto-detalle.component';

const rutas: Routes = [
  { path: '', component: ProductosListaComponent },
  { path: ':id', component: ProductoDetalleComponent }
];

@NgModule({
  imports: [RouterModule.forChild(rutas)],
  declarations: [ProductosListaComponent, ProductoDetalleComponent]
})
export class ProductosModule {}
```

Cuando el Remote corre en su puerto propio, usa `RouterModule.forRoot`. Cuando es consumido por el Host, usa `RouterModule.forChild`. La misma base de código sirve para ambos escenarios.

## Configuración para producción

En producción, las URLs hardcodeadas en las rutas son un problema. La solución es externalizar la configuración en un archivo de manifiesto:

```typescript
// shell/src/app/app.config.ts
import { ApplicationConfig } from '@angular/core';
import { provideRouter } from '@angular/router';
import { loadRemoteModule } from '@angular-architects/module-federation';

// La URL se lee de variables de entorno o configuración externa
const urlProductosMfe = (window as Window & { ENV?: Record<string, string> })
  .ENV?.['PRODUCTOS_MFE_URL'] ?? 'http://localhost:4201/remoteEntry.js';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter([
      {
        path: 'productos',
        loadChildren: () =>
          loadRemoteModule({
            type: 'module',
            remoteEntry: urlProductosMfe,
            exposedModule: './ProductosModule'
          }).then(m => m.ProductosModule)
      }
    ])
  ]
};
```

En el pipeline de CI, el shell se construye con las variables de entorno de producción. O bien, el shell carga un archivo `mfe-manifest.json` desde el servidor antes de inicializarse.

## Puntos clave

- Module Federation de Webpack 5 permite que un Host (Shell) cargue módulos Angular de un Remote (MFE) en runtime, sin necesidad de conocer el código del Remote en tiempo de compilación.
- La configuración `shared` con `singleton: true` y `strictVersion: true` es crítica para evitar que Angular se descargue múltiples veces y para prevenir bugs por incompatibilidad de versiones.
- `loadRemoteModule` en las rutas lazy del Host es la API principal para consumir código remoto; funciona como un `loadChildren` normal pero con descarga en runtime desde un servidor externo.
- Los Remotes son aplicaciones Angular independientes y funcionales: pueden correr solos para desarrollo y testing, y además ser consumidos por el Host en producción.
- El versioning coordinado de Angular entre todos los MFEs es un requisito organizacional que debe gestionarse como parte del proceso del equipo, no solo como decisión técnica.

## ¿Qué sigue?

En la siguiente parte exploraremos Native Federation, la alternativa a Module Federation que usa esbuild en lugar de Webpack, alineada con la dirección por defecto de Angular 17+.
