# Podcast Diario IA — Proyecto

## Descripción
Rutina diaria automatizada que lee newsletters de IA/tech, redacta briefing para NotebookLM,
dos posts de LinkedIn (ES + EN), guarda todo en Notion, actualiza historial en Drive,
crea borrador Gmail y actualiza NotebookLM vía Playwright.

## Reglas globales
- **Modelo**: Sonnet siempre. Nunca Opus.
- **Tarea autónoma**: NO hacer preguntas. Decidir por cuenta propia.
- **NUNCA** calcular ni escribir base64. Notion recibe texto directamente.
- Si un paso falla: anotar en Incidencias y continuar.
- Sin reintentos automáticos.
- URL NotebookLM fija, nunca cambiarla:
  `https://notebooklm.google.com/notebook/3865a42e-1acc-488e-8e7f-65f15e7b34f9`
- Posts LinkedIn NUNCA con enlaces en el cuerpo.
- Gmail no puede enviar (limitación Anthropic): solo borradores.
- Gmail no puede marcar como leído (bug Anthropic): omitir ese paso.

## MCP Servers activos
- `Gmail` — lectura newsletters, creación borradores
- `Google Drive` — historial de temas
- `Notion` — guardar briefing y posts
- `Playwright` — automatización NotebookLM (persistente con perfil Google)

## Playwright — Autenticación persistente
El perfil de Chromium se guarda en `/root/.playwright-notebooklm-profile`.
Este directorio mantiene la sesión de Google autenticada entre ejecuciones.

**Primera vez (o si la sesión expira)**: ejecutar el script de setup:
```bash
./scripts/setup-auth.sh
