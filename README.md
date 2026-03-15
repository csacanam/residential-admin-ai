# Residential Admin AI

Repositorio de skills, plantillas y reglas para el agente de IA de administradores de conjuntos residenciales en Colombia.

---

## Quién lee este repositorio

Este repositorio tiene **dos tipos de contenido** para dos lectores distintos:

| Lector | Qué lee | Para qué |
|---|---|---|
| **Tú (el instalador)** | `README.md`, `docs/` | Saber qué hacer en cada instalación |
| **OpenClaw (el agente)** | `CLAUDE.md`, `skills/`, `openclaw/`, `templates/` | Saber cómo comportarse y ejecutar tareas |

El administrador (cliente) **no lee ni configura nada** — solo interactúa con el agente por chat una vez que tú instalaste todo.

---

## Qué contiene este repositorio

```
residential-admin-ai/
├── CLAUDE.md                         ← OpenClaw lo lee al arrancar (reglas del agente)
├── .env.example                      ← plantilla de credenciales (tú la llenas)
├── openclaw/
│   ├── profile.system.md             ← OpenClaw: identidad y comportamiento
│   └── guardrails.md                 ← OpenClaw: reglas que no puede romper
├── skills/
│   ├── configurar-conjunto/SKILL.md  ← OpenClaw: primer paso de toda instalación
│   ├── actas-reunion/SKILL.md        ← OpenClaw: skill de actas
│   └── cobro-cartera-whatsapp/SKILL.md ← OpenClaw: skill de cobro
├── templates/
│   ├── actas/                        ← OpenClaw: plantillas de actas
│   └── cartera/                      ← OpenClaw: plantillas de mensajes
├── examples/                         ← referencia para onboarding
└── docs/
    └── setup-inicial.md              ← TÚ: guía de instalación paso a paso
```

---

## Para el instalador — cómo instalar en el computador de un cliente

### Requisitos previos (los gestionas tú antes de ir donde el cliente)

Antes de ir al computador del cliente necesitas tener creadas y funcionando estas cuentas **a nombre del cliente**. Ver el detalle paso a paso en [docs/setup-inicial.md](docs/setup-inicial.md).

- Cuenta de OpenAI con API key y créditos cargados
- Cuenta de Kapso con API key, número WhatsApp conectado y plantilla aprobada
- Cuenta de Google dedicada para el agente (Gmail + Drive)

### Instalación en el computador del cliente

```bash
# 1. Instalar Node.js 24 (requerido por OpenClaw)
#    https://nodejs.org

# 2. Instalar OpenClaw
curl -fsSL https://openclaw.ai/install.sh | bash
# alternativa: npm install -g openclaw@latest

# 3. Clonar este repositorio
git clone git@github.com:csacanam/residential-admin-ai.git ~/residential-admin-ai
cd ~/residential-admin-ai

# 4. Crear el archivo de credenciales
cp .env.example .env

# 5. Llenar .env con las credenciales del cliente:
#    OPENAI_API_KEY, KAPSO_API_KEY, KAPSO_PHONE_NUMBER_ID,
#    AGENT_EMAIL, ADMIN_EMAIL, GOOGLE_CREDENTIALS_JSON, GMAIL_APP_PASSWORD

# 6. Copiar el JSON de OAuth de Google al lugar correcto
mkdir credentials
# copiar google-oauth-credentials.json a credentials/

# 7. Hacer el onboarding inicial de OpenClaw (solo una vez por computador)
openclaw onboard --install-daemon

# 8. Conectar los canales del agente
openclaw channels login

# 9. Arrancar el gateway de OpenClaw
openclaw gateway --port 18789
# El dashboard queda disponible en http://127.0.0.1:18789/
```

> **Nota:** la integración exacta entre OpenClaw y la carpeta del proyecto (dónde apunta para leer `CLAUDE.md` y `skills/`) debe verificarse en [docs.openclaw.ai](https://docs.openclaw.ai) durante la instalación. El repositorio está estructurado siguiendo las convenciones estándar de Claude Code en que OpenClaw está basado.

### Primer uso — registrar los conjuntos del cliente

Con OpenClaw abierto, ejecutar:

```
/configurar-conjunto
```

El agente guiará el proceso para registrar cada conjunto (nombre, NIT, banco, cuenta, email, directorio de apartamentos). Repetir para cada conjunto que maneja el administrador.

### Prueba antes de entregar

1. Generar un acta de prueba con la transcripción de ejemplo en `examples/`.
2. Procesar la cartera de ejemplo en `examples/cartera-ejemplo.csv`.
3. Verificar que el acta llegue al correo del administrador.
4. Verificar que el resumen de cartera muestre preview correcto (sin hacer envío real).

---

## Actualizaciones

Cuando publiques mejoras de skills o plantillas, el cliente solo necesita:

```bash
cd ~/residential-admin-ai
git pull origin main
```

Los datos del cliente en `workspace/` son locales y nunca se ven afectados.
