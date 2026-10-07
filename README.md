# ai-native-sdlc

Hace que Claude Code siga por defecto el proceso de
[The AI-Native SDLC Playbook](https://claude.com/es/resources/articles/the-ai-native-sdlc-playbook)
de Anthropic, sin invocar nada: con solo describir lo que querés construir, Claude escribe
`intent/intent.md` con tus palabras, deriva `spec.md` y `plan.md`, y no deja que el proyecto se
desvíe de esa intención. La intención de este propio repo está en [`intent/intent.md`](intent/intent.md).

## Cómo funciona

Son tres piezas, cada una con un trabajo distinto:

| Pieza | Qué hace | Por qué así |
| --- | --- | --- |
| [`AI-NATIVE-SDLC.md`](AI-NATIVE-SDLC.md) | La regla: intent primero, cadena `intent → spec → plan` en `intent/`, frenar ante el desvío. | Se importa desde `CLAUDE.md` (`@AI-NATIVE-SDLC.md`), así está en contexto en toda sesión. Una skill solo se carga cuando el modelo decide que aplica. |
| [`skills/ai-native-sdlc/`](skills/ai-native-sdlc/SKILL.md) | Las plantillas de `intent.md`, `spec.md` y `plan.md`. | Se cargan solo al escribir un artefacto, así no ocupan contexto todo el tiempo. |
| [`load-intent.sh`](skills/ai-native-sdlc/scripts/load-intent.sh) | Hook `SessionStart` que inyecta `intent/intent.md` del proyecto al iniciar, retomar, `/clear` y compactar. | Tras compactar, Claude trabaja con un resumen y es cuando más se pierde la idea original. Sin intent raíz, no hace nada. |

El hook corre con `sh`. Solo inyecta el intent raíz si es un archivo regular de hasta 8000 bytes,
entre delimitadores explícitos; si es más largo, pide leerlo completo antes de planificar o cambiar
código. Los symlinks y otros tipos de archivo se omiten con un aviso. Después lista las rutas de
los intents de features regulares para leer el relevante; si la lista no entra, avisa que revises
`intent/`. La salida total siempre queda por debajo de 10.000 caracteres.

Convive con superpowers: los formatos y puertas de aprobación de brainstorming y writing-plans
mandan, y guardan su spec y su plan en `intent/` en vez de `docs/superpowers/`. La skill agrega la
trazabilidad al intent y de REQ a tests. Intent, spec y plan requieren tu aprobación explícita
(`Estado: aceptado`) antes de avanzar a la etapa siguiente.

## Instalar

Requiere `sh` y `jq`.

```sh
git clone <url-del-repo> ~/Proyectos/ai-native-sdlc
~/Proyectos/ai-native-sdlc/install.sh
```

[`install.sh`](install.sh) crea en el perfil dos symlinks al repo (`AI-NATIVE-SDLC.md` y
`skills/ai-native-sdlc`), agrega `@AI-NATIVE-SDLC.md` a `CLAUDE.md` si falta y registra el hook
`SessionStart` en `settings.json` sin tocar los demás hooks. Se puede correr las veces que haga
falta. Antes de modificar el perfil, valida las fuentes, los destinos, la lectura de `CLAUDE.md`
y que `settings.json`, si existe, contenga exactamente un objeto JSON. Si rechaza esas entradas,
el perfil queda intacto. Las rutas relativas de `CLAUDE_CONFIG_DIR` se resuelven desde el directorio
actual. El hook usa una ruta absoluta entre comillas simples con los escapes necesarios.

Solo reemplaza hooks cuyo comando completo sea `sh` o `bash` seguido de una ruta entre comillas
al script; conserva los comandos ajenos que solo mencionan su nombre. Actualiza `settings.json`
con un reemplazo atómico que conserva sus permisos y, si es un symlink, conserva el enlace y
reemplaza su destino. Después, abrí una sesión nueva de Claude Code.

**Varios perfiles:** corrélo una vez por perfil.

```sh
CLAUDE_CONFIG_DIR=~/.claude-personal ~/Proyectos/ai-native-sdlc/install.sh
```

## Actualizar

`git pull` en el repo. Los perfiles apuntan al repo con symlinks, así que toman los cambios en la
próxima sesión. Si moviste el repo de lugar, volvé a correr `install.sh`.

## Desinstalar

Si `CLAUDE.md` es un symlink, quitá `@AI-NATIVE-SDLC.md` en el archivo al que apunta:
`sed -i` reemplazaría el enlace. El bloque de abajo te avisa y deja ese paso pendiente.
Solo elimina los dos enlaces del paquete si son symlinks; conserva archivos y carpetas reales.
Para el hook usa la misma regla de propiedad que el instalador y reemplaza el destino de
`settings.json` de forma atómica, conservando permisos y symlinks.

```sh
(
  set -eu
  DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
  case "$DIR" in
    /*) ;;
    *) DIR="$PWD/$DIR" ;;
  esac

  if [ -L "$DIR/CLAUDE.md" ]; then
    printf 'CLAUDE.md es un symlink: quitá el import en el archivo al que apunta; sed -i reemplazaría el enlace.\n' >&2
  elif [ -f "$DIR/CLAUDE.md" ]; then
    sed -i.bak '/^@AI-NATIVE-SDLC\.md$/d' "$DIR/CLAUDE.md"
  fi

  for target in "$DIR/AI-NATIVE-SDLC.md" "$DIR/skills/ai-native-sdlc"; do
    if [ -L "$target" ]; then
      rm "$target"
    fi
  done

  settings="$DIR/settings.json"
  links=0
  while [ -L "$settings" ]; do
    links=$((links + 1))
    if [ "$links" -gt 40 ]; then
      printf 'No se pudo resolver settings.json: demasiados symlinks.\n' >&2
      exit 1
    fi
    link=$(readlink "$settings")
    case "$link" in
      /*) settings="$link" ;;
      *) settings="$(dirname "$settings")/$link" ;;
    esac
  done
  if [ -e "$settings" ]; then
    [ -f "$settings" ] && [ -r "$settings" ] || {
      printf 'No se puede leer %s como archivo regular.\n' "$settings" >&2
      exit 1
    }
    merged=$(jq -s '
  def ours:
    (.command? // "")
    | if type == "string" then
        test("\\A(sh|bash) (\u0027([^\u0027]|\u0027\\\\\u0027\u0027)*/skills/ai-native-sdlc/scripts/load-intent\\.sh\u0027|\"([^\"\\\\]|\\\\.)*/skills/ai-native-sdlc/scripts/load-intent\\.sh\")\\z")
      else false end;
  if length != 1 or (.[0] | type) != "object" then
    error("settings.json debe contener exactamente un objeto JSON")
  else .[0] end
  | if (.hooks.SessionStart? | type) == "array" then
      .hooks.SessionStart |= map(
        if any(.hooks[]?; ours)
        then (.hooks |= map(select(ours | not))) | select(.hooks != [])
        else . end)
    else . end' "$settings")
    tmp=$(mktemp "$(dirname "$settings")/settings.json.XXXXXX")
    trap 'rm -f "$tmp"' 0
    trap 'exit 1' HUP INT TERM
    cp -p "$settings" "$tmp"
    restore_write=no
    if [ ! -w "$tmp" ]; then
      chmod u+w "$tmp"
      restore_write=yes
    fi
    printf '%s\n' "$merged" > "$tmp"
    if [ "$restore_write" = yes ]; then
      chmod u-w "$tmp"
    fi
    mv -f "$tmp" "$settings"
  fi
)
```

Si `CLAUDE.md` es un archivo regular, deja un `CLAUDE.md.bak` al lado. Los `intent/` de tus
proyectos no se tocan.
