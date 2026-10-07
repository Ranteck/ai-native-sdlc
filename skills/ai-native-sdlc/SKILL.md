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
├── spec.md        requisitos y diseño derivados del intent
├── plan.md        archivos, orden de trabajo, riesgos y cómo se prueba
└── <slug>/        features grandes posteriores, mismo trío; no contradicen el intent raíz
```

## Escribir intent.md

1. Escribilo a partir de lo que el usuario ya dijo, con sus palabras. Preguntá solo lo que falte
   para completar Problema, Resultado esperado y Fuera de alcance; no hagas un interrogatorio.
2. Lo que no se pudo responder va a "Preguntas abiertas"; no lo inventes.
3. Mostráselo y pedí confirmación. Al confirmarlo, `Estado: aceptado`.

```markdown
# Intención: <nombre>
Autor: <nombre> · Estado: borrador | aceptado · Fecha: <AAAA-MM-DD>

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
<!-- AAAA-MM-DD: qué cambió y por qué (aprobado por el usuario) -->
```

## Escribir spec.md

Sale de un `intent.md` aceptado. Si viene de brainstorming, el diseño validado se guarda acá.

```markdown
# Spec: <nombre> (desde intent.md <fecha>)

## Requisitos
<numerados; cada uno trazable a una parte del intent>

## Diseño
<arquitectura, componentes, flujo de datos, decisiones y por qué>

## Concerns
<riesgos de seguridad, cumplimiento, UX o técnicos marcados para que el usuario decida>
```

## Escribir plan.md

Sale del spec, antes de tocar código. Si viene de writing-plans, se guarda acá.

```markdown
# Plan: <feature> (desde intent.md <fecha>)

## Archivos que cambian
<lista>

## Orden de trabajo
1. <paso>

## Riesgos
<qué se puede romper>

## Prueba
<cómo se verifica que funciona: comandos, tests, chequeo manual>
```

## Guarda contra el desvío

Antes de proponer un plan o un cambio, compará el pedido con `intent.md`:
- Encaja → seguí.
- Toca "Fuera de alcance" o cambia el concepto → frená y decilo con la cita concreta del intent.
  Opciones: descartarlo, o enmendar `intent.md` (entrada en `## Cambios` con fecha y motivo).
  Solo se enmienda con OK explícito del usuario; nunca en silencio.
