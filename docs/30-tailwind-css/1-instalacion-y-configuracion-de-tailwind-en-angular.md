# Capítulo 30 - Parte 1: Instalación y configuración de Tailwind en Angular

> **Parte 1 de 4** · Capítulo 30 · PARTE XIII - Librerías Esenciales del Ecosistema

Tailwind CSS cambió la manera en que pensamos el diseño en el frontend. En lugar de escribir clases semánticas como `.card` o `.boton-primario` y luego definirlas en un archivo CSS separado, trabajamos directamente con clases utilitarias que expresan el estilo en el template. En este capítulo veamos cómo integrarlo correctamente con Angular 17+, que desde su adopción de esbuild como bundler por defecto hace que la configuración sea más limpia que nunca.

## Instalación de dependencias

Lo primero es instalar Tailwind junto con sus dos compañeros necesarios para el procesamiento de CSS:

```bash
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init
```

El comando `init` genera un archivo `tailwind.config.js` en la raíz del proyecto. PostCSS es el procesador que transforma las directivas de Tailwind en CSS real, y Autoprefixer agrega los prefijos de vendor (`-webkit-`, `-moz-`, etc.) automáticamente según el browserslist configurado en `package.json`.

Con Angular 17+ y esbuild, **no necesitamos configurar un webpack custom** ni instalar `@angular-builders/custom-webpack`. El sistema de build de Angular ya soporta PostCSS de forma nativa. Esto es una mejora enorme respecto a versiones anteriores donde el proceso requería varios pasos manuales.

## Configuración de `tailwind.config.js`

El archivo generado debe quedar así:

```js
// tailwind.config.js
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/**/*.{html,ts}',
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
```

La propiedad `content` es la más importante. Le dice a Tailwind dónde buscar las clases que realmente usamos en el proyecto para hacer el **purging** (eliminación de clases no utilizadas) en producción. En Angular, los templates están en archivos `.html` y también pueden aparecer clases en archivos `.ts` cuando usamos template inline (`template: \`...\``), por eso incluimos ambas extensiones.

> Si olvidamos incluir `.ts` en el content, los componentes con template inline no tendrán sus clases en el bundle de producción. El resultado es un CSS sin estilos en producción pero que funciona perfectamente en desarrollo. Es un error difícil de detectar.

## Directivas en `styles.scss`

Abrimos `src/styles.scss` (o `styles.css` si el proyecto usa CSS plano) y agregamos las tres directivas de Tailwind:

```scss
/* src/styles.scss */
@tailwind base;
@tailwind components;
@tailwind utilities;
```

Estas directivas son reemplazadas en tiempo de compilación por el contenido real de cada capa:

- **`base`**: Resets y estilos normalizados (el "Preflight" de Tailwind).
- **`components`**: Clases de componentes definidas con `@apply` o por plugins.
- **`utilities`**: Todas las clases utilitarias (`flex`, `p-4`, `text-blue-600`, etc.).

El orden importa. Siempre `base` → `components` → `utilities` para que la cascada funcione correctamente.

## Integración con esbuild de Angular 17+

A partir de Angular 17, el builder por defecto es `application` (basado en esbuild), que es significativamente más rápido que el Webpack anterior. La buena noticia es que este builder soporta PostCSS de forma transparente.

Verificamos en `angular.json` que el builder correcto esté configurado:

```json
{
  "architect": {
    "build": {
      "builder": "@angular-devkit/build-angular:application",
      "options": {
        "styles": ["src/styles.scss"]
      }
    }
  }
}
```

No necesitamos agregar configuración adicional. Angular detecta el `tailwind.config.js` en la raíz del proyecto y activa el procesamiento automáticamente.

## Verificación en desarrollo

Arrancamos el servidor de desarrollo:

```bash
ng serve
```

En el componente `app.component.html` agregamos una clase de prueba:

```html
<!-- src/app/app.component.html -->
<div class="flex items-center justify-center min-h-screen bg-blue-50">
  <h1 class="text-4xl font-bold text-blue-700">
    Angular + Tailwind funcionando
  </h1>
</div>
```

Si el texto aparece grande y azul, la integración está lista. Para ver el CSS generado en tiempo real durante desarrollo, podemos usar:

```bash
npx tailwindcss --watch --input src/styles.scss --output dist/output.css
```

Aunque en desarrollo con `ng serve` esto no es necesario, es útil para inspeccionar exactamente qué CSS genera Tailwind.

## El problema del purging con clases dinámicas

Aquí viene el gotcha más importante de Tailwind con Angular. Consideremos este componente:

```typescript
// alerta.component.ts
import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';

type TipoAlerta = 'exito' | 'error' | 'advertencia';

@Component({
  selector: 'app-alerta',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div [class]="claseContenedor">
      {{ mensaje }}
    </div>
  `
})
export class AlertaComponent {
  @Input() tipo: TipoAlerta = 'exito';
  @Input() mensaje = '';

  get claseContenedor(): string {
    const mapa: Record<TipoAlerta, string> = {
      exito: 'bg-green-100 text-green-800',
      error: 'bg-red-100 text-red-800',
      advertencia: 'bg-yellow-100 text-yellow-800',
    };
    return `p-4 rounded-lg ${mapa[this.tipo]}`;
  }
}
```

El problema: Tailwind analiza el código como texto estático. Cuando ve `'bg-green-100 text-green-800'` en el archivo `.ts`, **sí** lo incluye porque la cadena completa aparece. Pero si construimos la clase dinámicamente:

```typescript
// PELIGROSO: Tailwind no detecta estas clases
const color = 'green';
const clase = `bg-${color}-100`; // Tailwind NO incluye bg-green-100
```

La solución es nunca construir nombres de clases parciales. Siempre usar la clase completa como cadena de texto, o usar la propiedad `safelist` en `tailwind.config.js`:

```js
// tailwind.config.js
module.exports = {
  content: ['./src/**/*.{html,ts}'],
  safelist: [
    'bg-green-100', 'text-green-800',
    'bg-red-100', 'text-red-800',
    'bg-yellow-100', 'text-yellow-800',
    // También soporta patrones con regex:
    { pattern: /^bg-(green|red|yellow)-(100|200|300)$/ },
  ],
  theme: { extend: {} },
  plugins: [],
}
```

La propiedad `safelist` garantiza que esas clases siempre se incluyan en el bundle de producción, independientemente de si Tailwind las detecta en el análisis estático.

## Flujo completo de procesamiento

```mermaid
flowchart LR
    A[styles.scss\n@tailwind base\n@tailwind components\n@tailwind utilities] --> B[PostCSS + Tailwind Plugin]
    C[tailwind.config.js\ncontent patterns] --> B
    D[src/**/*.html\nsrc/**/*.ts\nAnálisis de clases] --> B
    B --> E[CSS Purgeado\nSolo clases usadas]
    E --> F[autoprefixer]
    F --> G[Bundle final\nCSS optimizado]
```

## Puntos clave

- Instalar `tailwindcss postcss autoprefixer` y ejecutar `npx tailwindcss init` para comenzar.
- El `content` en `tailwind.config.js` debe incluir `./src/**/*.{html,ts}` para capturar templates inline.
- Las directivas `@tailwind base/components/utilities` van en `styles.scss` en ese orden exacto.
- Angular 17+ con esbuild detecta Tailwind automáticamente sin configuración de webpack.
- Las clases construidas dinámicamente con interpolación de strings no son detectadas por el purger; usar cadenas completas o la propiedad `safelist`.

## ¿Qué sigue?

En la siguiente parte construiremos componentes UI reales usando clases utilitarias directamente en los templates de Angular, y aprenderemos cuándo tiene sentido extraerlas con `@apply`.
