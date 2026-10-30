#!/bin/sh
set -eu

fail() {
  printf 'ai-native-sdlc: %s\n' "$*" >&2
  exit 1
}

dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
case "$dir" in
  /*) ;;
  *) dir="$PWD/$dir" ;;
esac
repo="$(CDPATH= cd "$(dirname "$0")" && pwd)"
settings="$dir/settings.json"
settings_target="$settings"
hook_path="$dir/skills/ai-native-sdlc/scripts/load-intent.sh"
escaped_path=$(printf '%s' "$hook_path" | sed "s/'/'\\\\''/g")
hook_cmd="sh '$escaped_path'"

for source in "$repo/AI-NATIVE-SDLC.md" "$repo/skills/ai-native-sdlc/SKILL.md" \
              "$repo/skills/ai-native-sdlc/scripts/load-intent.sh"; do
  [ -f "$source" ] && [ -r "$source" ] ||
    fail "falta una fuente legible del repo: $source."
done
command -v jq >/dev/null 2>&1 || fail 'necesitás jq para editar settings.json; instalalo y volvé a correr el script.'

# Real destinations may contain the user's work; validate them before any mutation.
for target in "$dir/AI-NATIVE-SDLC.md" "$dir/skills/ai-native-sdlc"; do
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    fail "$target existe y no es un symlink; no se cambió nada."
  fi
done
for directory in "$dir" "$dir/skills"; do
  if { [ -e "$directory" ] || [ -L "$directory" ]; } && [ ! -d "$directory" ]; then
    fail "$directory no es una carpeta accesible."
  fi
done

append_import=yes
if [ -e "$dir/CLAUDE.md" ] || [ -L "$dir/CLAUDE.md" ]; then
  [ -f "$dir/CLAUDE.md" ] && [ -r "$dir/CLAUDE.md" ] ||
    fail "no se puede leer $dir/CLAUDE.md como archivo regular."
  # Without -q, grep finishes reading, so a late read error cannot look like a match.
  # Any path form counts: a symlinked CLAUDE.md needs an absolute import such as @~/.claude/AI-NATIVE-SDLC.md.
  if grep -xE '@(.*/)?AI-NATIVE-SDLC\.md' "$dir/CLAUDE.md" >/dev/null; then
    append_import=no
  else
    status=$?
    [ "$status" -eq 1 ] || fail "falló la lectura del import en $dir/CLAUDE.md (grep: $status)."
    [ -w "$dir/CLAUDE.md" ] || fail "no se puede agregar el import a $dir/CLAUDE.md."
  fi
fi

# Replace the final target on its own filesystem, keeping every symlink in the chain.
links=0
while [ -L "$settings_target" ]; do
  links=$((links + 1))
  [ "$links" -le 40 ] || fail "no se pudo resolver $settings: demasiados symlinks."
  link=$(readlink "$settings_target") || fail "no se pudo leer el symlink $settings_target."
  case "$link" in
    /*) settings_target="$link" ;;
    *) settings_target="$(dirname "$settings_target")/$link" ;;
  esac
done
if [ "$links" -gt 0 ]; then
  [ -d "$(dirname "$settings_target")" ] || fail "no existe la carpeta destino de $settings."
fi

# Check the nearest existing parent before creating directories or replacing links.
for directory in "$dir" "$dir/skills" "$(dirname "$settings_target")"; do
  while [ ! -d "$directory" ]; do
    if [ -e "$directory" ] || [ -L "$directory" ]; then
      fail "$directory no es una carpeta accesible."
    fi
    directory=$(dirname "$directory")
  done
  [ -w "$directory" ] && [ -x "$directory" ] ||
    fail "no se puede escribir en la carpeta $directory."
done

settings_source=/dev/null
missing_settings=true
if [ -e "$settings_target" ]; then
  [ -f "$settings_target" ] && [ -r "$settings_target" ] ||
    fail "no se puede leer $settings como archivo regular."
  settings_source="$settings_target"
  missing_settings=false
fi

# Match only complete shell invocations, including POSIX escapes in single-quoted paths.
merged=$(jq -s --arg cmd "$hook_cmd" --argjson missing "$missing_settings" '
  def ours:
    (.command? // "")
    | if type == "string" then
        test("\\A(sh|bash) (\u0027([^\u0027]|\u0027\\\\\u0027\u0027)*/skills/ai-native-sdlc/scripts/load-intent\\.sh\u0027|\"([^\"\\\\]|\\\\.)*/skills/ai-native-sdlc/scripts/load-intent\\.sh\")\\z")
      else false end;
  if $missing then [{}] else . end
  | if length != 1 or (.[0] | type) != "object" then
    error("settings.json debe contener exactamente un objeto JSON")
  else .[0] end
  | .hooks.SessionStart = (
      [ (.hooks.SessionStart // [])[]
        | if any(.hooks[]?; ours)
          then (.hooks |= map(select(ours | not))) | select(.hooks != [])
          else . end ]
      + [ { matcher: "startup|resume|clear|compact",
            hooks: [ { type: "command", command: $cmd } ] } ]
    )' "$settings_source") || fail "no se pudo validar o preparar $settings; debe contener exactamente un objeto JSON y hooks compatibles."

mkdir -p "$dir/skills" || fail "no se pudieron crear las carpetas de $dir."
tmp=$(mktemp "$(dirname "$settings_target")/settings.json.XXXXXX") ||
  fail "no se pudo crear el temporal para $settings."
trap 'rm -f "$tmp"' 0
trap 'exit 1' HUP INT TERM
restore_write=no
if [ -f "$settings_target" ]; then
  cp -p "$settings_target" "$tmp" || fail "no se pudieron conservar los permisos de $settings."
  # The owned temporary can be writable during preparation even for a read-only target.
  if [ ! -w "$tmp" ]; then
    chmod u+w "$tmp" || fail "no se pudo preparar el temporal para $settings."
    restore_write=yes
  fi
fi
printf '%s\n' "$merged" > "$tmp" || fail "no se pudo escribir el temporal para $settings."
if [ "$restore_write" = yes ]; then
  chmod u-w "$tmp" || fail "no se pudieron restaurar los permisos de $settings."
fi

# Symlinks keep every profile connected to the repo after an update.
ln -sfn "$repo/AI-NATIVE-SDLC.md" "$dir/AI-NATIVE-SDLC.md" || fail "no se pudo actualizar el symlink $dir/AI-NATIVE-SDLC.md."
ln -sfn "$repo/skills/ai-native-sdlc" "$dir/skills/ai-native-sdlc" || fail "no se pudo actualizar el symlink $dir/skills/ai-native-sdlc."
if [ "$append_import" = yes ]; then
  # A leading newline separates the import from an existing unterminated last line.
  printf '\n@AI-NATIVE-SDLC.md\n' >> "$dir/CLAUDE.md" || fail "no se pudo agregar el import a $dir/CLAUDE.md."
fi
mv -f "$tmp" "$settings_target" || fail "no se pudo reemplazar el destino de $settings."

printf 'ai-native-sdlc instalado en %s. Abrí una sesión nueva de Claude Code.\n' "$dir"
