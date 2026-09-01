# Guía de contribución

¡Gracias por querer contribuir a **Angular: La Guía en Español**! Esta guía explica cómo hacerlo de forma efectiva.

---

## Tipos de contribución bienvenidas

- 🐛 **Correcciones** — errores técnicos, typos, código que no compila, información desactualizada
- 💡 **Sugerencias de contenido** — temas que faltan, ejemplos adicionales, mejoras de redacción
- 🔗 **Recursos** — enlaces útiles a la sección de recursos adicionales

---

## Entorno de desarrollo local

Necesitas [uv](https://docs.astral.sh/uv/) instalado:

```bash
# Instalar uv (si no lo tienes)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Clonar e instalar dependencias
git clone https://github.com/jhonsferg/spanish-angular-guide.git
cd spanish-angular-guide
uv sync

# Levantar el servidor de desarrollo
uv run mkdocs serve
# → http://127.0.0.1:8000
```

Alternativamente, con Docker:

```bash
docker compose up
# → http://localhost:8080
```

---

## Configurar pre-commit (recomendado)

Los hooks de pre-commit ejecutan el linter de Markdown antes de cada commit:

```bash
uv run pre-commit install
# Verificar que todo pasa:
uv run pre-commit run --all-files
```

---

## Flujo de contribución

1. **Abre un issue** usando el template correspondiente (corrección o sugerencia)
2. **Crea una rama** desde `main`:
   ```bash
   git checkout -b fix/nombre-descriptivo
   # o
   git checkout -b feat/nombre-descriptivo
   ```
3. **Realiza tus cambios** en `docs/`
4. **Verifica** que el sitio construye sin errores:
   ```bash
   uv run mkdocs build --strict
   ```
5. **Abre un Pull Request** hacia `main` — el template de PR te guiará

---

## Estándares de escritura

- **Idioma:** español neutro, sin regionalismos
- **Tono:** técnico pero accesible, como un senior explicando a un colega
- **Código:** siempre válido para la versión de Angular indicada en el capítulo; usa TypeScript estricto
- **Encabezados:** usa la jerarquía `#` → `##` → `###` sin saltar niveles
- **Ejemplos de código:** preferir ejemplos mínimos y autocontenidos

---

## Nombrado de archivos

Sigue la convención existente: `NN-titulo-con-guiones.md` donde `NN` es el número de capítulo global.

Si añades un archivo nuevo, actualiza también:
- La sección `nav` de `mkdocs.yml`
- El índice en `README.md`

---

## Preguntas

Abre un issue con el label `pregunta` o inicia una discusión en la pestaña **Discussions** del repo.
