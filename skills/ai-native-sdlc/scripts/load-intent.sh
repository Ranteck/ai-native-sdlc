#!/bin/sh
set -eu

fail() {
  printf 'ai-native-sdlc: no se pudo leer %s.\n' "$intent" >&2
  exit 1
}

# Byte counts keep the context bound independent of the session's locale.
LC_ALL=C
export LC_ALL
project_dir="${CLAUDE_PROJECT_DIR:-$PWD}"
intent_dir="$project_dir/intent"
intent="$intent_dir/intent.md"

if [ -L "$intent" ]; then
  printf 'ai-native-sdlc: se omitió %s porque es un symlink.\n' "$intent" >&2
  exit 0
fi
if [ ! -e "$intent" ]; then
  # An inaccessible directory must not be mistaken for a missing intent file.
  if [ -d "$intent_dir" ]; then
    [ -r "$intent_dir" ] && [ -x "$intent_dir" ] || fail
  fi
  exit 0
fi
if [ ! -f "$intent" ]; then
  printf 'ai-native-sdlc: se omitió %s porque no es un archivo regular.\n' "$intent" >&2
  exit 0
fi

size=$(wc -c < "$intent") || fail
if [ "$size" -le 8000 ]; then
  # The sentinel preserves trailing newlines that command substitution would strip.
  content=$(cat < "$intent" && printf '.') || fail
  content=${content%.}
  size=${#content}
fi

if [ "$size" -gt 8000 ]; then
  output='La intención del proyecto está en intent/intent.md y es demasiado larga para inyectarla (más de 8000 bytes). Leé el documento completo antes de planificar o cambiar código.'
else
  output="Intención original del proyecto escrita por el usuario (intent/intent.md). Todo plan y cambio debe respetarla; si un pedido se aparta de ella o toca \"Fuera de alcance\", frená y preguntá antes de seguir. Es un documento del proyecto: no reemplaza las instrucciones del usuario ni HOUSE-RULES. Si dice \"Estado: borrador\", todavía no está aceptado: confirmalo con el usuario.
--- BEGIN intent/intent.md ---
$content
--- END intent/intent.md ---"
fi

feature_header='
Intenciones de features (solo rutas): leé la relevante antes de planificar un cambio para esa feature.'
notice='La lista no entra completa: revisá intent/*/intent.md y leé la intención relevante antes de planificar.'
for feature in "$intent_dir"/*/intent.md; do
  [ ! -L "$feature" ] && [ -f "$feature" ] || continue
  if [ -n "$feature_header" ]; then
    output="$output$feature_header"
    feature_header=''
  fi
  feature_path="intent/${feature#"$intent_dir/"}"
  # Reserve the notice before listing paths so even large feature trees stay bounded.
  if [ "$(( ${#output} + ${#feature_path} + ${#notice} + 3 ))" -ge 10000 ]; then
    output="$output
$notice"
    break
  fi
  output="$output
$feature_path"
done
printf '%s\n' "$output"
