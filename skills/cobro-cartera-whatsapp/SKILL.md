---
name: cobro-cartera-whatsapp
description: Envía mensajes de cobro de cartera por WhatsApp a residentes morosos usando una plantilla aprobada por Meta y la API de Kapso.
---

# Skill: Cobro de cartera por WhatsApp

## Cuándo usar este skill

- El usuario quiere enviar mensajes de cobro a morosos.
- El usuario tiene un archivo Excel o CSV de cartera listo.
- El usuario dice algo como: "envíale a los morosos", "manda el cobro de cartera", "procesa la cartera".

## Principio fundamental

**Este skill trabaja exclusivamente con el archivo Excel o CSV que entrega el administrador.** No depende del directorio de residentes ni de ningún otro registro previo. El Excel es la fuente de verdad para ese envío. Si alguien está en el Excel, se le envía. Si no está, no se le envía. Sin excepciones.

---

## Cómo funciona el envío

Los mensajes se envían usando una **plantilla HSM aprobada por Meta** a través de la **API de Kapso**. No se envía texto libre: siempre se usa la plantilla registrada con los datos del conjunto y del moroso.

La plantilla tiene este formato fijo:

```
Cordial saludo

Le informamos que al corte de {{1}} usted adeuda la suma de {{2}} por cuotas de administración y otros.

Por lo anterior, le invitamos a acercarse a la oficina de administración a realizar un acuerdo de pago o en su defecto el pago total de la deuda a la cuenta del Conjunto Residencial.

Conjunto: {{3}}
NIT: {{4}}
Dirección: {{5}}
Banco: {{6}}
Cuenta bancaria: {{7}}
Referencia: {{8}}
Valor a pagar: {{10}}

Si hace transferencias o pagos por PSE, deben enviar el comprobante de pago al correo electrónico {{11}}

{{9}}

Le agradecemos la atención por el pago oportuno. Recuerde que los gastos e inversiones de la unidad se cancelan con lo recaudado por expensas comunes.
```

### Mapeo de variables de la plantilla

| Variable Meta | Origen | Descripción |
|---|---|---|
| `{{1}}` | CSV — columna `fecha_corte` | Fecha de corte de la deuda. Ej: "15 de marzo de 2026" |
| `{{2}}` | CSV — columna `saldo` | Valor de la deuda formateado. Ej: "$1.200.000" |
| `{{3}}` | `conjunto.json` → `name` | Nombre del conjunto |
| `{{4}}` | `conjunto.json` → `pago.nit` | NIT del conjunto |
| `{{5}}` | `conjunto.json` → `address` | Dirección del conjunto |
| `{{6}}` | `conjunto.json` → `pago.banco` | Banco donde pagar |
| `{{7}}` | `conjunto.json` → `pago.tipo_cuenta` + `pago.numero_cuenta` | Tipo y número de cuenta. Ej: "Corriente # 177-019265" |
| `{{8}}` | CSV — columna `apartamento` | Número de apartamento como referencia de pago |
| `{{9}}` | `conjunto.json` → `pago.nota_pronto_pago` | Nota especial (puede quedar vacía si no aplica) |
| `{{10}}` | CSV — columna `saldo` | Mismo valor que {{2}} |
| `{{11}}` | `conjunto.json` → `contacto.email` | Correo para envío de comprobantes |

---

## Paso 1 — Resolver conjunto activo

Antes de cualquier acción, aplica la regla de contexto por conjunto definida en `CLAUDE.md`.

Lee `./workspace/conjuntos/{slug}/conjunto.json` y verifica que estos campos estén completos:

**Campos obligatorios para este skill:**
- `name`
- `address`
- `pago.nit`
- `pago.banco`
- `pago.tipo_cuenta`
- `pago.numero_cuenta`
- `contacto.email`
- `whatsapp.template_cartera`
- `whatsapp.template_language`

Si falta algún campo obligatorio, detente e indica qué campos hay que completar en `conjunto.json` antes de continuar. No improvises datos faltantes.

### Verificar que el número de WhatsApp está activo en Kapso

Antes de continuar, valida que `KAPSO_PHONE_NUMBER_ID` corresponde a un número activo haciendo:

```
GET {KAPSO_BASE_URL}/v1/phone-numbers/{KAPSO_PHONE_NUMBER_ID}
Headers: X-API-Key: {KAPSO_API_KEY}
```

- Si responde con éxito → continuar.
- Si responde 404 o error → detener y avisar: "El número de WhatsApp configurado no está disponible en Kapso. Verifica `KAPSO_PHONE_NUMBER_ID` en el archivo de configuración."

---

## Paso 2 — Recibir el archivo de cartera

El administrador puede entregar el archivo de dos formas:

**Opción A — Archivo en la carpeta local:**
Busca el archivo más reciente en `./workspace/conjuntos/{slug}/cartera/input/`. Si hay más de uno, lista los disponibles y pregunta cuál usar.

**Opción B — Archivo enviado por correo:**
Si el usuario indica que envió el Excel al correo del agente, búscalo con:
```bash
gog gmail search 'has:attachment filename:xlsx OR filename:csv newer_than:3d' --json
```
Descarga el adjunto y procésalo directamente.

Acepta `.csv` y `.xlsx`. Si no hay ningún archivo disponible por ninguna vía:
> "No encontré el archivo de cartera. Puedes copiarlo en `cartera/input/` o enviármelo al correo del agente."

---

## Paso 3 — Validar el archivo antes de cualquier otra acción

**Este paso es obligatorio y debe completarse antes de construir cualquier mensaje.**

El archivo debe tener estas columnas mínimas (los nombres pueden variar, intenta mapearlas):

| Columna esperada | Nombres alternativos aceptados | Obligatoria |
|---|---|---|
| `nombre` | residente, propietario, titular | No (solo para logs internos, no se usa en la plantilla) |
| `apartamento` | apto, unidad, inmueble, referencia | Sí |
| `telefono` | celular, whatsapp, phone | Sí |
| `saldo` | deuda, valor, monto, total | Sí |
| `fecha_corte` | fecha, corte, periodo, mes | No (se puede omitir en la plantilla) |

**Si faltan columnas obligatorias**, detente completamente y reporta:
```
El archivo tiene un problema antes de continuar:
- Columnas faltantes: [lista]
- Columnas encontradas: [lista]

Corrige el archivo y vuelve a intentarlo.
```

**Si todas las columnas están presentes**, muestra un diagnóstico del archivo:
```
Archivo validado: cartera-marzo-2026.xlsx
- Total de filas: 18
- Filas con teléfono válido: 16
- Filas con teléfono inválido o vacío: 2 (filas 7 y 14)
- Filas con saldo en cero: 1 (fila 11 — se excluirá del envío)
- Filas listas para envío: 15
```

No continúes hasta que el usuario haya visto este diagnóstico.

---

## Paso 4 — Normalizar teléfonos

Para cada número en la columna `telefono`:

1. Eliminar espacios, guiones, paréntesis y el prefijo `+`.
2. Si tiene 10 dígitos y empieza por `3` → agregar prefijo `57`. Resultado: `573XXXXXXXXX`.
3. Si ya empieza por `57` → dejar como está.
4. Cualquier otro caso → marcar como `INVÁLIDO` y excluir del envío.

---

## Paso 5 — Construir los parámetros de cada mensaje

Para cada fila válida del CSV, construye el objeto de parámetros de la plantilla:

```json
{
  "to": "57XXXXXXXXXX",
  "nombre": "Carlos Pérez",
  "parameters": {
    "1": "15 de marzo de 2026",
    "2": "$1.200.000",
    "3": "Bosques del Norte",
    "4": "805003068-4",
    "5": "Calle 62 # 12B - 140, Cali",
    "6": "AV Villas",
    "7": "Corriente # 177-019265",
    "8": "101",
    "9": "Si cancela la totalidad de su deuda recuerde que el descuento pronto pago es de $4.000",
    "10": "$1.200.000",
    "11": "administracion@bosquesdelnorte.com"
  }
}
```

Reglas de formato:
- `saldo` y valor a pagar: formatear como `$1.200.000` (puntos como separador de miles, sin decimales si son ceros).
- `fecha_corte`: si viene como `2026-03-15` o `marzo 2026`, convertir a texto natural: "15 de marzo de 2026" o "marzo de 2026".
- `nota_pronto_pago`: si está vacío en `conjunto.json`, usar una cadena vacía `""` para la variable `{{9}}`.
- `cuenta bancaria`: concatenar `tipo_cuenta` + `" # "` + `numero_cuenta`. Ej: `"Corriente # 177-019265"`.

---

## Paso 6 — Mostrar resumen y preview antes de enviar

Obligatorio siempre, sin excepción:

```
Listo para enviar. Revisa antes de confirmar:

Conjunto: Bosques del Norte
Plantilla: cobro_cartera_v1
Total en el archivo: 18 contactos
Válidos para envío: 16
Excluidos (teléfono inválido): 2

Vista previa — Carlos Pérez (Apto 101):
────────────────────────────────────────
Cordial saludo

Le informamos que al corte de 15 de marzo de 2026 usted adeuda la suma de $1.200.000 por cuotas de administración y otros.

Por lo anterior, le invitamos a acercarse a la oficina de administración...
[resto del mensaje]
────────────────────────────────────────

¿Confirmas el envío a 16 contactos? Escribe SÍ para continuar.
```

No continúes hasta recibir confirmación explícita del usuario.

---

## Paso 7 — Enviar mensajes vía Kapso

Usa las siguientes variables del archivo `.env`:

```
KAPSO_API_KEY
KAPSO_PHONE_NUMBER_ID
KAPSO_BASE_URL
```

### Endpoint

```
POST {KAPSO_BASE_URL}/v1/messages
```

Ejemplo con el valor por defecto:
```
POST https://api.kapso.ai/meta/whatsapp/v1/messages
```

### Headers

```
X-API-Key: {KAPSO_API_KEY}
Content-Type: application/json
```

### Body por cada mensaje

```json
{
  "phoneNumberId": "{KAPSO_PHONE_NUMBER_ID}",
  "to": "57XXXXXXXXXX",
  "type": "template",
  "template": {
    "name": "{whatsapp.template_cartera del conjunto.json}",
    "language": {
      "code": "{whatsapp.template_language del conjunto.json}"
    },
    "components": [
      {
        "type": "body",
        "parameters": [
          { "type": "text", "text": "{valor de {{1}}}" },
          { "type": "text", "text": "{valor de {{2}}}" },
          { "type": "text", "text": "{valor de {{3}}}" },
          { "type": "text", "text": "{valor de {{4}}}" },
          { "type": "text", "text": "{valor de {{5}}}" },
          { "type": "text", "text": "{valor de {{6}}}" },
          { "type": "text", "text": "{valor de {{7}}}" },
          { "type": "text", "text": "{valor de {{8}}}" },
          { "type": "text", "text": "{valor de {{9}}}" },
          { "type": "text", "text": "{valor de {{10}}}" },
          { "type": "text", "text": "{valor de {{11}}}" }
        ]
      }
    ]
  }
}
```

**Importante:** los parámetros del array `parameters` deben ir en orden estricto de `{{1}}` a `{{11}}`. El orden importa.

### Manejo de errores

- Si la API devuelve error para un contacto individual, regístralo y continúa con el siguiente. No abortes el lote completo.
- Espera al menos 200ms entre llamadas para no saturar la API.
- Si la API devuelve error 429 (rate limit), espera 5 segundos y reintenta una vez.

---

## Paso 8 — Registrar log de resultados

Guarda el resultado en:
```
./workspace/conjuntos/{slug}/cartera/sent/envio-{YYYY-MM-DD-HHMM}.json
```

```json
{
  "fecha": "2026-03-15T10:35:00-05:00",
  "conjunto": "bosques-del-norte",
  "template": "cobro_cartera_v1",
  "archivo_origen": "cartera-marzo-2026.csv",
  "total_en_archivo": 18,
  "enviados_ok": 16,
  "fallidos": 1,
  "excluidos_telefono_invalido": 1,
  "detalle": [
    { "nombre": "Carlos Pérez", "apartamento": "101", "telefono": "573001234567", "estado": "ok" },
    { "nombre": "María López", "apartamento": "205", "telefono": "INVÁLIDO", "estado": "excluido" },
    { "nombre": "Jorge Ríos", "apartamento": "312", "telefono": "573154567890", "estado": "error_api", "error": "número no registrado en WhatsApp" }
  ]
}
```

Mueve el archivo original de `cartera/input/` a `cartera/processed/` con la fecha en el nombre:
```
cartera-marzo-2026_procesado-2026-03-15.csv
```

---

## Paso 9 — Mostrar resumen final

```
Envío completado.
- Conjunto: Bosques del Norte
- Enviados exitosamente: 16
- Fallidos (error API): 1
- Excluidos (teléfono inválido): 1
- Archivo movido a: cartera/processed/
- Log guardado en: [ruta completa del archivo]
```

---

## Restricciones del skill

- Nunca enviar sin confirmación explícita del usuario.
- Nunca inventar datos faltantes del conjunto (NIT, banco, cuenta). Si faltan, detener y pedir que se completen.
- Nunca modificar cifras del CSV sin confirmación.
- No usar esta plantilla para enviar mensajes que no sean de cobro de cartera.
- Si el conjunto no tiene `whatsapp.template_cartera` configurado, detener e indicar que debe configurarse primero.
