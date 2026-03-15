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
- Cuenta de Google dedicada para el agente (Gmail)

### Instalación en el computador del cliente

```bash
# 1. Instalar OpenClaw
#    El instalador maneja Node.js automáticamente
curl -fsSL https://openclaw.ai/install.sh | bash

# 2. Correr el onboarding inicial de OpenClaw (solo una vez por computador)
#    El asistente interactivo configura el workspace, el modelo y los canales
openclaw onboard --install-daemon

# 3. Clonar este repositorio en una carpeta propia (NO dentro del workspace)
git clone https://github.com/csacanam/residential-admin-ai.git ~/residential-admin-ai

# 4. Enlazar los skills al directorio de skills de OpenClaw
#    OpenClaw carga skills desde ~/.openclaw/skills/ automáticamente
ln -s ~/residential-admin-ai/skills ~/.openclaw/skills

# 5. Copiar CLAUDE.md al workspace de OpenClaw
cp ~/residential-admin-ai/CLAUDE.md ~/.openclaw/workspace/CLAUDE.md

# 6. Crear el archivo de credenciales
cp ~/residential-admin-ai/.env.example ~/residential-admin-ai/.env

# 7. Llenar .env con las credenciales del cliente:
#    OPENAI_API_KEY, KAPSO_API_KEY, KAPSO_PHONE_NUMBER_ID,
#    AGENT_EMAIL, ADMIN_EMAIL

# 8. Arrancar el gateway
openclaw gateway --port 18789
```

El dashboard queda disponible en `http://127.0.0.1:18789/`

### Configurar el skill de Google Workspace (GOG)

La integración con Google Drive y Gmail se hace a través del skill GOG de OpenClaw. Configurarlo desde el dashboard o con:

```bash
openclaw channels login
```

Ver instrucciones detalladas en [docs/setup-inicial.md](docs/setup-inicial.md) → Paso 4.

### Primer uso — registrar los conjuntos del cliente

Con OpenClaw corriendo, ejecutar en el chat del agente:

```
/configurar-conjunto
```

El agente guiará el proceso para registrar cada conjunto (nombre, NIT, banco, cuenta, email, directorio de apartamentos). Repetir para cada conjunto que maneja el administrador.

### Prueba antes de entregar

1. Generar un acta de prueba con la transcripción de ejemplo en `examples/`.
2. Procesar la cartera de ejemplo en `examples/cartera-ejemplo.csv`.
3. Verificar que el acta llegue al correo del administrador.
4. Verificar que el resumen de cartera muestre preview correcto (sin confirmar el envío).

---

## Actualizaciones

Cuando publiques mejoras de skills o plantillas, en el computador del cliente:

```bash
cd ~/residential-admin-ai
git pull origin main
cp CLAUDE.md ~/.openclaw/workspace/CLAUDE.md
```

Los skills se actualizan solos porque `~/.openclaw/skills` es un enlace directo a la carpeta del repo. Solo hay que copiar CLAUDE.md si cambió.
