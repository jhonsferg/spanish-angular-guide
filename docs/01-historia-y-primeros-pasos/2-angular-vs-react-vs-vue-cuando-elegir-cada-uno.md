# Capítulo 1 - Parte 2: Angular vs React vs Vue: cuándo elegir cada uno

> **Parte 2 de 4** · Capítulo 1 · PARTE I - Primeros Pasos con Angular

Elegir un framework de frontend es una de las decisiones más importantes en un proyecto web. No existe una respuesta universal, y cualquiera que te diga "X framework siempre es mejor" no está siendo honesto contigo. Angular, React y Vue son herramientas maduras con comunidades activas, ecosistemas sólidos y miles de aplicaciones en producción. La pregunta correcta no es cuál es el mejor, sino cuál resuelve mejor los problemas de tu equipo y tu proyecto.

## ¿Qué significa que un framework sea "opinionated"?

El término "opinionated framework" (framework con opiniones definidas) describe una herramienta que toma decisiones por ti: cómo estructurar el código, cómo manejar el estado, qué sistema de routing usar, cómo escribir las pruebas. Estas decisiones vienen impuestas por el framework, no dejadas a la elección del equipo.

Un framework sin opiniones fuertes (como React, que técnicamente es una librería de UI) te da más libertad, pero también más responsabilidad: debes elegir y mantener tú mismo las soluciones para routing, manejo de estado, validación de formularios, HTTP, testing y decenas de necesidades más. En equipos pequeños con desarrolladores experimentados, esa libertad es un activo. En equipos grandes y heterogéneos, es una fuente de inconsistencia y fricción.

Angular es deliberadamente opinionated. Viene con soluciones integradas para todas esas necesidades: `@angular/router`, `HttpClient`, `ReactiveForms`, `TestBed`. Un desarrollador Angular de otro equipo puede incorporarse al tuyo y reconocer inmediatamente la estructura del proyecto, porque Angular define un estándar. Esta característica tiene un costo (la curva de aprendizaje inicial) y un beneficio claro (consistencia y mantenibilidad a largo plazo).

## Comparación objetiva de características

| Característica                | Angular                             | React                              | Vue                            |
| ----------------------------- | ----------------------------------- | ---------------------------------- | ------------------------------ |
| **Tipo**                      | Framework completo                  | Librería de UI                     | Framework progresivo           |
| **Lenguaje**                  | TypeScript (obligatorio)            | JS o TS (opcional)                 | JS o TS (opcional)             |
| **Curva de aprendizaje**      | Alta (más conceptos iniciales)      | Media                              | Baja-Media                     |
| **Tamaño del equipo ideal**   | Mediano a grande                    | Cualquiera                         | Pequeño a mediano              |
| **Routing**                   | Integrado (`@angular/router`)       | Librería externa (React Router)    | Integrado (Vue Router)         |
| **Formularios**               | Integrado (Template + Reactive)     | Librería externa (React Hook Form) | Librería externa (VeeValidate) |
| **HTTP**                      | Integrado (`HttpClient`)            | Librería externa (axios, fetch)    | Librería externa               |
| **Estado global**             | Integrado (Signals) + NgRx          | Redux, Zustand, Jotai, etc.        | Vuex / Pinia                   |
| **Inyección de dependencias** | Sistema DI propio y robusto         | No nativa (Context API, hooks)     | Provide/inject (simple)        |
| **CLI oficial**               | Muy completa (`@angular/cli`)       | `create-react-app` / Vite          | `create-vue` / Vite            |
| **Testing integrado**         | Karma, Jest, Jasmine + TestBed      | Testing Library + Jest             | Vue Test Utils + Jest          |
| **Renderizado en servidor**   | `@angular/ssr`                      | Next.js                            | Nuxt.js                        |
| **Detección de cambios**      | Zone.js + Signals (Zoneless futuro) | Virtual DOM + reconciliation       | Virtual DOM + Proxy            |
| **Modelo de componentes**     | Clase + template separado           | JSX en el mismo archivo            | SFC (Single File Component)    |
| **Licencia**                  | MIT                                 | MIT                                | MIT                            |

Esta tabla muestra características, no juicios. Cada elección refleja una filosofía de diseño distinta con sus propias ventajas.

## Cuándo Angular brilla

Angular muestra su mejor cara en contextos específicos donde sus características "opinionated" se convierten en ventajas competitivas claras.

**Equipos grandes con rotación de personal.** Cuando un equipo tiene 10, 20 o 50 desarrolladores, la consistencia del código es crítica. Angular dicta dónde va cada cosa: los servicios van en `core/services`, los componentes compartidos en `shared`, la lógica de negocio fuera de los componentes. Un desarrollador nuevo puede orientarse en el proyecto en horas, no en días. React sin convenciones establecidas puede convertirse en un proyecto donde cada módulo parece escrito por un equipo diferente.

**Aplicaciones enterprise con larga vida útil.** Los proyectos que van a mantenerse durante cinco o diez años se benefician del ciclo de releases predecible de Angular, las herramientas de migración automática (`ng update`) y el soporte LTS. Google y el equipo de Angular tienen un interés directo en mantener el framework porque lo usan internamente en aplicaciones críticas como Google Ads y Google Cloud Console.

**Tipado estricto como requisito, no como opción.** TypeScript en Angular no es opcional ni superficial: el sistema de tipos se integra con el compilador de templates, de modo que los errores de tipo en el HTML se detectan en tiempo de compilación. Esto es especialmente valioso en dominios complejos (finanzas, salud, logística) donde un error de tipo puede tener consecuencias reales.

**Formularios complejos.** El sistema de formularios reactivos de Angular (Reactive Forms) es uno de los más potentes del ecosistema. Validadores síncronos y asíncronos, formularios anidados, arrays dinámicos de controles: todo está disponible de forma nativa y tipada. Los formularios complejos que requieren semanas de trabajo con soluciones externas en React suelen resolverse en días con Angular.

**Proyectos que requieren estructura desde el primer día.** Startups que anticipan crecimiento rápido del equipo, o proyectos de consultoría donde diferentes equipos toman el proyecto en distintas etapas, se benefician de las convenciones que Angular impone desde el inicio.

## Cuándo las alternativas tienen sentido

React es una excelente elección cuando el equipo quiere máxima flexibilidad para elegir su propio stack, cuando el proyecto es un producto de consumo masivo donde el rendimiento de tiempo de carga inicial es crítico, o cuando el equipo ya tiene experiencia profunda en React y el costo de cambio no se justifica. El ecosistema de React es enorme y su adopción en el mercado laboral general es alta.

Vue es ideal para proyectos donde la curva de aprendizaje importa (equipos con menos experiencia en SPA, proyectos de mediana complejidad) o cuando se quiere un framework progresivo que se puede adoptar gradualmente en una aplicación existente. Vue 3 con la Composition API ofrece un modelo mental cercano al de React con Hooks pero con una sintaxis que muchos encuentran más legible.

## El factor del ecosistema npm

Los tres frameworks tienen ecosistemas maduros, pero su naturaleza difiere. El ecosistema de React es mayoritariamente de terceros: la comunidad elige las mejores librerías y las combina. El de Angular es más centralizado: el equipo de Angular mantiene las librerías críticas bajo el scope `@angular/*`. Esto significa que las librerías oficiales de Angular siempre son compatibles con la versión actual del framework, mientras que en React puede haber desfases entre versiones de React y sus librerías de ecosistema.

## Puntos clave

- "Opinionated framework" significa que Angular toma decisiones de arquitectura por el equipo, lo que garantiza consistencia a cambio de menor flexibilidad
- Angular incluye soluciones integradas para routing, HTTP, formularios y testing; React y Vue dependen mayormente de librerías de terceros
- Angular brilla en equipos grandes, aplicaciones enterprise de larga vida y proyectos con formularios complejos o requisitos estrictos de tipado
- La elección del framework debe basarse en el contexto del equipo y el proyecto, no en popularidad de GitHub stars
- Los tres frameworks son opciones legítimas y profesionales; conocer sus diferencias reales permite tomar decisiones informadas

## ¿Qué sigue?

En la Parte 3 pasamos de la teoría a la acción: instalamos Node.js, Angular CLI y configuramos VS Code con las extensiones que maximizan la productividad al trabajar con Angular.
