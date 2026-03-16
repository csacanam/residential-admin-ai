---
name: actas-reunion
description: Convierte grabaciones de audio, transcripciones o notas de reunión en actas formales listas para firmar.
---

# Skill: Actas de reunión

## Cuándo usar este skill

- El usuario quiere convertir una grabación en acta.
- El usuario tiene una transcripción o notas y quiere formalizarlas.
- El usuario dice algo como: "genera el acta", "redacta el acta de la reunión", "tengo la grabación del consejo".

## Paso 1 — Resolver conjunto activo

Antes de cualquier acción, aplica la regla de contexto por conjunto definida en `CLAUDE.md`.

Confirma qué conjunto aplica y ten lista la ruta:
```
./workspace/conjuntos/{slug}/
```

Lee `./workspace/conjuntos/{slug}/conjunto.json` para conocer el nombre oficial, el tono preferido y cualquier instrucción especial del conjunto.

## Paso 2 — Identificar el tipo de entrada

Pregunta o detecta cuál es la entrada disponible:

| Tipo | Descripción |
|---|---|
| Audio ya transcrito | Un archivo `.txt` o `.md` en `reuniones/transcripciones/` |
| Texto pegado directamente | El usuario pega la transcripción en el chat |
| Notas sueltas | El usuario describe lo que pasó con puntos o párrafos |

Si el usuario menciona un archivo de audio (`.mp3`, `.m4a`, `.wav`, etc.), indícale que primero debe transcribirlo con una herramienta externa (Whisper, Otter.ai, etc.) y pegar el texto resultante. El skill trabaja desde texto.

## Paso 3 — Identificar tipo de reunión

Detecta o pregunta:

- **Consejo de administración** — sesión ordinaria o extraordinaria del consejo.
- **Asamblea general** — ordinaria o extraordinaria de propietarios.
- **Comité de convivencia** — sesión del comité.

Usa este tipo para seleccionar la plantilla correcta en `./templates/actas/`.

## Paso 4 — Extraer la información base

Del texto disponible, extrae o solicita:

| Campo | Obligatorio | Cómo obtenerlo |
|---|---|---|
| Fecha de la reunión | Sí | Del texto o pregunta |
| Hora de inicio y fin | No | Del texto si aparece |
| Lugar o modalidad | No | Del texto si aparece |
| Asistentes | Sí | Del texto o lista provista por el usuario |
| Quórum | Solo en asambleas | Del texto o pregunta |
| Temas tratados | Sí | Del texto |
| Decisiones tomadas | Sí | Del texto |
| Compromisos y responsables | Sí | Del texto |
| Próxima reunión | No | Del texto si se menciona |

**Regla crítica**: si un dato no está en el texto, déjalo como `[PENDIENTE — verificar]`. Nunca inventes información.

## Paso 5 — Seleccionar y aplicar plantilla

Usa la plantilla correspondiente al tipo de reunión:

- Consejo → `./templates/actas/acta-consejo.md`
- Asamblea → `./templates/actas/acta-asamblea.md`
- Comité de convivencia → `./templates/actas/acta-comite-convivencia.md`

Rellena la plantilla con la información extraída. Adapta el tono al indicado en `conjunto.json` (campo `tone`).

## Paso 6 — Generar el acta

Produce el acta con estas secciones:

1. **Encabezado** — nombre del conjunto, tipo de reunión, fecha, lugar, hora.
2. **Asistentes** — lista completa con nombre y cargo si aplica.
3. **Orden del día** — temas tratados numerados.
4. **Desarrollo** — resumen de cada tema con las decisiones tomadas.
5. **Compromisos** — tabla: responsable | tarea | fecha límite.
6. **Cierre** — hora de finalización, firma del presidente y secretario de la reunión.

Usa lenguaje formal pero claro. Evita tecnicismos legales innecesarios.

## Paso 7 — Guardar el output

Guarda el acta generada en:
```
./workspace/conjuntos/{slug}/reuniones/actas/acta-{tipo}-{YYYY-MM-DD}.md
```

Ejemplo:
```
./workspace/conjuntos/bosques-del-norte/reuniones/actas/acta-consejo-2026-03-15.md
```

Si ya existe un archivo con ese nombre, agrega un sufijo `-v2`, `-v3`, etc.

## Paso 8 — Crear Google Doc y compartir

Crea el acta como Google Doc usando GOG:

```bash
gog docs create "Acta {tipo} {nombre-conjunto} {YYYY-MM-DD}" --account {AGENT_EMAIL}
```

Copia el contenido del acta al documento. Luego compártelo públicamente con permiso de lectura:

```bash
gog docs share {document_id} --anyone --role reader
```

Guarda el link público.

## Paso 9 — Confirmar con link al documento

Envía este resumen al usuario — **no pegues el texto del acta en el chat**:

```
Acta lista.

📄 [Acta {tipo} — {fecha}]({link al Google Doc})

Campos pendientes de verificar: [número o "ninguno"]
```

## Restricciones del skill

- No inventar asistentes, decisiones ni compromisos.
- No modificar fechas ni cifras sin confirmación.
- Si la transcripción es muy larga (+10.000 palabras), advertir el costo estimado antes de procesar.
- Marcar con `[VERIFICAR]` cualquier parte del texto original que sea ambigua o ilegible.
- No generar actas de reuniones que no hayan ocurrido (planificación futura no aplica aquí).
