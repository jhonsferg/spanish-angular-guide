# Capítulo 7 - Parte 1: Pipes built-in: date, currency, number, json, async

> **Parte 1 de 4** · Capítulo 7 · PARTE IV - Pipes: Transformando Datos

Los pipes[^1] de Angular son transformadores de datos declarativos que viven directamente en el template. En lugar de preparar cada valor en la clase del componente antes de mostrarlo, le decimos al template: "muestra este valor, pero transformado de esta manera". El resultado es código de clase más limpio y templates más expresivos.

Angular 17+ incluye un conjunto de pipes built-in que cubren los casos de uso más frecuentes: formateo de fechas, divisas, números y depuración de estructuras de datos. Todos son pipes puros por defecto, lo que significa que Angular los ejecuta únicamente cuando el valor de entrada cambia -un detalle de rendimiento que exploraremos a fondo en la Parte 4.

[^1]: **Pipe**: mecanismo de Angular para transformar valores en el template mediante la sintaxis `| nombrePipe`. Se conserva el término en inglés por su uso universal en la comunidad.

## DatePipe: fechas con formato localizado

`DatePipe` convierte un valor de tipo `Date`, un timestamp numérico o una cadena ISO en una representación textual de fecha y hora. Su comportamiento depende del locale[^2] activo en la aplicación.

[^2]: **Locale**: configuración regional que determina el idioma, formato de fechas, separadores decimales y más.

```typescript
import { Component } from '@angular/core';
import { DatePipe } from '@angular/common';

@Component({
  selector: 'app-fechas',
  standalone: true,
  imports: [DatePipe],
  template: `
    <p>{{ hoy | date:'dd/MM/yyyy' }}</p>       <!-- 12/05/2026 -->
    <p>{{ hoy | date:'short' }}</p>             <!-- 5/12/26, 10:30 AM -->
    <p>{{ hoy | date:'longDate' }}</p>          <!-- May 12, 2026 -->
    <p>{{ hoy | date:'EEEE, d MMMM y' }}</p>   <!-- Tuesday, 12 May 2026 -->
  `
})
export class FechasComponent {
  hoy = new Date();
}
```

Los formatos predefinidos (`'short'`, `'medium'`, `'long'`, `'full'`, `'shortDate'`, `'longDate'`, `'shortTime'`, `'longTime'`) son alias convenientes que Angular mapea a patrones Unicode CLDR según el locale activo. Los formatos personalizados como `'dd/MM/yyyy'` usan la sintaxis de patrones Unicode directamente: `d` es el día sin cero a la izquierda, `dd` con él; `M` es el mes numérico, `MMMM` es el nombre completo del mes.

## Configuración global del locale con LOCALE_ID

Por defecto Angular usa el locale `en-US`. Para que `DatePipe`, `CurrencyPipe` y `DecimalPipe` muestren los datos en español, necesitamos registrar los datos del locale y cambiar el token `LOCALE_ID` en la configuración de la aplicación.

```typescript
// main.ts
import { bootstrapApplication } from '@angular/platform-browser';
import { LOCALE_ID } from '@angular/core';
import { registerLocaleData } from '@angular/common';
import localeEs from '@angular/common/locales/es';
import { AppComponent } from './app/app.component';

// Registrar los datos de formato del locale español
registerLocaleData(localeEs);

bootstrapApplication(AppComponent, {
  providers: [
    { provide: LOCALE_ID, useValue: 'es' }
  ]
});
```

Con este cambio, `{{ hoy | date:'longDate' }}` producirá `12 de mayo de 2026` en lugar de `May 12, 2026`, y `CurrencyPipe` usará el formato europeo por defecto. La llamada a `registerLocaleData` es obligatoria: sin ella, Angular tiene los tokens de formato pero no los datos específicos del idioma.

## CurrencyPipe: divisas con símbolo y formato

`CurrencyPipe` formatea un número como una cantidad monetaria. Acepta tres parámetros opcionales: el código de divisa ISO 4217, la representación del símbolo y el formato de dígitos.

```typescript
import { Component } from '@angular/core';
import { CurrencyPipe } from '@angular/common';

@Component({
  selector: 'app-precio',
  standalone: true,
  imports: [CurrencyPipe],
  template: `
    <!-- Resultado con locale 'es': 1.299,99 € -->
    <p>{{ precio | currency:'EUR':'symbol':'1.2-2' }}</p>

    <!-- Resultado con locale 'es': USD 1.299,99 -->
    <p>{{ precio | currency:'USD':'code' }}</p>

    <!-- Sin locale override, usa el activo en la app -->
    <p>{{ precio | currency }}</p>
  `
})
export class PrecioComponent {
  precio = 1299.99;
}
```

El tercer parámetro (`'1.2-2'`) sigue la sintaxis `'minimoEnteros.minimoDecimales-maximoDecimales'`: al menos 1 dígito entero, exactamente 2 decimales. El segundo parámetro `'symbol'` muestra el símbolo nativo de la divisa (`€`, `$`), mientras que `'code'` muestra el código ISO (`EUR`, `USD`) y `'symbol-narrow'` el símbolo más compacto disponible.

## DecimalPipe y PercentPipe

`DecimalPipe` formatea números con control fino sobre separadores y decimales, mientras que `PercentPipe` multiplica el valor por 100 y añade el símbolo `%`.

```typescript
import { Component } from '@angular/core';
import { DecimalPipe, PercentPipe } from '@angular/common';

@Component({
  selector: 'app-numeros',
  standalone: true,
  imports: [DecimalPipe, PercentPipe],
  template: `
    <!-- Con locale 'es': 3.141,593 -->
    <p>{{ pi | number:'1.3-3' }}</p>

    <!-- 0,75 → 75 % (con locale 'es') -->
    <p>{{ tasa | percent:'1.0-1' }}</p>

    <!-- Sin parámetros: usa los defaults del locale -->
    <p>{{ cantidad | number }}</p>
  `
})
export class NumerosComponent {
  pi = 3.14159265;
  tasa = 0.75;
  cantidad = 1234567.89;
}
```

Ambos pipes respetan automáticamente el separador decimal y de miles del locale activo. Con `locale 'es'`, el punto separa los miles y la coma separa los decimales, exactamente al revés que en `en-US`. Esta consistencia automática es una de las razones más importantes para configurar el locale global correctamente desde el inicio del proyecto.

## JsonPipe: inspeccionando estructuras de datos

`JsonPipe` es el mejor amigo de la depuración en desarrollo. Aplica `JSON.stringify()` con indentación al valor y lo muestra como texto preformateado. Es invaluable cuando necesitas verificar qué datos llegan a un componente sin abrir las DevTools.

```typescript
import { Component } from '@angular/core';
import { JsonPipe } from '@angular/common';

@Component({
  selector: 'app-debug',
  standalone: true,
  imports: [JsonPipe],
  template: `
    <!-- Muestra el objeto completo con formato legible -->
    <pre>{{ usuario | json }}</pre>
  `
})
export class DebugComponent {
  usuario = {
    id: 42,
    nombre: 'Ana García',
    roles: ['admin', 'editor'],
    activo: true
  };
}
```

`JsonPipe` es un pipe impuro -se ejecuta en cada ciclo de change detection- porque necesita detectar cambios profundos en objetos y arrays. Esto es aceptable durante el desarrollo, pero conviene eliminarlo antes de producción. Una buena práctica es envolver los bloques de debug en una condición `@if (modoDebug)` controlada por un flag de entorno.

## AsyncPipe: la forma correcta de mostrar datos asíncronos

`AsyncPipe` es el pipe más poderoso del conjunto built-in. Se suscribe automáticamente a un `Observable` o resuelve una `Promise`, devuelve el último valor emitido y, cuando el componente se destruye, cancela la suscripción sin que tengamos que escribir ni una línea de código de limpieza.

```typescript
import { Component, inject } from '@angular/core';
import { AsyncPipe } from '@angular/common';
import { Observable } from 'rxjs';
import { ProductosService } from '../services/productos.service';

interface Producto {
  id: number;
  nombre: string;
  precio: number;
}

@Component({
  selector: 'app-lista-productos',
  standalone: true,
  imports: [AsyncPipe],
  template: `
    @if (productos$ | async; as productos) {
      @for (producto of productos; track producto.id) {
        <div>{{ producto.nombre }} - {{ producto.precio | currency:'EUR' }}</div>
      }
    } @else {
      <p>Cargando productos...</p>
    }
  `
})
export class ListaProductosComponent {
  private productosService = inject(ProductosService);

  // El Observable se declara en la clase, AsyncPipe gestiona la suscripción
  productos$: Observable<Producto[]> = this.productosService.obtenerTodos();
}
```

El patrón `| async; as productos` captura el valor emitido en una variable de template local. Mientras el Observable no ha emitido ningún valor (o ha emitido `null`), el bloque `@if` entra en la rama `@else`, mostrando el estado de carga. Cuando el Observable emite un array, el bloque principal toma el control.

La alternativa manual -suscribirse en `ngOnInit` y guardar el valor en una propiedad- requiere implementar `OnDestroy` y llamar a `subscription.unsubscribe()`. `AsyncPipe` elimina completamente esa responsabilidad. Además, si el componente usa la estrategia `OnPush` de change detection, `AsyncPipe` llama automáticamente a `markForCheck()` cada vez que el Observable emite, garantizando que el componente se actualice aunque Angular no haya planificado revisarlo.

## AsyncPipe con Promises y el caso null

`AsyncPipe` también funciona con Promises nativas. Cuando la promesa se resuelve, el pipe actualiza el template con el valor. Si la promesa aún no se ha resuelto, el pipe devuelve `null`, lo que hace necesario manejar ese caso en el template.

```typescript
import { Component } from '@angular/core';
import { AsyncPipe } from '@angular/common';

@Component({
  selector: 'app-config',
  standalone: true,
  imports: [AsyncPipe],
  template: `
    <!-- 'as config' evita múltiples suscripciones si usáramos async varias veces -->
    @if (configuracion | async; as config) {
      <p>Entorno: {{ config.entorno }}</p>
    } @else {
      <span>Inicializando...</span>
    }
  `
})
export class ConfigComponent {
  configuracion: Promise<{ entorno: string }> = fetch('/assets/config.json')
    .then(res => res.json());
}
```

Un error común es usar `async` varias veces sobre el mismo Observable en el mismo template sin el alias `as`. Cada uso de `| async` crea una suscripción independiente, lo que puede disparar múltiples peticiones HTTP. El alias `as` resuelve esto: suscribirse una sola vez y compartir el valor en todo el bloque `@if`.

## Puntos clave

- `DatePipe`, `CurrencyPipe`, `DecimalPipe` y `PercentPipe` se adaptan automáticamente al locale configurado con `LOCALE_ID` y `registerLocaleData`.
- `JsonPipe` es una herramienta de depuración, no de producción; es impura y tiene costo en rendimiento.
- `AsyncPipe` gestiona la suscripción y la cancelación automáticamente, eliminando el riesgo de memory leaks.
- El patrón `| async; as variable` evita suscripciones duplicadas y maneja el estado `null` de forma elegante.
- Los pipes built-in de Angular 17+ son standalone y se importan individualmente desde `@angular/common`.

## ¿Qué sigue?

En la Parte 2 veremos cómo pasar parámetros a los pipes y cómo encadenar múltiples pipes en una sola expresión de template.
