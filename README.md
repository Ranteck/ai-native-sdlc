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
| [`load-intent.sh`](skills/ai-native-sdlc/scripts/load-intent.sh) | Hook `SessionStart` que inyecta `intent/intent.md` del proyecto al iniciar, retomar, `/clear` y compactar. | Tras compactar, Claude trabaja con un resumen y es cuando más se pierde la idea original. Sin `intent/`, no hace nada. |

Convive con superpowers: brainstorming y writing-plans siguen funcionando, pero guardan su spec y
su plan en `intent/` en vez de `docs/superpowers/`.

## Instalar

Requiere `jq`.

```bash
git clone <url-del-repo> ~/Proyectos/ai-native-sdlc
~/Proyectos/ai-native-sdlc/install.sh
```

[`install.sh`](install.sh) crea en el perfil dos symlinks al repo (`AI-NATIVE-SDLC.md` y
`skills/ai-native-sdlc`), agrega `@AI-NATIVE-SDLC.md` a `CLAUDE.md` si falta y registra el hook
`SessionStart` en `settings.json` sin tocar los demás hooks. Se puede correr las veces que haga
falta. Si en el perfil ya hay un archivo o carpeta real con esos nombres, no cambia nada y avisa.
Después, abrí una sesión nueva de Claude Code.

**Varios perfiles:** corrélo una vez por perfil.

```bash
CLAUDE_CONFIG_DIR=~/.claude-personal ~/Proyectos/ai-native-sdlc/install.sh
```

## Actualizar

`git pull` en el repo. Los perfiles apuntan al repo con symlinks, así que toman los cambios en la
próxima sesión. Si moviste el repo de lugar, volvé a correr `install.sh`.

## Desinstalar

```bash
DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
sed -i.bak '/^@AI-NATIVE-SDLC\.md$/d' "$DIR/CLAUDE.md"
rm "$DIR/AI-NATIVE-SDLC.md" "$DIR/skills/ai-native-sdlc"
jq '.hooks.SessionStart |= map(.hooks |= map(select((.command // "") | contains("ai-native-sdlc/scripts/load-intent.sh") | not)) | select(.hooks != []))' \
  "$DIR/settings.json" > "$DIR/settings.json.tmp" && cat "$DIR/settings.json.tmp" > "$DIR/settings.json" && rm "$DIR/settings.json.tmp"
```

Deja un `CLAUDE.md.bak` al lado de tu `CLAUDE.md`. Los `intent/` de tus proyectos no se tocan.
