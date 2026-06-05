# Prompt — Rutina Diaria AI Briefing

## Cabecera de ejecución

MODELO: Sonnet (obligatorio — nunca Opus)
CONECTORES: Gmail, Google Drive, Notion, Playwright

---

## REGLAS GENERALES

- **Modelo**: Sonnet. Nunca Opus.
- **Tarea autónoma**: NO hagas preguntas. Decide tú.
- **NUNCA** calcules ni escribas base64. Notion recibe texto directamente.
- Si un paso falla: continúa y anota en **Incidencias** al final.
- Sin reintentos automáticos.
- URL NotebookLM fija, nunca cambiarla:
  https://notebooklm.google.com/notebook/3865a42e-1acc-488e-8e7f-65f15e7b34f9
- Posts LinkedIn **NUNCA** con enlaces en el cuerpo.
- Gmail no puede enviar (limitación Anthropic): solo borradores.
- Gmail no puede marcar como leído (bug Anthropic): omite ese paso.
- Calidad sobre cantidad.

---

## PASO 1 — LEER NEWSLETTERS (Gmail MCP)

Usar `mcp__Gmail__search_threads` con las siguientes 4 queries (últimas 48 h):

1. from:(theneuralnews OR tldr OR thegeneralist OR importai OR stratechery OR bensbites OR superhuman OR morningbrew OR techcrunch) newer_than:2d
2. subject:(AI OR "inteligencia artificial" OR LLM OR GPT OR "machine learning") newer_than:2d
3. from:(openai.com OR anthropic.com OR google.com OR microsoft.com OR deepmind.com) newer_than:2d
4. label:newsletters newer_than:2d

Para cada thread relevante, llamar `mcp__Gmail__get_thread` y extraer el cuerpo en texto plano.
Si el resultado supera el límite de tokens, leer los archivos guardados en
~/.claude/projects/*/tool-results/mcp-Gmail-get_thread-*.txt con:

    jq -r '.messages[0].plaintextBody' <archivo.txt>

Consolidar todos los textos extraídos en una lista de temas candidatos.

---

## PASO 2 — OBTENER LISTA DE EXCLUSIÓN (Google Drive MCP)

1. `mcp__Google-Drive__search_files` con query "ai-briefing-historial".
2. Si existe el archivo, `mcp__Google-Drive__read_file_content` para leer el historial.
3. Extraer los temas de **ayer** (fecha del día anterior) como lista de exclusión.
4. Si no existe el archivo, la lista de exclusión está vacía.

---

## PASO 3 — FILTRAR Y SELECCIONAR TEMAS

Criterios de selección (máximo 8 temas):
- Excluir temas ya cubiertos ayer (lista del PASO 2).
- Excluir duplicados (mismo anuncio en múltiples newsletters = 1 tema).
- Priorizar: novedades > actualizaciones > análisis de tendencias.
- Incluir al menos 1 tema de investigación académica si lo hay.
- Incluir al menos 1 tema de impacto social/laboral si lo hay.

Para cada tema dudoso de exclusión: incluirlo si el ángulo es significativamente nuevo.

---

## PASO 4A — REDACTAR TEXTO NOTEBOOKLM

Redactar en **español** un texto de briefing para NotebookLM con las siguientes reglas:

- **Extensión**: máximo 4.500 caracteres (contar siempre antes de guardar).
- **Formato**:

    AI Daily Briefing — [FECHA DD MMM YYYY]

    TEMA 1: [Título conciso]
    [2-3 párrafos de contexto, datos clave, implicaciones]

    TEMA 2: [Título conciso]
    [...]

    TEMA N: [Título conciso]
    [...]

    ---
    FUENTES:
    • [Newsletter/fuente — titular breve]
    • [...]

- Usar cifras concretas cuando las haya (porcentajes, precios, fechas, métricas).
- No añadir opinión editorial. Estilo informativo neutro.
- El texto completo será el contenido de una fuente en NotebookLM para generar un podcast.

---

## PASO 4B — REDACTAR POSTS LINKEDIN

### Post ES (español)

- **Extensión**: 2.400–2.700 caracteres. **Límite absoluto: 3.000**. Contar antes de guardar.
- **Sin enlaces** en el cuerpo del post (ni URLs, ni dominios).
- **Bullets**: usar 🔹 como viñeta.
- **Sin negrita Unicode** (solo texto normal).
- **Hashtags** al final, bloque separado (5-8 hashtags).
- **Estructura**: gancho 1-2 líneas → temas con 🔹 → cierre → hashtags.

### Post EN (inglés)

Mismas reglas que el post ES pero en inglés. No es traducción literal: adaptar tono para audiencia anglófona (más directo, menos contextual).

---

## PASO 5A — GUARDAR EN NOTION

Usar `mcp__Notion__notion-create-pages` para crear dos páginas:

**Página 1 — NotebookLM**
- title: "📻 NotebookLM — [FECHA YYYY-MM-DD]"
- content: texto completo del PASO 4A (texto plano, nunca base64).

**Página 2 — LinkedIn Posts**
- title: "💼 Posts LinkedIn — [FECHA YYYY-MM-DD]"
- content: post ES completo + separador + post EN completo + comentarios sugeridos con URL NotebookLM.

Anotar las URLs de ambas páginas Notion para usar en PASO 7.

---

## PASO 5B — ACTUALIZAR NOTEBOOKLM (Playwright MCP)

**Reglas de este paso:**
- Si falla en cualquier sub-paso: anotar en Incidencias como `NotebookLM: [motivo]` y continuar en PASO 6.
- Si detectas pantalla de login de Google en cualquier momento: ABORTAR, anotar
  `NotebookLM: re-auth necesaria — ejecutar scripts/setup-auth.sh` y continuar en PASO 6.
- Usa siempre `browser_snapshot` antes de hacer clic para localizar elementos reales.
- URL fija del notebook: `https://notebooklm.google.com/notebook/3865a42e-1acc-488e-8e7f-65f15e7b34f9`

### 5B.1 — Navegar y verificar sesión

1. `browser_navigate` → URL fija del notebook.
2. `browser_wait_for` → buscar texto "Add source" o "Añadir fuente" en la página — timeout 15 s.
3. `browser_take_screenshot` → revisar: si aparece formulario con campo de email/contraseña
   de Google, ABORTAR este paso.
4. `browser_snapshot` → para entender el estado actual de la página (fuentes existentes,
   panel Audio Overview, idioma de la interfaz).

### 5B.2 — Eliminar fuente de texto anterior (si existe)

5. En el snapshot, buscar en el panel de fuentes (columna izquierda) si hay una fuente
   de tipo "texto pegado" (icono de página con texto, etiqueta "Pasted text" o similar).
6. Si existe esa fuente:
   a. `browser_click` en el botón de menú "⋮" o los tres puntos de esa fuente.
   b. `browser_snapshot` → localizar opción "Delete source" / "Eliminar fuente" /
      "Remove" en el menú desplegable.
   c. `browser_click` en esa opción.
   d. Si aparece modal de confirmación: `browser_snapshot` → `browser_click` en
      "Delete" / "Eliminar" / "Confirm".
   e. `browser_wait_for` → esperar que desaparezca la fuente del panel — timeout 8 s.
7. Si no hay fuente anterior, continuar en 5B.3.

### 5B.3 — Añadir nueva fuente con el texto del briefing

8. `browser_click` en el botón "+" o "Add source" / "Añadir fuente" del panel de fuentes.
9. `browser_snapshot` → ver las opciones del modal/menú desplegable.
10. `browser_click` en "Copied text" / "Texto copiado" / "Paste text" / "Texto pegado"
    (la opción para pegar texto plano, no para URL ni archivo).
11. `browser_wait_for` → esperar que aparezca el área de texto (textarea o div editable)
    — timeout 8 s.
12. `browser_snapshot` → confirmar que el área de texto está activa.
13. `browser_click` dentro del área de texto para enfocarla.
14. `browser_type` → pegar el **texto completo del PASO 4A** (el briefing en español,
    incluyendo título, todos los temas y la sección de fuentes).
15. `browser_click` en "Insert" / "Insertar" / "Add" para confirmar la fuente.
16. `browser_wait_for` → esperar que la nueva fuente aparezca en el panel — timeout 12 s.
17. `browser_take_screenshot` → confirmar visualmente que la fuente está añadida.

### 5B.4 — Generar Audio Overview en español

18. `browser_snapshot` → localizar el panel "Audio Overview" / "Resumen de audio"
    (normalmente en el panel derecho).
19. Si hay botón "Customize" / "Personalizar" / "Adjust" visible:
    a. `browser_click` en ese botón.
    b. `browser_snapshot` → ver formulario de personalización.
    c. En el campo de idioma: seleccionar "Spanish" / "Español".
    d. Dejar el resto de opciones por defecto.
    e. `browser_click` en "Save" / "Guardar" / "Done".
20. `browser_click` en "Generate" / "Generar" del panel Audio Overview.
21. `browser_wait_for` → esperar que aparezca spinner o estado "Generating…" / "Generando…"
    — timeout 10 s.
22. `browser_take_screenshot` → confirmar que la generación está en curso.

### 5B.5 — Esperar el audio en español y lanzar generación en inglés

23. `browser_wait_for` → esperar que aparezca botón de play ▶ o texto "Play" / "Reproducir"
    indicando que el audio ES está listo — **timeout 360 s (6 min)**.
24. Si aparece el audio:
    a. `browser_take_screenshot` → confirmar audio ES listo.
    b. `browser_click` en "Customize" / "Personalizar".
    c. `browser_snapshot` → ver formulario de personalización.
    d. En el campo de idioma: seleccionar "English" / "Inglés".
    e. `browser_click` en "Save" / "Guardar".
    f. `browser_click` en "Regenerate" / "Volver a generar" / "Generate".
    g. `browser_wait_for` → spinner de generación — timeout 10 s.
    h. `browser_take_screenshot` → confirmar que la generación EN está en curso.
    i. Anotar en resumen: `NotebookLM: audio ES listo, generación EN iniciada`.
25. Si después de 6 min no aparece el botón de play:
    a. `browser_take_screenshot`.
    b. Anotar incidencia: `NotebookLM: timeout esperando audio ES — generación EN no lanzada`.
    c. Continuar en PASO 6.

---

## PASO 6 — ACTUALIZAR HISTORIAL EN GOOGLE DRIVE

1. `mcp__Google-Drive__search_files` con query "ai-briefing-historial".
2. Si existe: `mcp__Google-Drive__read_file_content` y añadir entrada nueva.
3. Crear/actualizar con `mcp__Google-Drive__create_file`:
   - Nombre: ai-briefing-historial.md
   - Contenido:

    ## [FECHA YYYY-MM-DD]
    Temas: [lista separada por " | "]
    Descartados: [temas excluidos por lista de exclusión]

---

## PASO 7 — CREAR BORRADOR GMAIL

Usar `mcp__Gmail__create_draft` con:
- Para: manuel.crespo.marcos@gmail.com
- Asunto: "😙️ AI Briefing [DD MMM YYYY] — listo en Notion"
- Cuerpo HTML con: enlaces a ambas páginas Notion + lista de temas del día + temas descartados.

---

## RESUMEN FINAL

Al terminar todos los pasos, imprimir en pantalla:

    === AI Briefing [FECHA] — Completado ===

    ✅ Temas seleccionados: N
    ✅ Texto NotebookLM: [URL Notion]
    ✅ Posts LinkedIn: [URL Notion]
    ✅ Historial Drive: actualizado
    ✅ Gmail draft: creado
    [✅/⏳/❌] NotebookLM audio ES: [listo / generando / error]
    [✅/⏳/❌] NotebookLM audio EN: [listo / generando / no lanzado]

    Incidencias:
    - [lista de incidencias o "Ninguna"]
