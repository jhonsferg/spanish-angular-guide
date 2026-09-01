# Capítulo 7 - Parte 3: Creando pipes personalizados con PipeTransform

> **Parte 3 de 4** · Capítulo 7 · PARTE IV - Pipes: Transformando Datos

Los pipes built-in cubren los casos de formateo más habituales, pero cada aplicación tiene sus propias reglas de presentación. Una tienda muestra precios con descuento tachados; una aplicación de recursos humanos filtra empleados por departamento; un blog trunca los títulos largos con puntos suspensivos. Crear un pipe personalizado en Angular es sencillo y el resultado es reutilizable en cualquier template de la aplicación.

## La interfaz PipeTransform y el decorador @Pipe

Todo pipe personalizado es una clase TypeScript decorada con `@Pipe` que implementa la interfaz `PipeTransform`. Esta interfaz exige un único método: `transform()`, que recibe el valor de entrada y cualquier número de parámetros adicionales, y devuelve el valor transformado.

```typescript
import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'truncarTexto',   // Nombre que se usa en el template: | truncarTexto
  standalone: true,        // Sin NgModule, disponible para importar directamente
  pure: true               // Por defecto es true; se incluye aquí por claridad
})
export class TruncarTextoPipe implements PipeTransform {

  // Angular llama a este método con el valor y los parámetros del template
  transform(valor: string, limite: number = 100, elipsis: string = '…'): string {
    if (!valor) return '';
    if (valor.length <= limite) return valor;

    // Trunca en el límite y añade el carácter de elipsis
    return valor.substring(0, limite).trimEnd() + elipsis;
  }
}
```

El decorador `@Pipe` registra la clase en el sistema de pipes de Angular y le asigna el nombre que se usará en el template. La propiedad `standalone: true` permite importar el pipe directamente en los componentes que lo necesitan, exactamente igual que los pipes built-in de `@angular/common`.

## Ejemplo completo: pipe truncarTexto en acción

Con el pipe definido, su uso en el template es inmediato. Lo importamos en el array `imports` del componente y lo aplicamos con la sintaxis estándar de pipes.

```typescript
import { Component } from '@angular/core';
import { TruncarTextoPipe } from '../pipes/truncar-texto.pipe';

@Component({
  selector: 'app-tarjeta-articulo',
  standalone: true,
  imports: [TruncarTextoPipe],
  template: `
    <!-- Trunca a 80 caracteres con elipsis por defecto -->
    <h3>{{ articulo.titulo | truncarTexto:80 }}</h3>

    <!-- Trunca a 150 caracteres con un indicador personalizado -->
    <p>{{ articulo.resumen | truncarTexto:150:'... [leer más]' }}</p>

    <!-- Sin parámetros: usa los valores por defecto (100 caracteres, '…') -->
    <span>{{ articulo.categoria | truncarTexto }}</span>
  `
})
export class TarjetaArticuloComponent {
  articulo = {
    titulo: 'Angular 17: Guía completa de las nuevas características del framework más potente del ecosistema frontend',
    resumen: 'En esta entrega exploramos en profundidad todas las novedades introducidas en Angular 17, incluyendo el nuevo bloque @if, los Deferrable Views y las mejoras en el rendimiento del compilador.',
    categoria: 'Framework'
  };
}
```

El pipe es puro, así que Angular solo lo invoca cuando el valor de `articulo.titulo` o los parámetros cambian. Para una tarjeta estática como esta, el pipe se ejecutará exactamente una vez por ciclo de renderizado inicial y no volverá a ejecutarse hasta que los datos cambien.

## Pipe con tipado genérico: filtrarPor

Un caso muy frecuente es filtrar arrays de objetos en el template. La versión más poderosa de este pipe usa genéricos de TypeScript para que funcione con cualquier tipo de objeto.

```typescript
import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'filtrarPor',
  standalone: true,
  pure: true
})
export class FiltrarPorPipe implements PipeTransform {

  // T es el tipo de cada elemento del array
  // K es una clave válida de T (keyof T garantiza seguridad de tipos)
  transform<T>(
    items: T[],
    campo: keyof T,
    termino: string | number | boolean
  ): T[] {
    if (!items || !termino) return items;

    const terminoStr = String(termino).toLowerCase();

    return items.filter(item => {
      const valorCampo = item[campo];
      return String(valorCampo).toLowerCase().includes(terminoStr);
    });
  }
}
```

El uso de `keyof T` como tipo del parámetro `campo` hace que TypeScript rechace en tiempo de compilación cualquier clave que no exista en el tipo del array. Si el array es `Producto[]` y `Producto` no tiene una propiedad `nombreInexistente`, el compilador lo reportará como error, no el runtime.

```typescript
import { Component, signal } from '@angular/core';
import { FiltrarPorPipe } from '../pipes/filtrar-por.pipe';
import { FormsModule } from '@angular/forms';

interface Producto {
  id: number;
  nombre: string;
  categoria: string;
  precio: number;
}

@Component({
  selector: 'app-catalogo',
  standalone: true,
  imports: [FiltrarPorPipe, FormsModule],
  template: `
    <input
      type="text"
      placeholder="Buscar por nombre..."
      [(ngModel)]="terminoBusqueda"
    />

    @for (
      producto of productos | filtrarPor:'nombre':terminoBusqueda;
      track producto.id
    ) {
      <div>{{ producto.nombre }} - {{ producto.categoria }}</div>
    }
  `
})
export class CatalogoComponent {
  terminoBusqueda = '';

  productos: Producto[] = [
    { id: 1, nombre: 'Teclado mecánico', categoria: 'Periféricos', precio: 89 },
    { id: 2, nombre: 'Monitor 4K',       categoria: 'Pantallas',   precio: 349 },
    { id: 3, nombre: 'Ratón inalámbrico',categoria: 'Periféricos', precio: 45 },
  ];
}
```

Aquí hay algo importante que señalar: este pipe filtra en el template, no en el servicio. Eso significa que el array completo debe estar disponible en el componente desde el inicio. Si la lista tiene miles de elementos, el filtrado en el servidor -combinado con `HttpClient`- es la solución correcta. Para listas de decenas o unos pocos cientos de elementos, este patrón funciona perfectamente. Volveremos al impacto en rendimiento de los pipes de filtrado en la Parte 4.

## Generando pipes con Angular CLI

Angular CLI genera el archivo del pipe con la estructura base y su archivo de spec de pruebas:

```bash
ng generate pipe pipes/truncar-texto
# Atajo equivalente:
ng g p pipes/truncar-texto
```

El CLI detecta automáticamente si el proyecto usa componentes standalone y genera el pipe con `standalone: true`. Si necesitas un pipe para un NgModule específico, usa la opción `--module`:

```bash
ng g p pipes/filtrar-por --module=productos
```

## Registro en componente standalone vs NgModule

En un componente standalone, el pipe se importa directamente en el array `imports` del decorador `@Component`, como hemos visto en todos los ejemplos anteriores. No hay ningún módulo intermedio.

```typescript
// En un componente standalone - forma moderna
@Component({
  standalone: true,
  imports: [TruncarTextoPipe, FiltrarPorPipe], // Pipes importados directamente
  // ...
})
export class MiComponenteComponent {}
```

Si el proyecto usa NgModules -ya sea por decisión arquitectónica o por ser una aplicación existente en migración- el pipe se declara en el array `declarations` del módulo que lo posee y se exporta si debe estar disponible fuera de ese módulo:

```typescript
// En un NgModule - forma clásica
@NgModule({
  declarations: [TruncarTextoPipe, FiltrarPorPipe],
  exports:      [TruncarTextoPipe, FiltrarPorPipe], // Necesario para usarlos fuera
})
export class PipesModule {}
```

La diferencia de fondo es que en el mundo standalone la dependencia es explícita a nivel de componente, mientras que en NgModules la dependencia es implícita: si el módulo está importado, todos sus exports están disponibles. Ambos enfoques funcionan, pero el modelo standalone es el recomendado en Angular 17+.

## Pipes con dependencias inyectadas

Los pipes son clases de Angular y participan en el sistema de inyección de dependencias. Pueden inyectar servicios exactamente igual que lo hacen los componentes.

```typescript
import { Pipe, PipeTransform, inject } from '@angular/core';
import { ConfiguracionService } from '../services/configuracion.service';

@Pipe({
  name: 'formatearMoneda',
  standalone: true,
  pure: true
})
export class FormatearMonedaPipe implements PipeTransform {

  // Inyectamos el servicio que conoce la divisa activa del usuario
  private config = inject(ConfiguracionService);

  transform(valor: number): string {
    const divisa = this.config.divisaActiva();
    const locale = this.config.localeActivo();

    return new Intl.NumberFormat(locale, {
      style: 'currency',
      currency: divisa
    }).format(valor);
  }
}
```

Este pipe es puro a pesar de consultar un servicio. Mientras el valor de entrada (`valor`) no cambie entre dos ciclos de change detection, Angular no lo re-ejecutará, incluso si `ConfiguracionService` ha cambiado internamente. Si necesitamos que el pipe reaccione a cambios en el servicio, tendríamos que hacerlo impuro (`pure: false`) -con el costo en rendimiento que eso implica, tema central de la Parte 4- o bien pasar los parámetros de configuración directamente al pipe para que sean parte de su entrada.

## Puntos clave

- Todo pipe personalizado es una clase con `@Pipe({ name, standalone, pure })` que implementa `PipeTransform` con el método `transform()`.
- La propiedad `name` del decorador define cómo se usa el pipe en el template con `| nombre`.
- En componentes standalone se importa directamente en `imports: []`; en NgModules se declara y exporta desde el módulo.
- El uso de genéricos (`<T>`, `keyof T`) hace que los pipes de colecciones sean seguros en tipos y reutilizables.
- Los pipes pueden inyectar servicios, pero la pureza del pipe determina con qué frecuencia Angular invoca `transform()`.

## ¿Qué sigue?

La Parte 4 explica la diferencia fundamental entre pipes puros e impuros, su impacto en el ciclo de change detection y las alternativas que evitan los problemas de rendimiento de los pipes impuros.
