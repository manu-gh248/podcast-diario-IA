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

Si falla en cualquier punto: anotar en Incidencias como "NotebookLM: [motivo]" y continuar en PASO 6.
Si hay pantalla de login de Google: anotar "NotebookLM: re-auth necesaria — ejecutar scripts/setup-auth.sh".

1. `browser_navigate` a https://notebooklm.google.com/notebook/3865a42e-1acc-488e-8e7f-65f15e7b34f9
2. Esperar 3-5 segundos.
3. `browser_screenshot` — si hay login de Google: ABORTAR PASO 5B.
4. En panel de fuentes, localizar fuente de texto pegado anterior → clic en menú ⋮ → "Eliminar fuente" / "Delete source" → confirmar.
5. Si no hay fuente anterior, saltar al punto 6.
6. Clic en botón "+" / "Añadir fuente" / "Add source".
7. Seleccionar "Texto pegado" / "Copied text" / "Paste text".
8. `browser_type` con el texto completo del PASO 4A.
9. Clic en "Insertar" / "Insert".
10. `browser_screenshot` para confirmar que la fuente aparece.
11. Localizar panel "Resumen de audio" / "Audio Overview".
12. Clic en "Generar" / "Generate".
13. Esperar 3 segundos.
14. `browser_screenshot` para confirmar que la generación comenzó.

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
- Asunto: "🎙️ AI Briefing [DD MMM YYYY] — listo en Notion"
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
    [✅/❌] NotebookLM web: [estado]

    Incidencias:
    - [lista de incidencias o "Ninguna"]
