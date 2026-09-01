# Capítulo 31 - Parte 2: Testing de Componentes con Angular Testing Library

> **Parte 2 de 4** · Capítulo 31 · PARTE XIII - Librerías Esenciales del Ecosistema

Angular Testing Library (ATL) es una filosofía de testing tanto como una librería. Su premisa central es simple pero poderosa: **los tests deberían verificar lo que el usuario ve y hace, no cómo el componente está implementado internamente**. En esta parte veamos cómo instalarla, sus queries principales y cómo escribir tests que realmente aportan confianza al proyecto.

## La filosofía ATL: testar comportamiento, no implementación

Veamos la diferencia concreta. Con el enfoque tradicional de TestBed:

```typescript
// Test frágil: acoplado a la implementación
it('debería actualizar la variable cargando', () => {
  componente.cargando = true;
  fixture.detectChanges();
  expect(componente.cargando).toBe(true); // Testamos estado interno
});
```

Con ATL:

```typescript
// Test robusto: testamos lo que el usuario ve
it('debería mostrar un indicador de carga', async () => {
  render(LoginComponent);
  const boton = screen.getByRole('button', { name: /iniciar sesión/i });
  await userEvent.click(boton);
  expect(screen.getByRole('progressbar')).toBeInTheDocument();
});
```

La diferencia clave: el segundo test seguirá siendo válido aunque cambiemos el nombre de la variable `cargando` a `estaEnviando`, o aunque cambiemos de una variable booleana a un signal. Solo fallaría si el comportamiento visible cambia.

## Instalación

```bash
npm install -D @testing-library/angular @testing-library/user-event @testing-library/jest-dom
```

Agregamos jest-dom al setup de Jest para que los matchers personalizados estén disponibles en todos los tests:

```typescript
// setup-jest.ts
import 'jest-preset-angular/setup-jest';
import '@testing-library/jest-dom'; // Agrega toBeInTheDocument, toBeDisabled, etc.
```

## Queries: cómo encontrar elementos

ATL prioriza las queries según cómo los usuarios reales interactúan con la página:

```
1. getByRole         → accesibilidad (preferida)
2. getByLabelText    → campos de formulario con etiqueta
3. getByPlaceholderText → cuando hay placeholder
4. getByText         → texto visible
5. getByDisplayValue → valor seleccionado en selects
6. getByAltText      → imágenes
7. getByTitle        → atributo title
8. getByTestId       → último recurso: data-testid
```

Cada query tiene variantes:
- `getBy...`: lanza error si no encuentra (o encuentra más de uno)
- `queryBy...`: retorna null si no encuentra (útil para verificar ausencia)
- `findBy...`: retorna Promise, espera a que el elemento aparezca (async)
- `getAllBy...`, `queryAllBy...`, `findAllBy...`: versiones para múltiples elementos

## Ejemplo completo: formulario de login

Construyamos el componente primero:

```typescript
// login.component.ts
import { Component, inject, signal } from '@angular/core';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from './auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [ReactiveFormsModule],
  template: `
    <form [formGroup]="formulario" (ngSubmit)="enviar()" novalidate>
      <h1>Iniciar sesión</h1>

      <div>
        <label for="correo">Correo electrónico</label>
        <input
          id="correo"
          type="email"
          formControlName="correo"
          placeholder="tu@correo.com"
          autocomplete="email"
        />
        @if (mostrarErrorCorreo) {
          <span role="alert">El correo es obligatorio</span>
        }
      </div>

      <div>
        <label for="contrasena">Contraseña</label>
        <input
          id="contrasena"
          type="password"
          formControlName="contrasena"
          autocomplete="current-password"
        />
        @if (mostrarErrorContrasena) {
          <span role="alert">La contraseña debe tener al menos 8 caracteres</span>
        }
      </div>

      @if (errorServidor()) {
        <p role="alert" aria-live="polite">{{ errorServidor() }}</p>
      }

      <button type="submit" [disabled]="enviando()">
        {{ enviando() ? 'Iniciando sesión...' : 'Iniciar sesión' }}
      </button>
    </form>
  `
})
export class LoginComponent {
  private readonly fb = inject(FormBuilder);
  private readonly authService = inject(AuthService);
  private readonly router = inject(Router);

  readonly enviando = signal(false);
  readonly errorServidor = signal('');

  readonly formulario = this.fb.group({
    correo:     ['', [Validators.required, Validators.email]],
    contrasena: ['', [Validators.required, Validators.minLength(8)]],
  });

  get mostrarErrorCorreo(): boolean {
    const campo = this.formulario.get('correo')!;
    return campo.invalid && campo.touched;
  }

  get mostrarErrorContrasena(): boolean {
    const campo = this.formulario.get('contrasena')!;
    return campo.invalid && campo.touched;
  }

  async enviar(): Promise<void> {
    if (this.formulario.invalid) {
      this.formulario.markAllAsTouched();
      return;
    }
    this.enviando.set(true);
    this.errorServidor.set('');
    try {
      const { correo, contrasena } = this.formulario.value;
      await this.authService.login(correo!, contrasena!);
      await this.router.navigate(['/dashboard']);
    } catch {
      this.errorServidor.set('Credenciales incorrectas. Intentá de nuevo.');
    } finally {
      this.enviando.set(false);
    }
  }
}
```

Ahora el test completo con ATL:

```typescript
// login.component.spec.ts
import { render, screen } from '@testing-library/angular';
import userEvent from '@testing-library/user-event';
import { provideRouter } from '@angular/router';
import { LoginComponent } from './login.component';
import { AuthService } from './auth.service';

describe('LoginComponent', () => {
  const authServiceMock = {
    login: jest.fn(),
  };

  const opciones = {
    providers: [
      provideRouter([]),
      { provide: AuthService, useValue: authServiceMock },
    ],
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('debería renderizar el formulario completo', async () => {
    await render(LoginComponent, opciones);

    expect(screen.getByRole('heading', { name: /iniciar sesión/i })).toBeInTheDocument();
    expect(screen.getByLabelText(/correo electrónico/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/contraseña/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /iniciar sesión/i })).toBeInTheDocument();
  });

  it('debería mostrar errores de validación al enviar vacío', async () => {
    await render(LoginComponent, opciones);
    const usuario = userEvent.setup();

    await usuario.click(screen.getByRole('button', { name: /iniciar sesión/i }));

    expect(screen.getByText(/el correo es obligatorio/i)).toBeInTheDocument();
    expect(screen.getByText(/la contraseña debe tener al menos/i)).toBeInTheDocument();
  });

  it('debería llamar al servicio con las credenciales correctas', async () => {
    authServiceMock.login.mockResolvedValue(undefined);
    await render(LoginComponent, opciones);
    const usuario = userEvent.setup();

    await usuario.type(screen.getByLabelText(/correo electrónico/i), 'ana@ejemplo.com');
    await usuario.type(screen.getByLabelText(/contraseña/i), 'clave-segura-123');
    await usuario.click(screen.getByRole('button', { name: /iniciar sesión/i }));

    expect(authServiceMock.login).toHaveBeenCalledWith('ana@ejemplo.com', 'clave-segura-123');
  });

  it('debería deshabilitar el botón mientras envía', async () => {
    // Simular una promesa que tarda
    authServiceMock.login.mockImplementation(
      () => new Promise(resolve => setTimeout(resolve, 100))
    );
    await render(LoginComponent, opciones);
    const usuario = userEvent.setup();

    await usuario.type(screen.getByLabelText(/correo electrónico/i), 'ana@ejemplo.com');
    await usuario.type(screen.getByLabelText(/contraseña/i), 'clave-segura-123');
    await usuario.click(screen.getByRole('button', { name: /iniciar sesión/i }));

    expect(screen.getByRole('button', { name: /iniciando sesión/i })).toBeDisabled();
  });

  it('debería mostrar error del servidor cuando el login falla', async () => {
    authServiceMock.login.mockRejectedValue(new Error('Unauthorized'));
    await render(LoginComponent, opciones);
    const usuario = userEvent.setup();

    await usuario.type(screen.getByLabelText(/correo electrónico/i), 'mal@correo.com');
    await usuario.type(screen.getByLabelText(/contraseña/i), 'clave-incorrecta');
    await usuario.click(screen.getByRole('button', { name: /iniciar sesión/i }));

    expect(await screen.findByRole('alert')).toHaveTextContent(/credenciales incorrectas/i);
  });
});
```

## Inputs del componente con ATL

Cuando testamos componentes que reciben `@Input`:

```typescript
// producto-detalle.component.spec.ts
import { render, screen } from '@testing-library/angular';
import { ProductoDetalleComponent } from './producto-detalle.component';

it('debería mostrar el nombre del producto', async () => {
  await render(ProductoDetalleComponent, {
    componentInputs: {
      nombre: 'Laptop Gaming Pro',
      precio: 3500000,
      enStock: true,
    },
  });

  expect(screen.getByText('Laptop Gaming Pro')).toBeInTheDocument();
  expect(screen.getByText(/disponible/i)).toBeInTheDocument();
});
```

## Puntos clave

- ATL promueve testar comportamiento observable por el usuario, no estado interno del componente.
- La jerarquía de queries: `getByRole` es la más semántica y accesible; `getByTestId` es el último recurso.
- `userEvent` simula eventos del usuario de forma más realista que `fireEvent`; siempre preferirla.
- `findBy...` es la versión async de `getBy...`; usarla cuando el elemento aparece de forma asíncrona.
- `@testing-library/jest-dom` agrega matchers como `toBeInTheDocument()`, `toBeDisabled()`, `toHaveTextContent()`.

## ¿Qué sigue?

En la siguiente parte profundizamos en testing de servicios con `HttpTestingController` y cómo testear componentes que dependen de un store NgRx con `MockStore`.
