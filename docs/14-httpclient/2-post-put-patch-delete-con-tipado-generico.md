# Capítulo 14 - Parte 2: POST, PUT, PATCH, DELETE con tipado genérico

> **Parte 2 de 4** · Capítulo 14 · PARTE VIII - Comunicación HTTP

Con `HttpClient` configurado y el servicio base listo (→ Ver Parte 1), el siguiente paso es implementar las operaciones de escritura. Cada método HTTP tiene semántica propia: `POST` crea recursos, `PUT` reemplaza uno completo, `PATCH` actualiza campos específicos y `DELETE` elimina. Respetar esta semántica no es solo una convención: muchas APIs validan el método antes de procesar el cuerpo.

## Tipando las respuestas con interfaces específicas

Antes de escribir los métodos del servicio, definimos las interfaces que describen las respuestas de cada operación. Una API bien diseñada no devuelve lo mismo en un `POST` que en un `GET`: normalmente devuelve el recurso recién creado con su `id` asignado por el servidor.

```typescript
// src/app/core/models/producto.model.ts
export interface Producto {
  id: number;
  nombre: string;
  precio: number;
  stock: number;
  categoriaId: number;
  activo: boolean;
}

// Lo que enviamos al crear - sin id, el servidor lo asigna
export interface CrearProductoDto {
  nombre: string;
  precio: number;
  stock: number;
  categoriaId: number;
}

// Respuesta al crear - incluye el id asignado y timestamp
export interface RespuestaCreacion {
  id: number;
  creadoEn: string; // ISO 8601
}

// Para actualizaciones parciales, todos los campos son opcionales
export type ActualizarProductoDto = Partial<Pick<Producto, 'nombre' | 'precio' | 'stock' | 'activo'>>;
```

`Partial<Pick<...>>` es un patrón de TypeScript que extrae campos específicos de una interfaz y los hace todos opcionales. Esto representa con precisión lo que permite un endpoint `PATCH`: enviar solo los campos que cambian.

## POST: creando recursos

`http.post<T>(url, body)` toma la URL, el cuerpo de la petición y devuelve un `Observable<T>`. Angular serializa el cuerpo a JSON y establece el header `Content-Type: application/json` automáticamente cuando el cuerpo es un objeto JavaScript plano.

```typescript
// src/app/core/services/productos.service.ts
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import {
  Producto,
  CrearProductoDto,
  RespuestaCreacion,
  ActualizarProductoDto
} from '../models/producto.model';

@Injectable({ providedIn: 'root' })
export class ProductosService {
  private http = inject(HttpClient);
  private readonly baseUrl = '/api/productos';

  obtenerTodos(): Observable<Producto[]> {
    return this.http.get<Producto[]>(this.baseUrl);
  }

  obtenerPorId(id: number): Observable<Producto> {
    return this.http.get<Producto>(`${this.baseUrl}/${id}`);
  }

  // POST - el servidor crea el recurso y devuelve confirmación con el id
  crear(datos: CrearProductoDto): Observable<RespuestaCreacion> {
    return this.http.post<RespuestaCreacion>(this.baseUrl, datos);
  }
}
```

El tipo genérico `<RespuestaCreacion>` le indica a TypeScript el shape de la respuesta. Si la API devuelve un campo adicional inesperado, TypeScript no se queja (los objetos pueden tener más propiedades de las declaradas), pero si intentamos acceder a un campo no declarado, el compilador con `strict: true` sí lo detectará.

## PUT: reemplazo completo del recurso

`PUT` envía la representación completa del recurso. El servidor reemplaza el estado actual con lo recibido. Si se omite un campo, el servidor lo considera como "sin valor" o lo ignora según su implementación.

```typescript
// Continuación de ProductosService
actualizar(id: number, producto: Producto): Observable<Producto> {
  // PUT a /api/productos/:id con el objeto completo
  return this.http.put<Producto>(`${this.baseUrl}/${id}`, producto);
}
```

Es común que el servidor devuelva el recurso actualizado completo tras un `PUT`. Tipamos la respuesta como `Observable<Producto>` para que el componente pueda actualizar su estado local sin necesidad de hacer una nueva petición GET.

## PATCH: actualizaciones parciales

`PATCH` es la operación más delicada porque su semántica varía entre APIs. La implementación correcta en el cliente es enviar únicamente los campos que cambian:

```typescript
// Solo enviamos los campos modificados
actualizarParcial(id: number, cambios: ActualizarProductoDto): Observable<Producto> {
  return this.http.patch<Producto>(`${this.baseUrl}/${id}`, cambios);
}
```

La ventaja sobre `PUT` es el tamaño del payload: si solo cambia el precio, enviamos `{ precio: 149.99 }` en lugar del objeto completo. Esto es especialmente relevante en móviles con conexiones lentas o cuando los objetos tienen muchos campos.

## DELETE: eliminando recursos

`DELETE` generalmente no tiene cuerpo de respuesta. El tipo genérico `<void>` comunica esta intención explícitamente al compilador y a quien lea el código:

```typescript
eliminar(id: number): Observable<void> {
  // <void> indica que no esperamos cuerpo en la respuesta
  return this.http.delete<void>(`${this.baseUrl}/${id}`);
}
```

Algunas APIs devuelven el recurso eliminado como confirmación. En ese caso, cambiaríamos `<void>` por `<Producto>`. Siempre hay que ajustar el tipo genérico al contrato real de la API.

## Ejemplo completo: componente de formulario CRUD

Con el servicio completo, el componente que gestiona el formulario queda limpio y sin lógica HTTP:

```typescript
// src/app/features/productos/formulario-producto.component.ts
import { Component, inject, signal } from '@angular/core';
import { ProductosService } from '../../core/services/productos.service';
import { CrearProductoDto } from '../../core/models/producto.model';

@Component({
  selector: 'app-formulario-producto',
  standalone: true,
  template: `
    <button (click)="guardar()">Guardar</button>
    @if (guardando()) { <span>Guardando...</span> }
    @if (error()) { <span class="error">{{ error() }}</span> }
  `
})
export class FormularioProductoComponent {
  private productosService = inject(ProductosService);

  guardando = signal(false);
  error = signal<string | null>(null);

  guardar(): void {
    const nuevoProducto: CrearProductoDto = {
      nombre: 'Teclado mecánico',
      precio: 299.99,
      stock: 50,
      categoriaId: 3
    };

    this.guardando.set(true);
    this.error.set(null);

    this.productosService.crear(nuevoProducto).subscribe({
      next: (respuesta) => {
        console.log('Creado con id:', respuesta.id);
        this.guardando.set(false);
      },
      error: (err) => {
        this.error.set('No se pudo guardar el producto');
        this.guardando.set(false);
      }
    });
  }
}
```

El objeto suscriptor acepta tres callbacks opcionales: `next` para el dato emitido, `error` para errores (la petición no emitirá más después de un error) y `complete` cuando el observable termina sin error. Para peticiones HTTP, `complete` siempre se dispara inmediatamente después de `next`, porque un `Observable<T>` de HttpClient emite exactamente un valor y cierra.

## Diagrama del flujo CRUD completo

```mermaid
flowchart LR
    Componente -->|crear()| POST[POST /api/productos]
    Componente -->|actualizar()| PUT[PUT /api/productos/:id]
    Componente -->|actualizarParcial()| PATCH[PATCH /api/productos/:id]
    Componente -->|eliminar()| DELETE[DELETE /api/productos/:id]

    POST -->|Observable RespuestaCreacion| Componente
    PUT -->|Observable Producto| Componente
    PATCH -->|Observable Producto| Componente
    DELETE -->|Observable void| Componente
```

## Puntos clave

- `POST` usa `http.post<RespuestaCreacion>(url, body)`: Angular serializa el body a JSON automáticamente
- `PUT` envía el recurso completo; `PATCH` envía solo los campos que cambian - usar `Partial<Pick<...>>` para tiparlo
- `delete<void>()` comunica explícitamente que no se espera cuerpo en la respuesta
- El callback de suscripción acepta `{ next, error, complete }` - los tres son opcionales
- Un Observable de HttpClient emite exactamente un valor y luego completa; no hay riesgo de emisiones continuas

## ¿Qué sigue?

En la Parte 3 abordamos qué ocurre cuando la petición falla: cómo capturar `HttpErrorResponse`, distinguir errores del cliente de errores del servidor, y notificar al usuario de forma controlada.
