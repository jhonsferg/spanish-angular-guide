# Capítulo 37 - Parte 2: Signal Forms estables: form(), field() y FieldTree

> **Parte 2 de 4** · Capítulo 37 · PARTE XVI - Angular 22

En el Capítulo 36 vimos Signal Forms como developer preview de Angular 21, con `signalForm()` y `signalControl()`. En Angular 22 la API se **estabilizó con nombres y estructura definitivos**: `form()` y `field()`, importados desde el subpath `@angular/forms/signals`. Si veniste directo del capítulo anterior, esta es la diferencia más importante a tener presente - el preview y la versión estable no son API-compatibles.

## De `signalForm()`/`signalControl()` (preview) a `form()`/`field()` (estable)

```typescript
// Angular 21 (developer preview) - API del Capítulo 36, ya no vigente
import { signalForm, signalControl } from "@angular/forms";

formulario = signalForm({
  email: signalControl("", {
    validators: [Validators.required, Validators.email],
  }),
});
```

```typescript
// Angular 22 (estable) - API definitiva
import {
  form,
  required,
  email as emailValidator,
} from "@angular/forms/signals";
import { signal } from "@angular/core";

datos = signal({ email: "" });

formulario = form(this.datos, (path) => {
  required(path.email);
  emailValidator(path.email);
});
```

La diferencia de fondo no es solo cosmética: Signal Forms estable combina **las garantías de tipado fuerte de los Reactive Forms** (Capítulo 13) **con la ergonomía declarativa de los template-driven forms** (Capítulo 12) en una sola API basada en Signals, sin `FormControl` ni `FormGroup` de por medio.

## `form()`, validadores por `path` y el `FieldTree`

`form()` recibe un `Signal` con los datos del formulario y una función de esquema donde se declaran los validadores sobre un objeto `path` que refleja la forma de los datos:

```typescript
import { Component, signal } from "@angular/core";
import { form, required, minLength } from "@angular/forms/signals";

interface Vuelo {
  from: string;
  to: string;
}

@Component({
  selector: "app-buscador-vuelos",
  standalone: true,
  template: `...`,
})
export class BuscadorVuelosComponent {
  protected readonly flight = signal<Vuelo>({ from: "", to: "" });

  protected readonly flightForm = form(this.flight, (path) => {
    required(path.from);
    required(path.to);
    minLength(path.from, 3);
  });
}
```

El resultado de `form()` es un **`FieldTree`**: una estructura de Signals anidados donde cada propiedad del formulario se representa como un Signal con su propio estado - `value()`, `dirty()`, `invalid()`, `errors()` - siguiendo exactamente la forma del objeto de datos original. No hay que "desenvolver" nada manualmente para llegar a un campo anidado: `flightForm.from` ya es, en sí mismo, un nodo del árbol con su propio estado reactivo.

## Bind en el template con `[formField]`

```html
<!-- La directiva [formField] conecta un input con un nodo del FieldTree -->
<label for="flight-from">Origen</label>
<input [formField]="flightForm.from" id="flight-from" />

@if (flightForm.from().invalid()) {
<div class="error">{{ flightForm.from().errors() | json }}</div>
}

<label for="flight-to">Destino</label>
<input [formField]="flightForm.to" id="flight-to" />
```

→ Ver Capítulo 13, Parte 4 para comparar con la validación cross-field de Reactive Forms con `ValidatorFn` - el enfoque conceptual (validar contra el estado completo del formulario) es el mismo, pero aquí se hace declarando validadores sobre `path` en vez de escribir una función imperativa.

## Submission API: enviar el formulario sin lógica manual de estado

Signal Forms estable incluye una API de envío integrada en la propia configuración del formulario, en vez de manejar el submit "a mano" con un método del componente:

```typescript
protected readonly flightForm = form(this.flight, (path) => {
  required(path.from);
  required(path.to);
}, {
  submission: {
    action: async (form) => this.guardarVuelo(form),
    ignoreValidators: "none",
    onInvalid: (form) => this.reportarErrorDeValidacion(form),
  },
});
```

```html
<!-- La directiva [formRoot] conecta el <form> completo con el FieldTree raíz -->
<form [formRoot]="flightForm">
  <input [formField]="flightForm.from" />
  <input [formField]="flightForm.to" />
  <button>Buscar vuelos</button>
</form>
```

Con `[formRoot]`, Angular maneja automáticamente el ciclo de submit: valida antes de invocar `action`, respeta `ignoreValidators` si se necesita forzar un envío con errores conocidos, y despacha a `onInvalid` cuando la validación falla - sin que el componente tenga que orquestar manualmente `formulario.valid()` antes de cada envío.

## Schemas dinámicos con `validateStandardSchema`

Cuando la validación depende de un estado externo (por ejemplo, un modo "estricto" activable por el usuario) o se quiere reutilizar un schema de una librería como Zod, `validateStandardSchema` conecta el `FieldTree` con cualquier schema que implemente el **Standard Schema** que el resultado de la validación cambie en tiempo real según un Signal:

```typescript
import { validateStandardSchema, SchemaPathTree } from "@angular/forms/signals";
import { Signal } from "@angular/core";

function validarConSchema(
  path: SchemaPathTree<Vuelo>,
  estricto: Signal<boolean>,
) {
  validateStandardSchema(path, () =>
    estricto() ? VueloZodSchemaEstricto : VueloZodSchema,
  );
}
```

Esto habilita un patrón que era incómodo con Reactive Forms: cambiar de un schema "permisivo" a uno "estricto" (por ejemplo, al pasar de un borrador a un envío final) sin reconstruir el formulario ni desregistrar/registrar validadores manualmente.

## Puntos clave

- La API estable de Signal Forms (`form()`, `field()` desde `@angular/forms/signals`) **reemplaza** al preview de Angular 21 (`signalForm()`, `signalControl()`) - no son compatibles entre sí
- `form()` devuelve un `FieldTree`: Signals anidados con `value`, `dirty`, `invalid` y `errors` por cada campo, con la misma forma que los datos originales
- `[formField]` conecta un input con un nodo del árbol; `[formRoot]` conecta el `<form>` completo con la API de submission integrada
- La API de `submission` (`action`, `ignoreValidators`, `onInvalid`) reemplaza el manejo manual de `(ngSubmit)` + validación previa
- `validateStandardSchema` permite validación dinámica y reutilizar schemas de librerías como Zod

## ¿Qué sigue?

En la Parte 3 vemos el otro cambio grande de Angular 22 en el día a día: el decorador `@Service()` como alternativa a `@Injectable({ providedIn: 'root' })`, y `injectAsync()` para cargar servicios pesados de forma perezosa.
