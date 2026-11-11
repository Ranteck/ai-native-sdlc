# Spec: backlog y archivo de features (desde intent.md 2026-11-10)
Estado: aceptado

## Requisitos
- REQ-1 MUST: el hook lista como features solo `intent/<slug>/intent.md` con `<slug>` distinto
  de `archivo`; nada bajo `intent/archivo/` aparece en su salida. Origen: Resultado esperado,
  "El hook lista solo el backlog"; Restricciones, "`archivo` es un nombre reservado".
- REQ-2 MUST: el proceso define que todo lo que está en `intent/` fuera de `intent/archivo/` es el
  backlog, incluidos los artefactos en borrador. Origen: Resultado esperado, "Todo lo que está en
  `intent/` fuera de `intent/archivo/` es el backlog, borradores incluidos".
- REQ-3 MUST: una feature se archiva solo cuando el usuario confirma que está terminada, y se mueve
  entera (intent, spec, plan y anexos) a `intent/archivo/<slug>/`, sin borrar nada; antes de moverla, si `plan.md` no refleja lo
  construido, el agente lo actualiza en el mismo commit. Origen:
  Resultado esperado, "con mi OK, se mueve entera", "con el plan actualizado"; Restricciones, "Solo yo confirmo".
- REQ-4 MUST: el `intent.md` raíz nunca se archiva. Origen: Restricciones.
- REQ-5 MUST: el agente rechaza `archivo` como slug de una feature nueva. Origen: Restricciones,
  "`archivo` es un nombre reservado".
- REQ-6 MUST: si un pedido toca una feature archivada, el agente lee `intent/archivo/<slug>/` para
  contrastar; para modificarla, propone reabrirla y la devuelve a `intent/<slug>/` solo con OK del
  usuario. Origen: Resultado esperado, "se reabre con mi OK".
- REQ-7 MUST: un artefacto preparado por otro agente queda en `Estado: borrador` hasta que el
  usuario lo apruebe. Origen: Restricciones, "sigue necesitando mi aprobación".
- REQ-8 SHOULD: al migrar un proyecto existente, el agente propone qué features archivar y
  archiva solo el conjunto que el usuario confirma; no infiere "terminada" desde `aceptado`.
  Origen: Restricciones, "Los proyectos existentes se migran a mano".

## Capacidades y escenarios
### Hook lista solo el backlog (REQ-1, REQ-2)
- GIVEN `intent/a/intent.md`, `intent/archivo/b/intent.md` e `intent/archivo/intent.md`
- WHEN arranca una sesión
- THEN la salida lista `intent/a/intent.md` y no menciona nada bajo `intent/archivo/`

### Archivar con OK (REQ-3, REQ-4)
- GIVEN la feature `a` con intent, spec y plan
- WHEN el usuario confirma que está terminada
- THEN los tres archivos quedan en `intent/archivo/a/` y `intent/a/` deja de existir
- GIVEN tests en verde pero sin confirmación del usuario
- WHEN el agente termina la implementación
- THEN pregunta si archivar y no mueve nada

### Nombre reservado (REQ-5)
- GIVEN el usuario describe una feature que se llamaría "archivo"
- WHEN el agente elige el slug
- THEN usa otro nombre y lo dice

### Feature archivada que se vuelve a tocar (REQ-6)
- GIVEN `intent/archivo/a/` existe
- WHEN un pedido modifica lo que construyó `a`
- THEN el agente contrasta con ese intent y propone reabrir; sin OK no la mueve

### Migración (REQ-8)
- GIVEN un proyecto con 15 features en `aceptado`
- WHEN el usuario pide migrarlo
- THEN el agente lista candidatas y archiva solo las que el usuario confirma

## Concerns
- Mover carpetas rompe enlaces a `intent/<slug>/` en commits, specs o código; git conserva la
  historia, pero las rutas viejas quedan muertas.
- Si una rama archiva una feature mientras otra la edita, el merge da conflicto de renombre;
  se resuelve a mano al integrar.
- REQ-3 a REQ-8 dependen de que el agente siga la regla; solo REQ-1 es verificable por script.
