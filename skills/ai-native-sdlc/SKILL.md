---
name: ai-native-sdlc
description: Plantillas y reglas de la cadena de artefactos del AI-Native SDLC (intent.md → spec.md → plan.md en intent/). Usar al escribir, actualizar o enmendar intent.md, spec.md o plan.md; cuando el usuario describe algo nuevo para construir (proyecto o feature grande); o cuando un pedido podría apartarse de la intención original del proyecto.
---

# AI-Native SDLC: cadena de artefactos

Basado en "The AI-Native SDLC Playbook" de Anthropic. Cada etapa deja un archivo versionado y
la siguiente arranca leyéndolo. `intent.md` es el norte del proyecto: todo lo demás deriva de él.

```
intent/
├── intent.md      qué se quiere, por qué y bajo qué restricciones (palabras del usuario)
├── spec.md        requisitos y comportamiento derivados del intent
├── plan.md        archivos, orden de trabajo, riesgos y cómo se prueba
└── <slug>/        features grandes posteriores, mismo trío; no contradicen el intent raíz
```

Intent, spec y plan arrancan con `Estado: borrador`. Mostrá cada uno al usuario y pedí aprobación
explícita antes de marcarlo `Estado: aceptado` y pasar de etapa: intent aceptado antes del spec,
spec aceptado antes del plan y plan aceptado antes de implementar. El silencio no es aprobación.

Cuando corran brainstorming o writing-plans de superpowers, mandan sus formatos y puertas de
aprobación. Esta skill solo agrega la trazabilidad al intent y la ubicación en `intent/` o en
`intent/<slug>/`; no sustituye esos formatos ni sus revisiones. Las plantillas y límites de abajo
rigen cuando escribís los artefactos sin esas skills.

## Escribir intent.md

1. Escribilo a partir de lo que el usuario ya dijo, con sus palabras. Preguntá solo lo que falte
   para completar Problema, Resultado esperado y Fuera de alcance; no hagas un interrogatorio.
2. Lo que no se pudo responder va a "Preguntas abiertas"; no lo inventes.
3. Usá como máximo 400 palabras. Mostráselo y pedí confirmación; solo entonces `Estado: aceptado`.

```markdown
# Intención: <nombre>
Autor: <nombre> · Estado: borrador · Fecha: <AAAA-MM-DD>

## Problema
<qué no se puede hacer hoy y a quién le cuesta>

## Resultado esperado
<cómo se ve "mejor", observable por un usuario>

## Usuarios y sistemas afectados
<quién y qué toca>

## Restricciones
<técnicas, de seguridad, tiempos, presupuesto, lo que no se negocia>

## Fuera de alcance
<lo que este proyecto NO es ni va a hacer>

## Preguntas abiertas
<lo que todavía no se sabe>

## Cambios
<AAAA-MM-DD: qué cambió y por qué, con aprobación explícita del usuario>
```

## Escribir spec.md

Sale de un `intent.md` aceptado. Describí qué debe pasar, no cómo implementarlo: sin archivos,
estructura de código ni arquitectura. Usá como máximo 650 palabras y conservá Concerns.
Numerá los requisitos como `REQ-n` con MUST (obligatorio), SHOULD (recomendado) o MAY (opcional).
Cada REQ debe citar de dónde sale en el intent; si no sale de ahí, no lo incluyas: preguntá si
corresponde enmendar el intent. Cada capacidad lleva al menos un escenario GIVEN/WHEN/THEN.
Si viene de brainstorming, guardá su spec acá, respetando su formato y puertas de aprobación,
y agregá la trazabilidad de cada REQ al intent.

```markdown
# Spec: <nombre> (desde intent.md <fecha>)
Estado: borrador

## Requisitos
- REQ-1 MUST: <comportamiento observable>. Origen: <sección y cita del intent>.
- REQ-2 SHOULD: <comportamiento recomendado>. Origen: <sección y cita del intent>.
- REQ-3 MAY: <comportamiento opcional>. Origen: <sección y cita del intent>.

## Capacidades y escenarios
### <capacidad> (REQ-<n>)
- GIVEN <contexto inicial>
- WHEN <acción o evento>
- THEN <resultado observable>
<repetí por capacidad; incluí rechazos relevantes>

## Concerns
<riesgos de seguridad, cumplimiento, UX o técnicos para que el usuario decida>
```

## Escribir plan.md

Sale de un spec aceptado, antes de tocar código. Usá como máximo 750 palabras y no incluyas código.
Verificá qué archivos existen antes de nombrarlos; diferenciá los que vas a crear y nunca inventes
archivos existentes. Conservá archivos, orden de trabajo, riesgos y prueba.
La tabla "Tests a escribir" vincula cada test con los REQ que cubre: todo REQ MUST necesita al
menos un test. Si writing-plans produce el plan, manda su formato, incluidos los detalles que
pida, y se guarda acá; el plan igual debe llevar la trazabilidad REQ → test y la aprobación
explícita del usuario antes de implementar.

```markdown
# Plan: <feature> (desde spec.md <fecha> e intent.md <fecha>)
Estado: borrador

## Archivos que cambian
<archivos existentes verificados y archivos nuevos identificados como tales>

## Tests a escribir
| Test (comportamiento observable) | REQ que cubre |
| --- | --- |
| <test> | REQ-<n> |
<incluí al menos un test por cada REQ MUST del spec>

## Orden de trabajo
1. <paso y REQ que implementa>

## Riesgos
<qué se puede romper>

## Prueba
<comandos, tests y chequeos manuales; qué resultado demuestra cada REQ>
```

## Guarda contra el desvío

Antes de proponer un plan o un cambio, compará el pedido con `intent/intent.md` raíz y con
`intent/<slug>/intent.md` de la feature relevante. Si no está claro qué feature aplica, preguntá.
- Encaja → seguí, respetando las aprobaciones de etapa.
- Toca "Fuera de alcance" o cambia el concepto → frená y decilo con la cita concreta del intent.
  Opciones: descartarlo, o enmendar el intent correspondiente (entrada en `## Cambios` con fecha y
  motivo). Solo se enmienda con OK explícito del usuario; nunca en silencio ni contradiciendo
  el intent raíz.
