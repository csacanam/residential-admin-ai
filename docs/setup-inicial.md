# Setup inicial — Guía para el instalador

Esta guía es **para ti**, quien instala y configura el agente en el computador del cliente. El administrador no hace ninguno de estos pasos — tú los haces antes o durante la visita de instalación.

Cada cuenta que creas acá queda a nombre del administrador (usa su correo o datos) y él paga directamente los servicios.

> **Sistema operativo:** todas las instalaciones corren sobre **Ubuntu**.

---

## Paso 1 — Crear cuenta en OpenAI

OpenAI es el motor de IA que genera las actas y procesa textos.

1. Ir a [platform.openai.com](https://platform.openai.com) y crear cuenta con el correo del administrador.
2. Confirmar el correo.
3. Ir a **Settings → Billing → Add payment method** y agregar la tarjeta del administrador.
4. Ir a **Settings → Billing → Add to credit balance** y recargar **USD $20** como saldo inicial.
5. Ir a **API Keys → Create new secret key**. Darle un nombre como `residential-admin-ai`.
6. Copiar la clave (`sk-...`). **Solo se muestra una vez.** Guardarla antes de cerrar.

**Esta clave va en `.env` como `OPENAI_API_KEY`.**

---

## Paso 2 — Crear cuenta en Kapso y conectar WhatsApp

Kapso es el servicio que envía los mensajes de WhatsApp de cobro de cartera.

1. Ir a [kapso.io](https://kapso.io) y crear cuenta.
2. Conectar el número de WhatsApp Business del administrador siguiendo las instrucciones de Kapso. El número debe estar disponible durante el proceso — Kapso enviará un código de verificación.
3. Ir a **Billing** y agregar la tarjeta del administrador. Kapso cobra por mensajes enviados.
4. Ir a **API Keys** y generar una clave nueva.
5. Copiar la clave.
6. Buscar el **Phone Number ID** del número conectado — es un número de identificación numérico largo (ej: `647015955153740`). Está en la configuración del número dentro del panel de Kapso.

**Estas credenciales van en `.env` como:**
- `KAPSO_API_KEY` ← la clave de API
- `KAPSO_PHONE_NUMBER_ID` ← el ID numérico del número conectado

> **Importante:** el número conectado a Kapso no puede usarse como WhatsApp personal al mismo tiempo. Usar un número dedicado para la administración es lo recomendado.

---

## Paso 3 — Crear la plantilla de cobro en Kapso (aprobación Meta)

Los mensajes masivos de WhatsApp requieren una plantilla aprobada por Meta. Este paso puede tomar entre 1 y 24 horas. Hacerlo con anticipación antes de la visita de instalación.

### Contenido exacto de la plantilla

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

### Cómo crear la plantilla en Kapso

1. En el panel de Kapso ir a **Templates → Create Template**.
2. Configurar:
   - **Nombre:** `cobro_cartera_v1`
   - **Categoría:** `UTILITY`
   - **Idioma:** `Español (es)`
3. Pegar el contenido exacto de arriba.
4. En la sección de muestras de variables llenar con estos ejemplos (Meta los revisa para aprobar):

   | Variable | Ejemplo |
   |---|---|
   | `{{1}}` | 15 de marzo de 2026 |
   | `{{2}}` | $1.200.000 |
   | `{{3}}` | Multifamiliares La Base |
   | `{{4}}` | 805003068-4 |
   | `{{5}}` | Calle 62 # 12B - 140 |
   | `{{6}}` | AV Villas |
   | `{{7}}` | Corriente # 177-019265 |
   | `{{8}}` | 12-101 |
   | `{{9}}` | Si cancela la totalidad de su deuda recuerde que el descuento pronto pago es de $4.000 |
   | `{{10}}` | $1.200.000 |
   | `{{11}}` | administracion@conjunto.com |

5. Enviar para revisión. Kapso notificará por correo cuando esté aprobada.

Una vez aprobada, el nombre `cobro_cartera_v1` se registra en `conjunto.json` de cada conjunto bajo `whatsapp.template_cartera`.

> **No modificar el texto de la plantilla** sin volver a someterla a revisión de Meta. Un cambio puede resultar en rechazo o suspensión.

---

## Paso 4 — Configurar Google Workspace del agente (skill GOG)

El agente necesita su propio correo de Google para enviar documentos al administrador y recibir archivos. La integración se hace a través del **skill GOG de OpenClaw**, que maneja Google Drive y Gmail internamente — no se configuran credenciales manuales en `.env`.

### Crear el correo del agente

1. Crear una cuenta de Gmail nueva. Ejemplo: `agente.nombreconjunto@gmail.com`.
2. **No usar el correo personal del administrador** — debe ser una cuenta separada y dedicada al agente.

### Conectar Google en OpenClaw

1. Con OpenClaw corriendo, ejecutar:
   ```bash
   openclaw channels login
   ```
2. Seleccionar **Google Workspace / GOG** en el asistente de canales.
3. Iniciar sesión con la cuenta del agente recién creada y autorizar los permisos de Drive y Gmail.
4. La autorización se guarda en OpenClaw y no es necesario repetirla.

### Registrar los correos en `.env`

Aunque la autenticación la maneja GOG, el agente necesita saber a quién enviarle los documentos:

- `AGENT_EMAIL` ← el Gmail del agente recién creado
- `ADMIN_EMAIL` ← el correo personal del administrador (donde recibirá documentos)

---

## Resumen de tarjetas y pagos

| Servicio | Quién paga | Tipo de cobro |
|---|---|---|
| OpenAI | Administrador (cliente) | Créditos por consumo — recarga manual o automática |
| Kapso | Administrador (cliente) | Por mensajes enviados según plan |
| Google | No requiere tarjeta en uso normal | Gratis dentro de límites estándar |

---

## Checklist antes de entregar la instalación

- [ ] Cuenta OpenAI creada, tarjeta del cliente agregada, $20 de créditos cargados
- [ ] API Key de OpenAI en `.env`
- [ ] Cuenta Kapso creada, número WhatsApp conectado, tarjeta del cliente agregada
- [ ] `KAPSO_API_KEY` y `KAPSO_PHONE_NUMBER_ID` en `.env`
- [ ] Plantilla `cobro_cartera_v1` creada en Kapso y aprobada por Meta
- [ ] Gmail del agente creado (no el personal del administrador)
- [ ] Google Workspace conectado en OpenClaw via skill GOG (`openclaw channels login`)
- [ ] `AGENT_EMAIL` y `ADMIN_EMAIL` en `.env`
- [ ] `/configurar-conjunto` ejecutado para cada conjunto del administrador
- [ ] Prueba de acta con transcripción de ejemplo completada
- [ ] Prueba de cartera con CSV de ejemplo completada (sin envío real)
- [ ] Documentos de prueba llegaron al correo del administrador
