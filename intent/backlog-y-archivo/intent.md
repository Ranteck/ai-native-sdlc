# Intención: backlog y archivo de features
Autor: Denis · Estado: aceptado · Fecha: 2026-11-10

## Problema
Las features terminadas quedan en `intent/` igual que las pendientes: todas dicen
`Estado: aceptado`, así que no sé qué falta hacer. El hook me lista todas en cada sesión, y los
planes viejos (algunos de casi 200K) quedan como ruido que puede confundir al agente.

## Resultado esperado
Todo lo que está en `intent/` fuera de `intent/archivo/` es el backlog, borradores incluidos.
Mientras un agente implementa, otro puede ir preparando intents que después se toman del backlog.
Cuando una feature se termina, con mi OK, se mueve entera (intent, spec y plan) a
`intent/archivo/<slug>/`, con el plan actualizado a lo que se construyó. El hook lista solo el
backlog. Si un cambio toca una feature archivada, el agente la lee para contrastar y, si hay que modificarla, se reabre con mi OK.

## Usuarios y sistemas afectados
Yo y los agentes que trabajan en mis proyectos: `AI-NATIVE-SDLC.md`, la skill `ai-native-sdlc`
y su hook `load-intent.sh`. También los `intent/` de los proyectos que ya usan el proceso.

## Restricciones
- El `intent.md` raíz nunca se archiva.
- `archivo` es un nombre reservado: no puede ser el slug de una feature.
- Solo yo confirmo que una feature está terminada; archivar, reabrir o borrar requiere mi OK.
- Un intent preparado por otro agente sigue necesitando mi aprobación para avanzar de etapa.
- Los proyectos existentes se migran a mano, con mi OK por conjunto; `aceptado` no prueba que
  algo esté terminado.
- Sin dependencias nuevas más allá de `sh` y `jq`.

## Fuera de alcance
- Hooks que bloqueen ediciones (sigue siendo por regla).
- Mostrar el estado de cada feature en el hook o mantener un índice.
- Reservar features para que dos agentes no tomen la misma.
- Las ideas del Elephant-Goldfish Model de Google (drift report, índice de diseños).

## Preguntas abiertas
- Ninguna.

## Cambios
- 2026-11-10: aceptado tras el concilio de Codex y Antigravity. Se conserva `plan.md` al archivar,
  la guarda contra el desvío también lee lo archivado y quedan fuera el estado en el hook y las
  reservas. Motivo: decisión de Denis.
- 2026-11-10: antes de archivar, `plan.md` refleja lo que se construyó (el playbook pide actualizar
  el plan en el mismo commit cuando la implementación se aparta). Motivo: OK de Denis tras
  contrastar con el playbook.
