# Intención: ai-native-sdlc
Autor: Denis · Estado: aceptado · Fecha: 2026-10-07

## Problema
En cada chat o proyecto nuevo tengo que repetirle a Claude que siga el proceso AI-Native SDLC de
Anthropic y cuál es mi idea principal. Además, los proyectos se desvían del concepto original a
medida que avanzan, sobre todo en sesiones largas o después de compactar.

## Resultado esperado
Con solo describir lo que quiero construir, Claude escribe `intent/intent.md` con mis palabras,
deriva `spec.md` y `plan.md` en `intent/`, carga la intención al iniciar cada sesión y frena cuando
un pedido se aparta de ella. Todo se reinstala en un perfil o máquina nueva con un comando.

## Usuarios y sistemas afectados
Yo, en Claude Code, en mis perfiles `~/.claude` y `~/.claude-personal`: su `CLAUDE.md`, su
`settings.json` (hook `SessionStart`) y su carpeta `skills/`.

## Restricciones
- Sin invocar skills a mano.
- Convive con superpowers (brainstorming, writing-plans); no lo reemplaza.
- Instalador idempotente, sin dependencias más allá de `sh` y `jq`, que respeta `CLAUDE_CONFIG_DIR`.
- Fuente única en `~/Proyectos/ai-native-sdlc`; los perfiles apuntan con symlinks.
- Mismo patrón que house-rules (import `@` desde `CLAUDE.md`).
- Las evals de este repo necesitan el CLI `claude` y gastan una sesión por caso; no son una
  dependencia del instalador.

## Fuera de alcance
- Etapas Test, Deploy y Maintain del playbook para mis proyectos (evals en CI, `REVIEW.md`,
  production gate, `bands.yaml`). Las evals propias de este repo sí están dentro.
- Hooks que bloqueen ediciones: el freno al desvío es por regla, no determinista.
- Soporte para Codex.
- Publicar en un marketplace de plugins.

## Preguntas abiertas
- Ninguna.

## Cambios
- 2026-10-07: se publica en GitHub como repo público (como house-rules), con LICENSE MIT. Se
  agregan evals propias del repo (`evals/run.sh`, a mano con `claude -p`, sin CI) que verifican
  que el intent se carga, que frena ante el desvío y que no se deja inyectar. Motivo: pedido
  explícito de Denis después de la revisión con graph-engineer.
