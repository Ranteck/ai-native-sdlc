# Plan: backlog y archivo de features (desde spec.md 2026-11-10 e intent.md 2026-11-10)
Estado: aceptado

## Archivos que cambian
Existentes (verificados):
- `skills/ai-native-sdlc/scripts/load-intent.sh`: el loop de features (glob `intent/*/intent.md`)
  saltea el slug `archivo` y las carpetas de feature que son symlink (un alias no expone lo
  archivado).
- `AI-NATIVE-SDLC.md`: un bullet nuevo con la regla de backlog, archivo, nombre reservado,
  reapertura y migración. Se importa en toda sesión, así que tiene que ser corto.
- `skills/ai-native-sdlc/SKILL.md`: `archivo/` en el árbol de `intent/` y una sección "Cerrar y
  reabrir una feature" con el detalle (mover entera, intent raíz nunca, slug reservado, contrastar
  con lo archivado, migración por conjuntos).
- `README.md`: la descripción del hook dice que omite `intent/archivo/`, y el paso de features
  grandes de "Uso" explica el backlog y el archivo.
- `evals/run.sh`: casos nuevos E6 a E9.

Nuevos: ninguno.

## Tests a escribir
| Test (comportamiento observable) | REQ que cubre |
| --- | --- |
| E6: el hook instalado, corrido sobre un proyecto con `intent/a/intent.md` (en borrador), `intent/archivo/b/intent.md` e `intent/archivo/intent.md`, más dos symlinks hacia lo archivado, lista `intent/a/intent.md` y no menciona `intent/archivo` ni los alias. Corre el script directo, sin gastar sesión. | REQ-1, REQ-2 |
| E7: con la feature `a` (intent, spec y plan) y el prompt "te confirmo que `a` está terminada, archivala", quedan los tres en `intent/archivo/a/`, `intent/a/` no existe e `intent/intent.md` sigue igual. | REQ-3, REQ-4 |
| E8: con el prompt "preparame el intent de una feature nueva llamada archivo para exportar hábitos", no se crea `intent/archivo/intent.md`, el intent nuevo está en otra carpeta y dice `Estado: borrador` y el intent raíz no cambia. | REQ-5, REQ-7 |
| E9: con `intent/archivo/b/` existente y un pedido dentro de su alcance (agregar una columna de fecha al CSV), no se mueve ni se edita nada bajo `intent/` y la respuesta propone reabrir. | REQ-6 |

La parte de REQ-3 sobre actualizar `plan.md` antes de archivar es criterio del agente y no lleva
assert: se revisa en el diff de cada archivado. REQ-8 (SHOULD) no lleva eval: se verifica a mano en la primera migración real (rebake).

## Orden de trabajo
1. `load-intent.sh`: saltear `archivo` en el loop (REQ-1).
2. E6 en `evals/run.sh` y correrlo antes y después del paso 1: tiene que fallar antes y pasar
   después.
3. `AI-NATIVE-SDLC.md` y `SKILL.md`: la regla y su detalle (REQ-2 a REQ-8).
4. E7, E8 y E9 en `evals/run.sh`.
5. `README.md`: hook y sección "Uso".
6. Concilio de Codex y Antigravity, en solo lectura, sobre el diff; incluye intentar romper el
   cambio (regla 6.4).
7. Correr las evals completas en el perfil instalado.

## Riesgos
- Las evals pasan de 5 a 8 sesiones por corrida (E6 no gasta sesión).
- E7 a E9 dependen de que el modelo siga una regla: pueden dar falsos negativos por formulación;
  si fallan, se ajusta la regla, no el assert.
- E7 necesita permiso para mover archivos: usa `--permission-mode acceptEdits` y permite `Bash`
  solo para `git mv`/`mv`, a diferencia de E2 a E4 que lo bloquean.
- El bullet en `AI-NATIVE-SDLC.md` suma tokens a toda sesión de todo proyecto; se mantiene en
  pocas líneas y el detalle va a la skill.
- Los proyectos que ya tienen un slug llamado `archivo` lo dejarían de ver listado; no hay
  ninguno hoy en `~/Proyectos`, se verifica con `ls` antes de cerrar.

## Prueba
- `sh -n` sobre `load-intent.sh` y `evals/run.sh`.
- E6 rojo antes del paso 1 y verde después: demuestra REQ-1 y REQ-2.
- `evals/run.sh` completo en el perfil instalado: E1 a E5 siguen en verde (sin regresión) y E7 a
  E9 demuestran REQ-3 a REQ-7.
- `ls ~/Proyectos/*/intent/archivo` vacío antes de instalar.

## Resultado
Implementado en `4fd13f9`. La guarda contra el desvío de `SKILL.md` también contrasta con
`intent/archivo/<slug>/intent.md`. Evals completas: 9/9 en `~/.claude-personal` (2026-11-11).
