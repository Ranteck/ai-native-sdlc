#!/usr/bin/env bash
# SessionStart hook: injects the project's original intent into context on every start,
# resume, /clear and /compact, so no session (especially a freshly compacted one) drifts
# away from the concept the project was created for.
set -euo pipefail

intent="${CLAUDE_PROJECT_DIR:-$PWD}/intent/intent.md"
[[ -f "$intent" ]] || exit 0

printf '%s\n\n' "Intención original de este proyecto (intent/intent.md). Todo plan y cambio debe respetarla; si un pedido se aparta de ella o toca \"Fuera de alcance\", frená y preguntá antes de seguir."
cat -- "$intent"
