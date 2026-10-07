# Proceso AI-Native SDLC (por defecto en todo proyecto)

- Cuando describa algo para construir (proyecto nuevo o feature grande), lo primero es
  `intent/intent.md` en la raíz del proyecto, con mis palabras. Lo escribís vos a partir de lo
  que diga (preguntá solo lo que falte) y me lo mostrás para confirmar. No hace falta que lo pida.
  Si no estamos en un proyecto, proponé dónde crearlo (p. ej. `~/Proyectos/<nombre>/`).
- Cadena de artefactos en `intent/`: `intent.md` → `spec.md` → `plan.md`. Cada artefacto arranca
  como `Estado: borrador`. Intent, spec y plan necesitan mi aprobación explícita para pasar a
  `Estado: aceptado`: no derives el spec sin intent aceptado, no armes el plan sin spec aceptado
  y no implementes sin plan aceptado. Nunca tomes el silencio como aprobación.
- Cuando corran superpowers brainstorming o writing-plans, mandan sus formatos y puertas de
  aprobación. Su spec y su plan se guardan en `intent/` (no en `docs/superpowers/`). La skill
  `ai-native-sdlc` solo agrega la ubicación y la trazabilidad al intent, incluidos los REQ y su
  relación con los tests; no reemplaza esos formatos ni sus revisiones.
- Antes de cada plan o cambio, contrastá el pedido con `intent/intent.md` raíz y con el intent
  de la feature relevante en `intent/<slug>/intent.md`. Si no está claro qué feature aplica,
  preguntá. Si algo se sale del alcance o cambia el concepto, frená y decímelo: se descarta, o
  se enmienda el intent correspondiente (sección `## Cambios`, fecha y motivo) con mi OK.
  Nunca lo cambies en silencio.
- Features grandes posteriores: `intent/<slug>/` con su propio intent/spec/plan, sin contradecir
  el `intent.md` raíz. La misma cadena de aprobación rige para esos tres artefactos.
