# Proceso AI-Native SDLC (por defecto en todo proyecto)

- Cuando describa algo para construir (proyecto nuevo o feature grande), lo primero es
  `intent/intent.md` en la raíz del proyecto, con mis palabras. Lo escribís vos a partir de lo
  que diga (preguntá solo lo que falte) y me lo mostrás para confirmar. No hace falta que lo pida.
  Si no estamos en un proyecto, proponé dónde crearlo (p. ej. `~/Proyectos/<nombre>/`).
- Cadena de artefactos en `intent/`: `intent.md` → `spec.md` → `plan.md`. El spec de brainstorming
  y el plan de writing-plans se guardan ahí (no en `docs/superpowers/`). Formatos: skill `ai-native-sdlc`.
- `intent.md` es el norte. Antes de cada plan o cambio, contrastalo. Si algo se sale del alcance o
  cambia el concepto, frená y decímelo: se descarta, o se enmienda `intent.md` (sección `## Cambios`,
  fecha y motivo) con mi OK. Nunca lo cambies en silencio.
- Features grandes posteriores: `intent/<slug>/` con su propio intent/spec/plan, sin contradecir
  el `intent.md` raíz.
