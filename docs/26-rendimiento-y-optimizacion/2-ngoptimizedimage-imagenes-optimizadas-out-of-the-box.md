# Capítulo 26 - Parte 2: NgOptimizedImage: imágenes optimizadas out-of-the-box

> **Parte 2 de 4** · Capítulo 26 · PARTE XII - Optimización y Rendimiento

Las imágenes son históricamente el mayor culpable de un LCP (Largest Contentful Paint) deficiente en aplicaciones web. Angular 15 introdujo `NgOptimizedImage`, una directiva que aplica automáticamente las mejores prácticas de carga de imágenes: preload de imágenes críticas, prevención de layout shift, generación de `srcset` responsivo y soporte nativo para CDNs de imágenes populares. Lo notable es que muchas de estas optimizaciones requieren cero configuración más allá de reemplazar `src` por `ngSrc`.

## Importar y activar la directiva

`NgOptimizedImage` vive en `@angular/common` y se usa como cualquier directiva standalone: importándola en el componente o en los imports del módulo.

```typescript
import { Component, ChangeDetectionStrategy } from '@angular/core';
import { NgOptimizedImage } from '@angular/common';

@Component({
  selector: 'app-portada-articulo',
  standalone: true,
  imports: [NgOptimizedImage],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <img
      ngSrc="articulos/portada-angular-performance.webp"
      width="1200"
      height="630"
      priority
      alt="Portada del artículo sobre rendimiento en Angular"
    />
  `
})
export class PortadaArticuloComponent {}
```

El cambio más visible es `ngSrc` en lugar de `src`. La directiva toma el control de cómo y cuándo se carga la imagen. `width` y `height` son obligatorios cuando no se usa `fill`: sin ellos la directiva lanza una advertencia en desarrollo porque sin dimensiones conocidas el navegador no puede reservar el espacio antes de que la imagen cargue, causando layout shift.

## El atributo priority: imágenes LCP above the fold

`priority` es el atributo más impactante para el LCP. Cuando está presente, `NgOptimizedImage` genera un `<link rel="preload">` en el `<head>` del documento para esa imagen, instruyendo al navegador para que la descargue con la máxima prioridad antes de procesar el resto del HTML. También desactiva el lazy loading para esa imagen.

La regla práctica es clara: cualquier imagen que sea el elemento más grande visible cuando la página carga por primera vez debe llevar `priority`. Solo una o dos imágenes por página deberían tenerlo -aplicarlo indiscriminadamente anula el beneficio.

```typescript
import { Component, ChangeDetectionStrategy } from '@angular/core';
import { NgOptimizedImage } from '@angular/common';

@Component({
  selector: 'app-hero',
  standalone: true,
  imports: [NgOptimizedImage],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <!-- Imagen hero: LCP → priority obligatorio -->
    <img ngSrc="hero/banner-principal.webp" width="1440" height="600" priority
         alt="Banner principal de la tienda" />

    <!-- Imágenes de producto: lazy loading automático sin priority -->
    @for (producto of productosDestacados; track producto.id) {
      <img [ngSrc]="producto.imagenUrl"
           width="300" height="300"
           [alt]="producto.nombre" />
    }
  `
})
export class HeroComponent {
  productosDestacados = [
    { id: 1, nombre: 'Teclado mecánico', imagenUrl: 'productos/teclado.webp' },
    { id: 2, nombre: 'Monitor 4K', imagenUrl: 'productos/monitor.webp' }
  ];
}
```

Las imágenes sin `priority` reciben automáticamente `loading="lazy"` y `fetchpriority="low"`, lo que difiere su descarga hasta que están cerca del viewport. Esto es exactamente lo opuesto a lo que queremos para el LCP, y exactamente lo correcto para el resto de imágenes de la página.

## fill: imágenes que llenan su contenedor

Cuando una imagen debe ocupar el 100% de su contenedor -carruseles, fondos de sección, galerías con grid CSS- usar `width` y `height` fijos no funciona bien. `fill` resuelve esto:

```typescript
import { Component, ChangeDetectionStrategy } from '@angular/core';
import { NgOptimizedImage } from '@angular/common';

@Component({
  selector: 'app-galeria-item',
  standalone: true,
  imports: [NgOptimizedImage],
  changeDetection: ChangeDetectionStrategy.OnPush,
  styles: [`
    .contenedor-imagen {
      position: relative; /* obligatorio con fill */
      width: 100%;
      aspect-ratio: 16 / 9;
      overflow: hidden;
    }
  `],
  template: `
    <div class="contenedor-imagen">
      <!-- fill: imagen ocupa todo el contenedor - no necesita width/height -->
      <img [ngSrc]="imagenUrl" fill [alt]="descripcion" />
    </div>
  `
})
export class GaleriaItemComponent {
  imagenUrl = 'galeria/foto-destacada.webp';
  descripcion = 'Foto destacada de la galería';
}
```

Con `fill`, el contenedor padre debe tener `position: relative` y dimensiones definidas. La imagen recibe internamente `position: absolute; width: 100%; height: 100%`. Es el equivalente de `object-fit: cover` para imágenes que deben adaptarse a cualquier tamaño de contenedor.

## sizes: imágenes responsivas con srcset automático

`NgOptimizedImage` puede generar automáticamente un `srcset` con múltiples resoluciones si le indicamos cómo varía el tamaño de la imagen según el viewport:

```typescript
import { Component, ChangeDetectionStrategy } from '@angular/core';
import { NgOptimizedImage } from '@angular/common';

@Component({
  selector: 'app-imagen-responsiva',
  standalone: true,
  imports: [NgOptimizedImage],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <img
      ngSrc="productos/camara.webp"
      width="800"
      height="600"
      sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
      alt="Cámara mirrorless"
    />
  `
})
export class ImagenResponsivaComponent {}
```

Con el atributo `sizes`, la directiva genera un `srcset` con variantes de la imagen para anchos de 640px, 750px, 828px, 1080px, 1200px, 1920px, 2048px y 3840px. El navegador elige automáticamente la variante más adecuada según el DPR y el tamaño real del elemento. Sin un loader de CDN configurado, esto requiere que los archivos de esas resoluciones existan en el servidor.

## Loaders para CDNs de imágenes

La funcionalidad más poderosa de `NgOptimizedImage` aparece cuando se configura con un loader de CDN. El loader transforma la URL base de `ngSrc` en una URL real del CDN con los parámetros correctos para cada tamaño.

```typescript
import { bootstrapApplication } from '@angular/platform-browser';
import { provideImageKitLoader } from '@angular/common';
import { AppComponent } from './app/app.component';

bootstrapApplication(AppComponent, {
  providers: [
    // Con ImageKit: las URLs se construyen automáticamente con transformaciones
    provideImageKitLoader('https://ik.imagekit.io/mi-proyecto')
  ]
});
```

Con el loader de ImageKit configurado, `ngSrc="productos/camara.webp"` se convierte automáticamente en URLs como `https://ik.imagekit.io/mi-proyecto/productos/camara.webp?tr=w-800,h-600` para el tamaño base, y variantes para cada punto del `srcset`. Angular también ofrece `provideCloudinaryLoader`, `provideImgixLoader` y `provideNetlifyImageLoader` con el mismo patrón.

## Advertencias de desarrollo

En modo desarrollo, `NgOptimizedImage` es bastante vocal. Lanza advertencias en consola cuando detecta problemas comunes:

- Imagen sin `width` y `height` que no usa `fill`: potencial CLS.
- Imagen con `priority` que no tiene `<link rel="preload">` en el `<head>` (posible cuando el componente carga tarde).
- Imagen sin `priority` que ocupa más del 50% del viewport inicial: debería llevar `priority`.
- Diferencia entre las dimensiones declaradas y las dimensiones reales de la imagen: posible distorsión.

Estas advertencias desaparecen en producción, pero son valiosas durante el desarrollo para detectar configuraciones incorrectas antes de que afecten a los usuarios.

## Puntos clave

- Reemplazar `src` por `ngSrc` activa optimizaciones automáticas: lazy loading, `fetchpriority`, generación de `srcset`
- `priority` agrega `<link rel="preload">` y desactiva lazy loading; usar solo para la imagen LCP de cada página
- `fill` es la alternativa a `width`/`height` cuando la imagen debe adaptarse al contenedor; requiere `position: relative` en el padre
- `sizes` permite a la directiva generar `srcset` responsivo automático con las resoluciones más comunes
- Los loaders de CDN (`provideImageKitLoader`, `provideCloudinaryLoader`, etc.) eliminan la necesidad de gestionar URLs de imagen manualmente

## ¿Qué sigue?

En la Parte 3 abrimos el bundle de la aplicación con `webpack-bundle-analyzer` y las herramientas de esbuild para identificar qué dependencias están engordando innecesariamente el código que descarga el usuario.
