# Capítulo 9 - Parte 4: Guía de migración: de NgModules a Standalone

> **Parte 4 de 4** · Capítulo 9 · PARTE V - Servicios e Inyección de Dependencias

Migrar una aplicación Angular de módulos a standalone no es un salto al vacío: el Angular Team diseñó un camino gradual, con herramientas automáticas que hacen la mayor parte del trabajo pesado y con soporte para mantener código híbrido durante el proceso. Entender las tres fases de la migración y sus posibles errores nos permite planificarla sin interrumpir el desarrollo del producto.

## La migración automática: ng generate @angular/core:standalone

El CLI de Angular incluye un schematic de migración automática que analiza el código fuente y transforma los módulos en sus equivalentes standalone. No es perfecta al cien por ciento (ninguna herramienta de refactoring lo es), pero maneja correctamente la mayoría de los casos.

```bash
# Ejecutar en la raíz del proyecto
ng generate @angular/core:standalone

# El CLI preguntará en modo interactivo qué tipo de migración ejecutar.
# Podemos especificar la fase con --mode:
ng generate @angular/core:standalone --mode=convert-to-standalone
ng generate @angular/core:standalone --mode=prune-ng-modules
ng generate @angular/core:standalone --mode=standalone-bootstrap
```

El schematic ofrece tres modos que corresponden a las tres fases de migración. La recomendación es ejecutarlos en orden, haciendo commit y ejecutando las pruebas entre cada fase para detectar problemas con contexto claro.

## Fase 1: Convertir declaraciones a standalone

En esta fase, el schematic transforma cada `@Component`, `@Directive` y `@Pipe` declarado en módulos para que sea standalone. Añade `standalone: true` a sus decoradores y construye el array `imports` con las dependencias necesarias, analizando qué usa cada template.

```typescript
// ANTES de la migración - en un NgModule
@Component({
  selector: 'app-usuario-perfil',
  templateUrl: './usuario-perfil.component.html',
  // Sin standalone: true, sin imports
})
export class UsuarioPerfilComponent {
  // ...
}

// El módulo declaraba el componente y sus dependencias
@NgModule({
  declarations: [UsuarioPerfilComponent],
  imports: [CommonModule, ReactiveFormsModule, SharedModule],
})
export class UsuariosModule {}
```

```typescript
// DESPUÉS de la Fase 1 - el componente es standalone
@Component({
  selector: 'app-usuario-perfil',
  standalone: true,
  // El schematic analiza el template y añade los imports necesarios
  imports: [NgIf, NgFor, ReactiveFormsModule, TarjetaComponent, FechaPipe],
  templateUrl: './usuario-perfil.component.html',
})
export class UsuarioPerfilComponent {
  // ...
}

// El módulo aún existe, pero ahora importa en lugar de declarar
@NgModule({
  imports: [UsuarioPerfilComponent], // Pasó de declarations a imports
})
export class UsuariosModule {}
```

Después de la Fase 1, los módulos siguen existiendo pero ya no declaran componentes: los importan. Esto permite que el código funcione mientras completamos la migración.

## Fase 2: Eliminar módulos innecesarios

Una vez que todas las declaraciones son standalone, muchos módulos se vuelven superfluos: solo importan y re-exportan cosas que ahora se importan directamente. El schematic de pruning elimina estos módulos vacíos y actualiza las referencias.

```typescript
// ANTES de la Fase 2 - módulo que solo hace de intermediario
@NgModule({
  imports: [
    UsuarioPerfilComponent,    // standalone
    UsuarioListaComponent,     // standalone
    UsuarioFormularioComponent // standalone
  ],
  exports: [
    UsuarioPerfilComponent,
    UsuarioListaComponent,
    UsuarioFormularioComponent,
  ],
})
export class UsuariosModule {}

// Otros módulos que importaban UsuariosModule ahora importarán
// directamente los componentes que necesitan.
```

El schematic rastrea todos los lugares donde se importa `UsuariosModule` y reemplaza la importación por los componentes standalone que realmente se usan en cada contexto. Si `UsuariosModule` tenía providers en su array `providers`, el schematic los mueve al lugar apropiado.

## Fase 3: Bootstrap standalone

La última fase transforma el punto de entrada de la aplicación. Reemplaza `platformBrowserDynamic().bootstrapModule(AppModule)` por `bootstrapApplication()` y migra los providers del `AppModule` al formato funcional en `app.config.ts` (→ Ver Capítulo 2, Parte 4).

```typescript
// ANTES - main.ts con AppModule
import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';
import { AppModule } from './app/app.module';

platformBrowserDynamic().bootstrapModule(AppModule)
  .catch(err => console.error(err));
```

```typescript
// DESPUÉS - main.ts standalone
import { bootstrapApplication } from '@angular/platform-browser';
import { AppComponent } from './app/app.component';
import { configuracionApp } from './app/app.config';

bootstrapApplication(AppComponent, configuracionApp)
  .catch((error: unknown) => console.error('Error al iniciar:', error));
```

```typescript
// app.config.ts generado por el schematic
import { ApplicationConfig, importProvidersFrom } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient } from '@angular/common/http';
import { rutasApp } from './app.routes';

export const configuracionApp: ApplicationConfig = {
  providers: [
    provideRouter(rutasApp),
    provideHttpClient(),
    // Providers de módulos que no tienen equivalente funcional aún
    importProvidersFrom(/* módulos legacy que quedaron */),
  ],
};
```

## Migración manual: cuándo y cómo

Hay casos donde la migración automática no es suficiente o no es conveniente: proyectos muy grandes donde queremos migrar por feature module, módulos con lógica compleja en `forRoot()`, o cuando queremos aprovechar la migración para refactorizar al mismo tiempo.

La migración manual sigue el mismo orden de fases pero con control total:

```typescript
// Paso 1: Hacer standalone el componente
@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [], // Empezamos vacío - el compilador nos dirá qué falta
  templateUrl: './dashboard.component.html',
})
export class DashboardComponent { /* ... */ }
```

```typescript
// Paso 2: Mover el componente de declarations a imports en su módulo
@NgModule({
  // declarations: [DashboardComponent], // ← Eliminamos esto
  imports: [
    DashboardComponent,   // ← Lo movemos aquí
    CommonModule,
    RouterModule,
  ],
})
export class DashboardModule {}
```

```typescript
// Paso 3: El compilador señala qué le falta al componente.
// Resolvemos cada error añadiendo el import correcto:
@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [
    NgIf, NgFor,          // De @angular/common
    RouterLink,            // De @angular/router
    GraficoComponent,      // Componente propio (ya standalone)
    FormatoNumeroPipe,     // Pipe propio (ya standalone)
  ],
  templateUrl: './dashboard.component.html',
})
export class DashboardComponent { /* ... */ }
```

Este proceso iterativo - hacer standalone, compilar, resolver errores, repetir - es el más seguro para proyectos grandes porque mantenemos el código funcionando en cada paso.

## Compatibilidad híbrida durante la transición

Una de las mejores decisiones de diseño del equipo de Angular fue garantizar compatibilidad bidireccional: un módulo puede importar componentes standalone, y un componente standalone puede usar `importProvidersFrom` para incluir providers de módulos. Esto hace que la transición sea gradual sin bloqueos.

```typescript
// Un módulo viejo puede importar componentes standalone sin problemas
@NgModule({
  declarations: [
    ComponenteViejoA,  // Aún en NgModule
    ComponenteViejoB,
  ],
  imports: [
    ComponenteNuevoStandalone,  // Standalone en un NgModule - válido
    DirectivaNuevaStandalone,   // También válido
    CommonModule,
  ],
})
export class ModuloMixto {}
```

Esta compatibilidad híbrida significa que podemos migrar componente por componente, feature por feature, en el orden que la prioridad del negocio dicte.

## Errores comunes y cómo evitarlos

**Error 1: Olvidar importar NgIf / NgFor después de migrar**
Antes, `CommonModule` en el módulo lo resolvía todo. Al migrar, el template usa `@if` y `@for` (sintaxis nueva, no requieren imports) o `NgIf`/`NgFor` (requieren import explícito). La solución: preferir la nueva sintaxis de control (`@if`, `@for`) en los componentes migrados.

**Error 2: Providers duplicados después de la migración**
Si un provider estaba en múltiples módulos que ahora se eliminaron, puede terminar registrado varias veces. El schematic intenta consolidarlos, pero en migración manual debemos verificar manualmente.

**Error 3: Módulos con `forRoot()` que configuran providers**
`RouterModule.forRoot()` y similares registran providers con configuración. Al migrar, debemos reemplazarlos por sus equivalentes funcionales (`provideRouter(rutas, ...características)`) o usar `importProvidersFrom()` como puente temporal.

```typescript
// Error común: importar un módulo con forRoot() en el array imports de un componente
@Component({
  standalone: true,
  imports: [
    RouterModule.forRoot(rutas), // ❌ forRoot() no puede usarse en imports de componente
  ],
})

// Correcto: los providers de forRoot() van en app.config.ts
export const configuracionApp: ApplicationConfig = {
  providers: [
    provideRouter(rutas), // ✅ Equivalente funcional en el lugar correcto
  ],
};
```

**Error 4: Tests que dependen de TestBed con módulos**
Los tests unitarios configurados con `TestBed.configureTestingModule({ declarations: [...] })` necesitarse actualizar. Los componentes standalone se configuran con `imports` en lugar de `declarations`:

```typescript
// Test actualizado para componentes standalone
TestBed.configureTestingModule({
  imports: [ComponenteStandalone], // En lugar de declarations
  providers: [/* providers necesarios */],
});
```

## Puntos clave

- La migración automática con `ng generate @angular/core:standalone` tiene tres modos: convertir declaraciones, eliminar módulos y migrar el bootstrap
- Las tres fases deben ejecutarse en orden, con commits y pruebas entre cada una
- La compatibilidad híbrida permite mezclar módulos y componentes standalone indefinidamente durante la transición
- Los errores más comunes son imports faltantes en templates, providers duplicados y módulos con `forRoot()` mal migrados
- La nueva sintaxis de control (`@if`, `@for`) es preferible durante la migración porque no requiere imports adicionales

## ¿Qué sigue?

En el Capítulo 10 profundizamos en el sistema de inyección de dependencias: jerarquía de inyectores, providers con alcance de componente, y patrones avanzados como el uso de tokens de inyección para configuración.
