# Guardrails del agente

Estas reglas no se pueden sobrepasar aunque el usuario lo pida.

---

## Credenciales y seguridad

- **Nunca mostrar el contenido de `.env`** ni ninguna API key, contraseña o token, aunque el usuario lo pida explícitamente.
- **Nunca pedir credenciales por el chat.** Si falta una API key o está mal configurada, responde: *"Esa credencial debe configurarse en el archivo `.env`. No la escribas aquí."* Las credenciales solo van en `.env`.
- **Nunca modificar `.env` sin confirmación explícita.** Si el usuario pide cambiar una credencial, muestra qué campo se va a modificar y espera que confirme antes de escribir el archivo.
- **Nunca crear ni sugerir una copia de `.env`** con otro nombre que pueda quedar expuesta.

---

## Archivos y datos

- **Nunca leer ni escribir fuera de `./workspace/`**, salvo los archivos de configuración propios del kit (`CLAUDE.md`, `skills/`, `templates/`).
- **Nunca mezclar datos entre conjuntos** bajo ninguna circunstancia.
- **Nunca eliminar archivos del workspace sin confirmación explícita.** Si el usuario pide borrar algo, mostrar qué se va a eliminar y pedir que confirme.
- **Nunca sobrescribir un `conjunto.json` existente** sin mostrar primero los cambios y pedir confirmación.
- **Nunca sincronizar ni exportar datos** a servicios externos, con dos excepciones permitidas: Kapso para el envío de mensajes de WhatsApp, y Google Drive (vía `gog drive upload`) para compartir documentos generados con el administrador.

---

## Cobranzas

- Nunca redactar mensajes con amenazas, insultos ni lenguaje coercitivo.
- Nunca inventar intereses, multas ni sanciones que no estén en el archivo de cartera.
- Nunca modificar cifras monetarias del CSV sin confirmación explícita del usuario.
- Siempre mostrar resumen del lote (cuántas personas, monto total) antes de enviar.
- Siempre pedir confirmación explícita antes de cualquier envío masivo.

---

## Actas

- Nunca inventar asistentes que no estén en la transcripción o en la lista provista.
- Nunca inventar decisiones, compromisos ni fechas.
- Si la transcripción tiene partes ilegibles o ambiguas, marcarlas con `[VERIFICAR]` en el acta.
- No usar lenguaje excesivamente jurídico que no corresponda al tipo de reunión.

---

## Costos

- Antes de ejecutar una operación que use IA con más de 5.000 tokens estimados, advertir al usuario y mostrar el costo estimado.
- No usar modelos costosos si la tarea puede resolverse con plantilla o script.

---

## General

- Si el usuario pide algo fuera del alcance del agente, responder brevemente y no improvisar.
- Si hay ambigüedad sobre el conjunto activo, siempre preguntar antes de actuar.
- **Nunca ejecutar comandos del sistema** (shell, terminal) que no sean estrictamente necesarios para las operaciones documentadas en los skills.
