# Setup inicial — Guía para el instalador

Esta guía es **para ti**, quien instala y configura el agente en el computador del cliente. El administrador no hace ninguno de estos pasos — tú los haces antes o durante la visita de instalación.

Cada cuenta que creas acá queda a nombre del administrador (usa su correo o datos) y él paga directamente los servicios.

> **Sistema operativo:** todas las instalaciones corren sobre **Ubuntu**. Git viene instalado por defecto.

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

> **Tip:** Para obtener el username de Telegram del administrador o del instalador, escríbele al agente desde esa cuenta: *"¿Cuál es mi username de Telegram?"* El agente lo reportará y lo copias al `.env` sin el @.

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

## Paso 4 — Instalar y configurar el skill GOG (Google Workspace)

GOG es un skill de OpenClaw que permite al agente leer y enviar correos y trabajar con Google Drive. Requiere crear credenciales OAuth en Google Cloud Console.

### Crear el correo del agente

1. Crear una cuenta de Gmail nueva. Ejemplo: `agente.nombreconjunto@gmail.com`.
2. **No usar el correo personal del administrador** — debe ser una cuenta separada y dedicada al agente.

### Crear credenciales OAuth en Google Cloud Console

1. Ir a [console.cloud.google.com](https://console.cloud.google.com) con la cuenta del agente.
2. Crear un proyecto nuevo. Nombre sugerido: `residential-admin-ai`.
3. Ir a **APIs y servicios → Habilitar APIs** y activar: Gmail API y Google Drive API.
4. Ir a **APIs y servicios → Credenciales → Crear credenciales → ID de cliente OAuth 2.0**.
5. Tipo de aplicación: **App de escritorio**. Nombre: `gog-agent`.
6. Descargar el archivo JSON de credenciales (`client_secret_*.json`). **Solo se descarga una vez.**

### Instalar el skill GOG

Con OpenClaw corriendo, escribirle al agente en Telegram:

> "Instala el skill GOG Google Workspace"

OpenClaw descargará e instalará el skill y el binario `gog` automáticamente.

### Autenticar el agente

Una vez instalado el skill, en la terminal del computador:

```bash
gog auth credentials ~/Downloads/client_secret_*.json
gog auth add agente.nombreconjunto@gmail.com
```

El segundo comando abre el navegador para autorizar el acceso. Iniciar sesión con el Gmail del agente y aceptar los permisos.

**El correo del agente va en `.env` como `AGENT_EMAIL`.**

> Verificar que funciona pidiéndole al agente en Telegram: "¿Tienes correos nuevos?"

---

## Paso 5 — Crear el bot de Telegram (antes del onboarding de OpenClaw)

El administrador interactúa con el agente a través de Telegram. El bot se crea con BotFather y sus datos se ingresan durante el proceso de instalación de OpenClaw (`openclaw onboard`). **Hacer este paso antes de correr el onboarding.**

### Crear el bot en BotFather

1. En Telegram, buscar `@BotFather` y abrir el chat.
2. Enviar `/newbot`.
3. Elegir un nombre visible (ej: `Agente Admin Bosques`).
4. Elegir un username único terminado en `bot` (ej: `agente_bosques_bot`).
5. BotFather entregará un **token de acceso** con formato `123456789:AAF...`.

**Guardar este token.** OpenClaw lo pedirá durante el onboarding.

> El administrador debe hablar con el agente únicamente a través de este bot. Compartirle el username del bot una vez que la instalación esté completa.

---

## Resumen de tarjetas y pagos

| Servicio | Quién paga | Tipo de cobro |
|---|---|---|
| OpenAI | Administrador (cliente) | Créditos por consumo — recarga manual o automática |
| Kapso | Administrador (cliente) | Por mensajes enviados según plan |
| Google | Gratis (dentro de límites normales) | Sin costo para uso básico de Gmail y Drive |

---

## Checklist antes de entregar la instalación

- [ ] Cuenta OpenAI creada, tarjeta del cliente agregada, $20 de créditos cargados
- [ ] API Key de OpenAI en `.env`
- [ ] Cuenta Kapso creada, número WhatsApp conectado, tarjeta del cliente agregada
- [ ] `KAPSO_API_KEY` y `KAPSO_PHONE_NUMBER_ID` en `.env`
- [ ] Plantilla `cobro_cartera_v1` creada en Kapso y aprobada por Meta
- [ ] Bot de Telegram creado en BotFather, token copiado
- [ ] OpenClaw instalado y onboarding completado (token de Telegram ingresado)
- [ ] `ADMIN_TELEGRAM_USERNAME` e `INSTALLER_TELEGRAM_USERNAME` en `.env`
- [ ] Gmail del agente creado (no el correo personal del administrador)
- [ ] GOG CLI instalado y autenticado con el Gmail del agente
- [ ] `AGENT_EMAIL` en `.env`
- [ ] `/configurar-conjunto` ejecutado para cada conjunto del administrador
- [ ] Prueba de acta con transcripción de ejemplo completada
- [ ] Prueba de cartera con CSV de ejemplo completada (sin envío real)
