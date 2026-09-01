# Capítulo 8 - Parte 2: Creando e inyectando servicios: @Injectable y providedIn

> **Parte 2 de 4** · Capítulo 8 · PARTE V - Servicios e Inyección de Dependencias

Los servicios en Angular son clases simples de TypeScript decoradas con `@Injectable`. Su propósito es encapsular lógica que no pertenece a ningún componente en particular: acceso a datos, cálculos compartidos, comunicación entre componentes no relacionados. El decorador no hace magia: le dice al compilador de Angular que esta clase puede participar en el sistema de inyección de dependencias, tanto como proveedora como consumidora de otras dependencias.

## Creando un servicio con Angular CLI

La forma recomendada de crear un servicio es mediante Angular CLI, que genera el archivo y su spec de prueba automáticamente:

```bash
ng generate service core/services/productos
# Atajo: ng g s core/services/productos
```

Esto crea `productos.service.ts` con la estructura base. Partamos de ahí y construyamos un servicio completo que gestione un catálogo de productos con tipado estricto:

```typescript
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map } from 'rxjs';

// Definimos la interfaz del modelo fuera del servicio para reutilizarla
export interface Producto {
  id: number;
  nombre: string;
  precio: number;
  stock: number;
  categoria: string;
}

export interface ProductoConDescuento extends Producto {
  precioFinal: number;
  porcentajeDescuento: number;
}

@Injectable({
  providedIn: 'root' // Singleton global: una sola instancia para toda la app
})
export class ProductosService {
  // Inyección moderna: inject() en el cuerpo de la clase
  private http = inject(HttpClient);
  private readonly urlBase = 'https://api.ejemplo.com/productos';

  // Devuelve todos los productos del servidor
  obtenerTodos(): Observable<Producto[]> {
    return this.http.get<Producto[]>(this.urlBase);
  }

  // Aplica descuento y filtra sin stock - lógica de negocio centralizada
  obtenerProductosConDescuento(descuento = 0.1): Observable<ProductoConDescuento[]> {
    return this.obtenerTodos().pipe(
      map(productos =>
        productos
          .filter(p => p.stock > 0)
          .map(p => ({
            ...p,
            porcentajeDescuento: descuento * 100,
            precioFinal: parseFloat((p.precio * (1 - descuento)).toFixed(2))
          }))
      )
    );
  }

  // Busca un producto por id con tipado seguro
  obtenerPorId(id: number): Observable<Producto> {
    return this.http.get<Producto>(`${this.urlBase}/${id}`);
  }
}
```

El decorador `@Injectable` marca la clase como participante del sistema de inyección de dependencias. La opción `providedIn: 'root'` registra el servicio en el inyector raíz, creando automáticamente una única instancia compartida por toda la aplicación. No hace falta declararlo en ningún `providers` array: Angular lo registra durante la compilación.

## El patrón Singleton y por qué importa

Cuando `providedIn: 'root'` está activo, Angular garantiza que existe exactamente una instancia de `ProductosService` en toda la aplicación. Eso significa que si el componente de catálogo y el componente de carrito inyectan el mismo servicio, obtienen la misma instancia. Si el servicio mantiene estado interno (una lista en memoria, un `BehaviorSubject`, una caché), ese estado es compartido automáticamente entre todos sus consumidores.

Este patrón Singleton automático tiene otra ventaja: Angular aplica tree-shaking sobre los servicios con `providedIn: 'root'`. Si ningún componente inyecta `ProductosService`, el compilador lo excluye del bundle final. Con los módulos tradicionales, un servicio declarado en `providers` de un módulo siempre se incluía en el bundle, lo usara alguien o no.

## Inyección por constructor

La primera forma de inyectar el servicio en un componente usa el parámetro del constructor. Angular inspecciona el tipo del parámetro y resuelve la instancia automáticamente:

```typescript
import { Component, OnInit } from '@angular/core';
import { ProductosService, ProductoConDescuento } from '../core/services/productos.service';
import { CurrencyPipe } from '@angular/common';

@Component({
  selector: 'app-catalogo',
  standalone: true,
  imports: [CurrencyPipe],
  template: `
    @for (producto of productos; track producto.id) {
      <div class="producto">
        <span>{{ producto.nombre }}</span>
        <span>{{ producto.precioFinal | currency:'USD' }}</span>
        <small>-{{ producto.porcentajeDescuento }}%</small>
      </div>
    }
  `
})
export class CatalogoComponent implements OnInit {
  productos: ProductoConDescuento[] = [];

  // Angular ve el tipo 'ProductosService' y sabe qué instancia inyectar
  constructor(private productosService: ProductosService) {}

  ngOnInit(): void {
    this.productosService.obtenerProductosConDescuento().subscribe(lista => {
      this.productos = lista;
    });
  }
}
```

Esta sintaxis es familiar para cualquier desarrollador que venga de otros frameworks con DI (Spring, NestJS, .NET). El modificador `private` hace que TypeScript declare la propiedad y la asigne en un solo paso, lo cual es una convención estándar en Angular.

## Inyección con inject()

La segunda forma, preferida en código moderno (Angular 14+), usa la función `inject()`. Esta puede llamarse en cualquier contexto de inyección activo: el cuerpo de la clase, una función de factory, un guard funcional o un interceptor:

```typescript
import { Component, OnInit, inject } from '@angular/core';
import { ProductosService, ProductoConDescuento } from '../core/services/productos.service';
import { CurrencyPipe } from '@angular/common';

@Component({
  selector: 'app-catalogo',
  standalone: true,
  imports: [CurrencyPipe],
  template: `
    @for (producto of productos; track producto.id) {
      <div class="producto">
        <span>{{ producto.nombre }}</span>
        <span>{{ producto.precioFinal | currency:'USD' }}</span>
      </div>
    }
  `
})
export class CatalogoComponent implements OnInit {
  // inject() se llama en el cuerpo de la clase - fuera del constructor
  private productosService = inject(ProductosService);
  productos: ProductoConDescuento[] = [];

  ngOnInit(): void {
    this.productosService.obtenerProductosConDescuento(0.15).subscribe(lista => {
      this.productos = lista;
    });
  }
}
```

La función `inject()` es más flexible que el constructor porque permite componer comportamientos fuera de la jerarquía de clases. En el Capítulo 8 - Parte 3 veremos cómo usarla en guards e interceptores funcionales, donde no existe un constructor de clase. Por ahora, la regla práctica es: en componentes nuevos, prefiere `inject()`.

## Servicios que consumen otros servicios

Un servicio también puede inyectar otros servicios. Esto permite construir capas de abstracción: `ProductosService` delega el acceso a datos a `ApiService`, que gestiona los headers, el manejo de errores base y la URL raíz. De esta forma, si cambia la forma de autenticarse, solo cambia `ApiService` y `ProductosService` no se entera:

```typescript
import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class ApiService {
  private http = inject(HttpClient);
  private readonly urlRaiz = 'https://api.ejemplo.com';

  get<T>(ruta: string): Observable<T> {
    // Centraliza headers, timeouts y configuración HTTP base
    const cabeceras = new HttpHeaders({ 'Content-Type': 'application/json' });
    return this.http.get<T>(`${this.urlRaiz}${ruta}`, { headers: cabeceras });
  }
}
```

Luego `ProductosService` puede usar `ApiService` en lugar de `HttpClient` directamente, ganando toda la configuración centralizada sin duplicar código.

## Puntos clave

- `@Injectable({ providedIn: 'root' })` registra el servicio como singleton global y habilita el tree-shaking automático.
- Angular CLI genera servicios con `ng g s ruta/del/servicio` junto con su spec de prueba.
- La inyección por constructor y `inject()` son equivalentes en componentes; ambas producen la misma instancia.
- Prefiere `inject()` en código nuevo: es más conciso, composable y funciona fuera de constructores.
- Los servicios pueden inyectar otros servicios, permitiendo construir capas de abstracción limpias.

## ¿Qué sigue?

En la Parte 3 profundizamos en el motor que hace posible toda esta magia: el sistema de Inyección de Dependencias de Angular, incluyendo `InjectionToken`, `@Inject()` y cómo Angular resuelve las dependencias recorriendo el árbol de inyectores.
