# Capítulo 1 - Parte 4: Tu primera aplicación: de `ng new` al primer `ng serve`

> **Parte 4 de 4** · Capítulo 1 · PARTE I - Primeros Pasos con Angular

Con el entorno listo (→ Ver Capítulo 1, Parte 3), es momento de crear nuestra primera aplicación Angular real. No vamos a empezar con "hola mundo" y ya: vamos a crear el proyecto de la forma correcta, entender cada archivo que genera la CLI y hacer nuestro primer cambio visible en el navegador.

## Creando el proyecto con `ng new`

Angular CLI crea proyectos con el comando `ng new`. La convención moderna es usar componentes standalone y SCSS como preprocesador de estilos. Ejecuta lo siguiente en el directorio donde quieras crear el proyecto:

```bash
ng new mi-primera-app --standalone --style=scss
```

La CLI te hará una pregunta:

```
? Would you like to enable Server-Side Rendering (SSR) and Static Site Generation (SSG/Prerendering)?
```

Responde `No` por ahora. El SSR lo cubriremos en la PARTE XII del libro.

El proceso tarda entre uno y tres minutos dependiendo de la velocidad de tu conexión, porque Angular CLI descarga alrededor de 900 paquetes de npm. Al terminar, verás una confirmación y el proyecto quedará en el directorio `mi-primera-app/`.

## Explorando la estructura de archivos generada

Antes de ejecutar cualquier cosa, veamos qué creó la CLI y por qué cada archivo existe:

```
mi-primera-app/
├── src/
│   ├── app/
│   │   ├── app.component.ts        ← Componente raíz de la aplicación
│   │   ├── app.component.html      ← Template del componente raíz
│   │   ├── app.component.scss      ← Estilos del componente raíz
│   │   ├── app.component.spec.ts   ← Tests del componente raíz
│   │   └── app.config.ts           ← Configuración de la aplicación standalone
│   ├── assets/                     ← Archivos estáticos (imágenes, fuentes)
│   ├── index.html                  ← Página HTML base
│   ├── main.ts                     ← Punto de entrada de la aplicación
│   └── styles.scss                 ← Estilos globales
├── angular.json                    ← Configuración del workspace y la CLI
├── package.json                    ← Dependencias y scripts npm
├── tsconfig.json                   ← Configuración raíz de TypeScript
├── tsconfig.app.json               ← Configuración TypeScript para la app
└── tsconfig.spec.json              ← Configuración TypeScript para los tests
```

Analicemos los archivos más importantes uno por uno.

## main.ts: el punto de entrada

```typescript
import { bootstrapApplication } from "@angular/platform-browser";
import { appConfig } from "./app/app.config";
import { AppComponent } from "./app/app.component";

// bootstrapApplication arranca la app con el componente raíz y su configuración
bootstrapApplication(AppComponent, appConfig).catch((err) =>
  console.error(err),
); // Muestra errores de arranque en consola
```

Este archivo es mínimo por diseño. Solo tiene una responsabilidad: iniciar la aplicación diciéndole a Angular cuál es el componente raíz (`AppComponent`) y qué configuración usar (`appConfig`). No debe contener lógica de negocio.

## app.config.ts: la configuración de la aplicación

```typescript
import { ApplicationConfig } from "@angular/core";
import { provideRouter } from "@angular/router";

import { routes } from "./app.routes";

// ApplicationConfig define los providers disponibles en toda la aplicación
export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes), // Registra el sistema de routing con las rutas definidas
  ],
};
```

`app.config.ts` es el equivalente standalone al antiguo `AppModule`. Aquí se registran los providers globales de la aplicación: el router, `HttpClient`, interceptores, stores de estado y cualquier servicio que deba estar disponible en toda la app.

## app.component.ts: el componente raíz

```typescript
import { Component } from "@angular/core";
import { RouterOutlet } from "@angular/router";

@Component({
  selector: "app-root", // Nombre del elemento HTML personalizado
  standalone: true, // No pertenece a ningún NgModule
  imports: [RouterOutlet], // Importaciones directas (otros componentes, directivas)
  templateUrl: "./app.component.html",
  styleUrl: "./app.component.scss",
})
export class AppComponent {
  title = "mi-primera-app"; // Propiedad disponible en el template
}
```

El decorador `@Component` convierte una clase TypeScript ordinaria en un componente Angular. La propiedad `standalone: true` es lo que lo convierte en un componente independiente, sin necesidad de declararlo en un NgModule. La propiedad `imports` lista las dependencias que este componente necesita en su template.

## angular.json: la configuración del workspace

Este archivo es el más extenso y el que más raramente editarás a mano. Contiene la configuración del workspace de Angular CLI: cómo compilar la aplicación, qué archivos de estilos globales incluir, cómo configurar el servidor de desarrollo, qué optimizaciones aplicar en producción. La CLI lo modifica automáticamente cuando agregas dependencias o cambias opciones de configuración.

## package.json: dependencias y scripts

```json
{
  "scripts": {
    "ng": "ng",
    "start": "ng serve",
    "build": "ng build",
    "watch": "ng build --watch --configuration development",
    "test": "ng test"
  }
}
```

Los scripts `npm start`, `npm run build` y `npm test` son atajos a los comandos de Angular CLI. Puedes usar `ng serve` directamente o `npm start`; son equivalentes.

## tsconfig.json: configuración de TypeScript

Angular configura TypeScript en modo estricto (`strict: true`) por defecto. Esto activa verificaciones adicionales como `noImplicitAny`, `strictNullChecks` y `strictPropertyInitialization`. El modo estricto puede parecer exigente al principio, pero previene una clase entera de errores en tiempo de ejecución al detectarlos en tiempo de compilación.

## Ejecutando la aplicación por primera vez

Con el proyecto creado, entra al directorio y ejecuta el servidor de desarrollo:

```bash
cd mi-primera-app
ng serve
```

La primera compilación tarda unos segundos. Cuando ves el mensaje `Application bundle generation complete`, abre tu navegador en `http://localhost:4200`. Verás la página de bienvenida de Angular con el nombre del proyecto.

## Haciendo el primer cambio y viendo el live reload

Abre `src/app/app.component.html` en VS Code. Verás una plantilla extensa generada por la CLI. Reemplaza todo el contenido con algo más simple:

```html
<!-- app.component.html - nuestra primera modificación -->
<main>
  <h1>Bienvenido a {{ title }}</h1>
  <p>Mi primera aplicación Angular está funcionando.</p>
</main>
```

Guarda el archivo. En el navegador, la página se actualiza automáticamente en menos de un segundo sin que tengas que hacer nada. Esto es el live reload: Angular CLI observa los archivos del proyecto y recompila solo los módulos afectados por cada cambio.

Ahora modifica la clase del componente para ver cómo funciona la interpolación `{{ title }}`:

```typescript
// app.component.ts - cambiamos el valor de la propiedad title
export class AppComponent {
  title = "Angular desde cero"; // El template mostrará este nuevo valor
}
```

Al guardar, el navegador actualiza y muestra "Bienvenido a Angular desde cero". Esta conexión reactiva entre la clase TypeScript y el template HTML es uno de los pilares fundamentales de Angular que exploraremos en profundidad a lo largo del libro.

## Puntos clave

- `ng new nombre --standalone --style=scss` crea un proyecto Angular moderno sin NgModules
- `main.ts` es el punto de entrada; `bootstrapApplication()` arranca la app con el componente raíz y su configuración
- `app.config.ts` reemplaza al `AppModule` en proyectos standalone: aquí van los providers globales
- `standalone: true` en el decorador `@Component` significa que el componente es autónomo y declara sus propias dependencias en `imports`
- `ng serve` inicia el servidor de desarrollo con live reload: los cambios se reflejan en el navegador automáticamente al guardar

## ¿Qué sigue?

En el Capítulo 2 profundizamos en la arquitectura de Angular: cómo se relacionan entre sí los componentes, servicios, módulos y el router, y cómo Angular CLI nos ayuda a mantener orden a medida que el proyecto crece.
