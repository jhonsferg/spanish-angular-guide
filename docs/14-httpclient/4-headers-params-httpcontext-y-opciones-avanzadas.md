# Capítulo 14 - Parte 4: Headers, params, HttpContext y opciones avanzadas

> **Parte 4 de 4** · Capítulo 14 · PARTE VIII - Comunicación HTTP

La mayoría de peticiones HTTP del mundo real necesitan más que una URL. Los headers llevan metadatos como el tipo de contenido o credenciales de autenticación. Los query params filtran y paginan colecciones. A veces necesitamos acceder a los headers de respuesta, no solo al cuerpo. Y cuando subimos archivos, queremos reportar el progreso al usuario. `HttpClient` expone todas estas capacidades a través de un objeto de opciones tipado.

## HttpHeaders: encadenamiento inmutable

`HttpHeaders` es una clase inmutable. Cada llamada a `set()`, `append()` o `delete()` devuelve una nueva instancia en lugar de mutar la existente. Este diseño es intencional: evita que un interceptor que modifica headers afecte accidentalmente a otras peticiones que comparten el mismo objeto.

```typescript
import { HttpHeaders } from '@angular/common/http';

// Encadenamiento fluido - cada método devuelve una nueva instancia
const headers = new HttpHeaders()
  .set('Content-Type', 'application/json')
  .set('Accept', 'application/json')
  .set('X-Version-Api', '2')
  .append('X-Request-Id', crypto.randomUUID()); // append agrega sin reemplazar

// También se puede construir desde un objeto literal - más conciso
const headersAlternativos = new HttpHeaders({
  'Content-Type': 'application/json',
  'Accept': 'application/json'
});
```

La diferencia entre `set` y `append` importa cuando un header puede tener múltiples valores (como `Accept`): `set` reemplaza todos los valores existentes, `append` agrega un valor adicional al header.

Para usar los headers en una petición, se pasan en el objeto de opciones:

```typescript
import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class ReportesService {
  private http = inject(HttpClient);

  descargarReporte(id: number): Observable<Blob> {
    const headers = new HttpHeaders()
      .set('Accept', 'application/pdf')
      .set('X-Request-Id', crypto.randomUUID());

    return this.http.get(`/api/reportes/${id}`, {
      headers,
      responseType: 'blob' // Indica que esperamos un archivo binario
    });
  }
}
```

## HttpParams: construyendo query strings con tipo

`HttpParams` construye los parámetros de la URL de forma segura y legible. Como `HttpHeaders`, también es inmutable:

```typescript
import { HttpParams } from '@angular/common/http';

// Construir query params con encadenamiento - resulta en ?pagina=2&porPagina=20&activo=true
const params = new HttpParams()
  .set('pagina', 2)          // acepta number - lo convierte a string
  .set('porPagina', 20)
  .set('activo', true)
  .set('orden', 'nombre');

// Uso en la petición
this.http.get<Producto[]>('/api/productos', { params });
```

También se puede construir desde un objeto literal, lo que es más conveniente cuando los parámetros provienen de variables del componente:

```typescript
// Alternativa con objeto - más legible cuando hay muchos parámetros
const opciones = {
  pagina: 1,
  porPagina: 20,
  busqueda: 'teclado',
  activo: true
};

const params = new HttpParams({ fromObject: opciones as Record<string, string | number | boolean> });

this.http.get<Producto[]>('/api/productos', { params });
// Genera: GET /api/productos?pagina=1&porPagina=20&busqueda=teclado&activo=true
```

## observe: 'response' - accediendo a la respuesta completa

Por defecto, `HttpClient` extrae el cuerpo de la respuesta y lo emite directamente. Pero a veces necesitamos los headers de respuesta: el header `X-Total-Count` para paginación, `Location` tras un `POST`, o `ETag` para caché condicional. La opción `observe: 'response'` cambia el tipo de retorno a `HttpResponse<T>`, que incluye el cuerpo, los headers y el código de estado.

```typescript
import { HttpResponse } from '@angular/common/http';

obtenerConPaginacion(pagina: number): Observable<HttpResponse<Producto[]>> {
  const params = new HttpParams()
    .set('pagina', pagina)
    .set('porPagina', 20);

  return this.http.get<Producto[]>('/api/productos', {
    params,
    observe: 'response' // El Observable ahora emite HttpResponse, no solo el array
  });
}
```

En el componente, accedemos tanto al cuerpo como a los headers:

```typescript
this.productosService.obtenerConPaginacion(1).subscribe(respuesta => {
  const productos = respuesta.body ?? [];      // Cuerpo tipado como Producto[]
  const total = respuesta.headers.get('X-Total-Count'); // Header de respuesta
  console.log(`Mostrando ${productos.length} de ${total} productos`);
});
```

## reportProgress: true - progreso en subida de archivos

Para subidas de archivos, el usuario necesita retroalimentación visual. La opción `reportProgress: true` con `observe: 'events'` hace que el Observable emita múltiples veces: al inicio, durante la subida (con el porcentaje) y al completar.

```typescript
import { HttpEventType, HttpRequest, HttpResponse } from '@angular/common/http';
import { signal } from '@angular/core';

// En el servicio
subirArchivo(archivo: File): Observable<number | Producto> {
  const formData = new FormData();
  formData.append('archivo', archivo);

  const peticion = new HttpRequest('POST', '/api/productos/importar', formData, {
    reportProgress: true,
    observe: 'events'
  });

  return this.http.request<Producto>(peticion).pipe(
    map(evento => {
      if (evento.type === HttpEventType.UploadProgress) {
        // Calculamos el porcentaje de progreso
        const porcentaje = Math.round(100 * evento.loaded / (evento.total ?? 1));
        return porcentaje;
      }
      if (evento instanceof HttpResponse) {
        return evento.body as Producto;
      }
      return 0;
    }),
    filter(valor => valor !== 0 || valor === 100)
  );
}
```

El enum `HttpEventType` define los tipos de eventos posibles: `Sent`, `UploadProgress`, `DownloadProgress`, `Response` y `ResponseHeader`. Verificar el tipo antes de acceder a propiedades específicas evita errores en tiempo de ejecución.

## HttpContext: metadatos entre interceptores

`HttpContext` es un contenedor de datos tipados que viaja junto a la petición y es visible para todos los interceptores. Permite comunicar al interceptor si debe o no aplicar su lógica a una petición específica, sin modificar la URL ni los headers.

```typescript
// src/app/core/http/tokens-contexto.ts
import { HttpContextToken } from '@angular/common/http';

// Token para indicar que una petición es pública (no necesita token JWT)
export const ES_PETICION_PUBLICA = new HttpContextToken<boolean>(() => false);

// Token para indicar el tiempo máximo de espera personalizado
export const TIMEOUT_PETICION = new HttpContextToken<number>(() => 30_000);
```

Usando el contexto en la petición:

```typescript
import { HttpContext } from '@angular/common/http';
import { ES_PETICION_PUBLICA } from '../http/tokens-contexto';

// Petición que el interceptor de auth debe ignorar
login(credenciales: Credenciales): Observable<TokenSesion> {
  return this.http.post<TokenSesion>('/api/auth/login', credenciales, {
    context: new HttpContext().set(ES_PETICION_PUBLICA, true)
  });
}
```

El interceptor lee el contexto así:

```typescript
// Dentro del interceptor funcional
if (req.context.get(ES_PETICION_PUBLICA)) {
  return next(req); // Pasar sin modificar
}
```

`HttpContext` es la solución limpia al problema de "¿cómo le digo al interceptor que esta petición es especial?". Las alternativas (añadir un header especial que el interceptor luego elimina, o verificar la URL con condiciones frágiles) son mucho más propensas a errores.

## Resumen de las opciones del objeto de configuración

```mermaid
flowchart LR
    subgraph OpcionesHttp["Objeto de opciones - HttpClient"]
        H[headers: HttpHeaders]
        P[params: HttpParams]
        O[observe: 'body' | 'response' | 'events']
        R[reportProgress: boolean]
        RT[responseType: 'json' | 'blob' | 'text']
        C[context: HttpContext]
    end

    HttpClient -->|acepta| OpcionesHttp
```

## Puntos clave

- `HttpHeaders` y `HttpParams` son inmutables - cada `set()` devuelve una nueva instancia
- `observe: 'response'` cambia el tipo de retorno a `HttpResponse<T>`, con acceso a headers de respuesta
- `reportProgress: true` con `observe: 'events'` permite mostrar progreso real de subida de archivos
- `HttpContext` con `HttpContextToken` es el mecanismo oficial para pasar metadatos entre el sitio de la petición y los interceptores
- `responseType: 'blob'` es necesario para descargar archivos binarios (PDF, imágenes, ZIP)

## ¿Qué sigue?

El Capítulo 15 introduce los interceptores funcionales: cómo capturar todas las peticiones salientes y respuestas entrantes para añadir comportamiento transversal como autenticación, logging y manejo global de errores.
