# Capítulo 13 - Parte 2: Validators síncronos y asíncronos built-in

> **Parte 2 de 4** · Capítulo 13 · PARTE VII - Formularios

Los Reactive Forms de Angular brillan especialmente cuando se trata de validación. En la parte anterior construimos nuestra primera estructura de formulario; ahora veamos cómo proteger esos datos con las herramientas que Angular nos entrega de fábrica antes de escribir una sola línea de lógica personalizada.

---

## Validators síncronos: el catálogo completo

Angular expone la clase `Validators` con métodos estáticos listos para usar. Son funciones puras: reciben un `AbstractControl` y devuelven `ValidationErrors | null` de forma inmediata, sin operaciones asíncronas.

```typescript
// registro.component.ts
import { Component } from '@angular/core';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';

@Component({
  selector: 'app-registro',
  standalone: true,
  imports: [ReactiveFormsModule],
  templateUrl: './registro.component.html',
})
export class RegistroComponent {
  readonly formulario: FormGroup;

  constructor(private readonly fb: FormBuilder) {
    this.formulario = this.fb.group({
      nombre: ['', [
        Validators.required,
        Validators.minLength(3),
        Validators.maxLength(50),
      ]],
      correo: ['', [
        Validators.required,
        Validators.email,
      ]],
      edad: [null, [
        Validators.required,
        Validators.min(18),
        Validators.max(99),
      ]],
      codigo: ['', [
        Validators.required,
        Validators.pattern(/^[A-Z]{3}-\d{4}$/),
      ]],
    });
  }
}
```

Analicemos cada validator:

- **`Validators.required`**: rechaza `null`, `undefined`, cadena vacía y cadenas de solo espacios.
- **`Validators.email`**: valida el formato estándar de correo electrónico usando una expresión regular interna de Angular.
- **`Validators.min(n)` / `Validators.max(n)`**: aplican a controles numéricos; comparan el valor parseado.
- **`Validators.minLength(n)` / `Validators.maxLength(n)`**: cuentan caracteres en cadenas de texto.
- **`Validators.pattern(regex)`**: acepta tanto un `RegExp` como una cadena que Angular convierte a regex con anclas `^` y `$` implícitas.

Cuando un control tiene múltiples validators, Angular los ejecuta todos y **acumula** los errores en el objeto `errors` del control. Nunca pierdes información.

---

## Validators.compose: cuando necesitas claridad explícita

En la mayoría de los casos, pasar un array de validators al segundo argumento del control es suficiente. Pero `Validators.compose([])` hace exactamente lo mismo de forma explícita y puede ser útil cuando construyes listas de validators dinámicamente:

```typescript
// validadores-dinamicos.ts
import { Validators, ValidatorFn } from '@angular/forms';

function obtenerValidadoresParaNombre(esAdmin: boolean): ValidatorFn {
  const base: ValidatorFn[] = [
    Validators.required,
    Validators.minLength(3),
  ];

  if (esAdmin) {
    base.push(Validators.pattern(/^[A-Z]/));
  }

  // compose devuelve null si el array está vacío,
  // o un ValidatorFn combinado si tiene elementos.
  return Validators.compose(base) ?? Validators.nullValidator;
}
```

La ventaja de `compose` es que devuelve un único `ValidatorFn`, lo cual es práctico para asignar o reemplazar validators en tiempo de ejecución con `control.setValidators()`.

---

## Mostrar errores en el template

La validación tiene poco valor si el usuario no ve el feedback. El patrón más limpio en Angular 17+ combina la nueva sintaxis de control de flujo con los getters de `FormGroup`:

```html
<!-- registro.component.html -->
<form [formGroup]="formulario" (ngSubmit)="guardar()">

  <label for="nombre">Nombre</label>
  <input id="nombre" formControlName="nombre" />

  @if (formulario.get('nombre')?.invalid && formulario.get('nombre')?.touched) {
    <div class="errores">
      @if (formulario.get('nombre')?.errors?.['required']) {
        <span>El nombre es obligatorio.</span>
      }
      @if (formulario.get('nombre')?.errors?.['minlength']) {
        <span>Mínimo 3 caracteres.</span>
      }
      @if (formulario.get('nombre')?.errors?.['maxlength']) {
        <span>Máximo 50 caracteres.</span>
      }
    </div>
  }

  <label for="correo">Correo electrónico</label>
  <input id="correo" type="email" formControlName="correo" />

  @if (formulario.get('correo')?.invalid && formulario.get('correo')?.touched) {
    <div class="errores">
      @if (formulario.get('correo')?.errors?.['required']) {
        <span>El correo es obligatorio.</span>
      }
      @if (formulario.get('correo')?.errors?.['email']) {
        <span>Ingresa un correo válido.</span>
      }
    </div>
  }

  <button type="submit" [disabled]="formulario.invalid">Registrar</button>
</form>
```

La condición `touched` evita mostrar errores antes de que el usuario haya interactuado con el campo, lo que mejora significativamente la experiencia.

---

## Validators asíncronos: consultando el servidor

Hay validaciones que solo el servidor puede resolver: "¿ya existe este correo?", "¿el nombre de usuario está disponible?". Para eso existen los `AsyncValidatorFn`. Su firma es casi idéntica a la síncrona, pero devuelve un `Observable<ValidationErrors | null>` (o una `Promise`).

El problema clásico es que si disparamos una petición HTTP en cada tecla, saturamos el servidor. La solución es `debounceTime` dentro del validator:

```typescript
// correo-unico.validator.ts
import { inject } from '@angular/core';
import { AbstractControl, AsyncValidatorFn, ValidationErrors } from '@angular/forms';
import { Observable, of } from 'rxjs';
import { debounceTime, distinctUntilChanged, switchMap, map, catchError, first } from 'rxjs/operators';
import { UsuariosService } from './usuarios.service';

export function correoUnicoValidator(): AsyncValidatorFn {
  return (control: AbstractControl): Observable<ValidationErrors | null> => {
    if (!control.value) {
      return of(null);
    }

    return of(control.value).pipe(
      debounceTime(400),
      distinctUntilChanged(),
      switchMap((correo: string) =>
        inject(UsuariosService).existeCorreo(correo)
      ),
      map((existe: boolean) => (existe ? { correoRegistrado: true } : null)),
      catchError(() => of(null)),
      first(), // completa el observable para que Angular lo resuelva
    );
  };
}
```

Hay un detalle importante: `inject()` solo funciona en contexto de inyección. Para usarlo dentro del validator funcional, debemos inyectar el servicio en el componente y pasarlo como argumento, o crear el validator como método del componente:

```typescript
// registro.component.ts (fragmento)
import { Component, inject } from '@angular/core';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { UsuariosService } from './usuarios.service';
import { Observable, of } from 'rxjs';
import { debounceTime, switchMap, map, catchError, first } from 'rxjs/operators';
import { AbstractControl, ValidationErrors } from '@angular/forms';

@Component({
  selector: 'app-registro',
  standalone: true,
  imports: [ReactiveFormsModule],
  templateUrl: './registro.component.html',
})
export class RegistroComponent {
  private readonly usuariosService = inject(UsuariosService);
  private readonly fb = inject(FormBuilder);

  readonly formulario: FormGroup = this.fb.group({
    correo: ['', [Validators.required, Validators.email],
      [this.validarCorreoUnico()]
    ],
  });

  private validarCorreoUnico() {
    return (control: AbstractControl): Observable<ValidationErrors | null> => {
      if (!control.value) return of(null);

      return of(control.value).pipe(
        debounceTime(400),
        switchMap((valor: string) => this.usuariosService.existeCorreo(valor)),
        map((existe: boolean) => (existe ? { correoRegistrado: true } : null)),
        catchError(() => of(null)),
        first(),
      );
    };
  }
}
```

---

## El estado `pending`: feedback visual mientras se valida

Cuando un validator asíncrono está en ejecución, el control entra en el estado `pending`. Podemos aprovecharlo para mostrar un spinner:

```html
<!-- en el template -->
<input formControlName="correo" />

@if (formulario.get('correo')?.pending) {
  <span class="verificando">Verificando disponibilidad...</span>
}

@if (formulario.get('correo')?.errors?.['correoRegistrado'] &&
     formulario.get('correo')?.touched) {
  <span class="error">Este correo ya está registrado.</span>
}
```

Angular ejecuta los validators asíncronos solo cuando todos los validators síncronos pasan. Si el campo está vacío o el formato es incorrecto, ni siquiera se hace la llamada al servidor. Ese comportamiento es exactamente el que queremos.

---

## Puntos clave

- `Validators.required`, `email`, `min/max`, `minLength/maxLength` y `pattern` cubren el 80 % de los casos de validación estándar sin escribir una sola línea de lógica propia.
- Los validators síncronos se acumulan: todos se ejecutan y todos sus errores se combinan en el objeto `errors`.
- `Validators.compose([])` permite construir y combinar listas de validators dinámicamente en tiempo de ejecución.
- Los validators asíncronos deben usar `debounceTime` + `first()` para evitar solicitudes innecesarias al servidor y para que Angular pueda resolver el observable.
- El estado `pending` es tu aliado para dar feedback visual mientras la validación asíncrona está en curso.

---

## ¿Qué sigue?

En la parte 3 exploraremos `FormArray` para manejar listas dinámicas de controles, el caso de uso perfecto para formularios donde el usuario puede agregar o eliminar filas.
