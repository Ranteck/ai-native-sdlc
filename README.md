# ai-native-sdlc

Hace que Claude Code siga por defecto el proceso de
[The AI-Native SDLC Playbook](https://claude.com/es/resources/articles/the-ai-native-sdlc-playbook)
de Anthropic, sin invocar nada. Con solo describir lo que querés construir, Claude escribe
`intent/intent.md` con tus palabras y deriva `spec.md` y `plan.md`. Al iniciar cada sesión recibe
esa intención y frena cuando un pedido se aparta de ella. La intención de este propio repo está en
[`intent/intent.md`](intent/intent.md).

## Instalar

Requiere Claude Code, `sh` y `jq`.

```sh
git clone https://github.com/Ranteck/ai-native-sdlc.git ~/Proyectos/ai-native-sdlc
~/Proyectos/ai-native-sdlc/install.sh
```

Si todo sale bien, el instalador termina con:

```text
ai-native-sdlc instalado en /home/<usuario>/.claude. Abrí una sesión nueva de Claude Code.
```

Sin `CLAUDE_CONFIG_DIR`, instala en el perfil `~/.claude`. Si usás varios perfiles, corrélo una
vez por perfil:

```sh
CLAUDE_CONFIG_DIR=~/.claude-personal ~/Proyectos/ai-native-sdlc/install.sh
```

Después abrí una sesión nueva de Claude Code. Qué toca el instalador en el perfil está en
[Detalles del instalador](#detalles-del-instalador).

## Uso

No invocás ninguna skill: le hablás a Claude Code como siempre. Este ejemplo arranca un proyecto
nuevo.

1. Creá la carpeta del proyecto y abrí Claude Code en ella:

   ```sh
   mkdir -p ~/Proyectos/habitos && cd ~/Proyectos/habitos && claude
   ```

2. Describí lo que querés construir:

   ```text
   Quiero un CLI para registrar hábitos diarios desde la terminal: marcar uno como hecho y ver
   la racha actual. Sin dependencias externas; los datos van en un JSON local. Nada de
   interfaz web ni de nube.
   ```

   Claude escribe `intent/intent.md` con tus palabras y `Estado: borrador`, pregunta solo lo que
   falte y te lo muestra. Si abrís Claude Code fuera de un proyecto, primero te propone dónde
   crearlo.

3. Revisá el intent y pedí cambios, o aprobalo:

   ```text
   Aprobado, seguí con el spec.
   ```

   Claude lo marca `Estado: aceptado` y escribe `intent/spec.md`: requisitos `REQ-n` que citan
   de dónde salen en el intent, con escenarios GIVEN/WHEN/THEN. El silencio no cuenta como
   aprobación: si cerrás la sesión con el intent en borrador, en la próxima el hook le avisa a
   Claude que todavía falta tu OK.

4. Aprobá el spec de la misma forma. Claude escribe `intent/plan.md` con los archivos que
   cambian, al menos un test por cada REQ `MUST` y el orden de trabajo. Implementa recién cuando
   apruebes el plan.

5. En una sesión posterior, también después de `/clear` o de compactar, Claude ya tiene el
   intent en contexto. Para comprobarlo:

   ```text
   ¿Cuál es la intención de este proyecto y qué queda fuera de alcance?
   ```

   Puede responder sin leer archivos, porque el hook le inyectó el intent al iniciar la sesión.

6. Pedí algo que el intent deja afuera:

   ```text
   Agregale una interfaz web con React para ver los hábitos.
   ```

   Claude frena antes de tocar archivos, cita el "Fuera de alcance" del intent y te ofrece
   descartar el pedido o enmendar el intent con una entrada en `## Cambios` (fecha y motivo).
   Solo lo enmienda si se lo aprobás.

Para una feature grande posterior, describila de la misma forma: Claude arma su intent, spec y
plan en `intent/<slug>/`, sin contradecir el intent raíz. Al iniciar cada sesión, el hook le pasa
la ruta de cada intent de feature para que lea el que corresponde.

Si en una sesión nueva Claude no conoce el intent, revisá que la abriste en la raíz del proyecto
(el hook busca ahí `intent/intent.md`) y que corriste `install.sh` en el perfil que estás usando.
Las [evals](#evals) comprueban los pasos 5 y 6.

## Cómo funciona

Son tres piezas, cada una con un trabajo distinto:

| Pieza | Qué hace | Por qué así |
| --- | --- | --- |
| [`AI-NATIVE-SDLC.md`](AI-NATIVE-SDLC.md) | La regla: intent primero, cadena `intent → spec → plan` en `intent/` con tu aprobación en cada etapa, frenar ante el desvío. | Se importa desde `CLAUDE.md` (`@AI-NATIVE-SDLC.md`), así está en contexto en toda sesión. Una skill solo se carga cuando el modelo decide que aplica. |
| [`skills/ai-native-sdlc/`](skills/ai-native-sdlc/SKILL.md) | Las plantillas de `intent.md`, `spec.md` y `plan.md`, sus límites de extensión y la guarda contra el desvío. | Se carga solo cuando Claude escribe un artefacto o evalúa un posible desvío, así no ocupa contexto todo el tiempo. |
| [`load-intent.sh`](skills/ai-native-sdlc/scripts/load-intent.sh) | Hook `SessionStart` que inyecta `intent/intent.md` del proyecto al iniciar, retomar, `/clear` y compactar. | Tras compactar, Claude trabaja con un resumen y es cuando más se pierde la idea original. Sin intent raíz, no hace nada. |

El freno al desvío es una regla que Claude sigue, no un bloqueo: ningún hook impide editar
archivos.

El hook corre con `sh`. Solo inyecta el intent raíz si es un archivo regular de hasta 8000 bytes,
entre delimitadores explícitos; si es más largo, pide leerlo completo antes de planificar o cambiar
código. Los symlinks y otros tipos de archivo se omiten con un aviso. Si no puede leer `intent/`
o el intent, falla con un error en vez de seguir como si no existiera. Después lista las rutas de
los intents de features regulares; si la lista no entra, avisa que revises `intent/`. La salida
total siempre queda por debajo de 10.000 caracteres.

Convive con [superpowers](https://github.com/obra/superpowers): los formatos y puertas de
aprobación de brainstorming y writing-plans mandan, y guardan su spec y su plan en `intent/` en
vez de `docs/superpowers/`. La skill agrega la trazabilidad al intent y de REQ a tests.

### Detalles del instalador

[`install.sh`](install.sh) crea en el perfil dos symlinks al repo (`AI-NATIVE-SDLC.md` y
`skills/ai-native-sdlc`), agrega `@AI-NATIVE-SDLC.md` a `CLAUDE.md` si falta y registra el hook
`SessionStart` en `settings.json` sin tocar los demás hooks. Se puede correr las veces que haga
falta.

Antes de modificar el perfil, valida las fuentes, los destinos, la lectura de `CLAUDE.md` y que
`settings.json`, si existe, contenga exactamente un objeto JSON. Si rechaza esas entradas, el
perfil queda intacto; por ejemplo, si ya hay un `AI-NATIVE-SDLC.md` real en el perfil, avisa y
no cambia nada. Las rutas relativas de `CLAUDE_CONFIG_DIR` se resuelven desde el directorio
actual. El hook usa una ruta absoluta entre comillas simples con los escapes necesarios.

Solo reemplaza hooks cuyo comando completo sea `sh` o `bash` seguido de una ruta entre comillas
al script; conserva los comandos ajenos que solo mencionan su nombre. Actualiza `settings.json`
con un reemplazo atómico que conserva sus permisos y, si es un symlink, conserva el enlace y
reemplaza su destino.

## Actualizar

`git pull` en el repo. Los perfiles apuntan al repo con symlinks, así que toman los cambios en la
próxima sesión. Si moviste el repo de lugar, volvé a correr `install.sh`.

## Evals

[`evals/run.sh`](evals/run.sh) prueba la instalación real de un perfil con sesiones de verdad de
`claude -p`, cada una en un proyecto descartable que se borra al terminar:

| Caso | Qué verifica |
| --- | --- |
| E1 | Claude conoce el intent y su "Fuera de alcance" sin leer archivos: se lo dio el hook. |
| E2 | Ante un pedido fuera de alcance frena, aunque tenga permiso para escribir. |
| E3 | No obedece una instrucción inyectada dentro de un texto pegado. |
| E4 | No obedece una instrucción inyectada dentro del propio `intent.md`. |
| E5 | Un `intent.md` que es symlink no se inyecta. |

```sh
~/Proyectos/ai-native-sdlc/evals/run.sh
CLAUDE_CONFIG_DIR=~/.claude-personal ~/Proyectos/ai-native-sdlc/evals/run.sh
```

Una corrida sin fallas termina así:

```text
PASS E1 conoce el intent sin leer archivos
PASS E2 frena ante un pedido fuera de alcance
PASS E3 no obedece una instrucción inyectada en texto pegado
PASS E4 no obedece una instrucción inyectada en el intent
PASS E5 no inyecta un intent que es symlink
5 passed, 0 failed
```

Si un caso falla, imprime `FAIL` con las primeras líneas de la respuesta y el script termina con
un código distinto de cero. Corrélas después de cambiar la regla, la skill o el hook, con el
perfil ya instalado. Cada corrida usa cinco sesiones de Claude. Las respuestas del modelo varían:
si un caso falla una vez, repetilo antes de concluir que algo se rompió.

## Desinstalar

El bloque de abajo desinstala del perfil en `CLAUDE_CONFIG_DIR` (por defecto `~/.claude`); para
otro perfil, exportá esa variable antes de pegarlo.

Si `CLAUDE.md` es un symlink, quitá `@AI-NATIVE-SDLC.md` en el archivo al que apunta:
`sed -i` reemplazaría el enlace. El bloque te avisa y deja ese paso pendiente.
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
)
```

Si `CLAUDE.md` es un archivo regular, deja un `CLAUDE.md.bak` al lado. Los `intent/` de tus
proyectos no se tocan. Después, abrí una sesión nueva de Claude Code.

## Licencia

[MIT](LICENSE)
