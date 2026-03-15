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
- Cuenta de Gmail dedicada para el agente y GOG CLI autenticado

### Instalación en el computador del cliente

```bash
# 1. Instalar OpenClaw
#    El instalador maneja Node.js automáticamente
curl -fsSL https://openclaw.ai/install.sh | bash

# 2. Correr el onboarding inicial de OpenClaw (solo una vez por computador)
#    ANTES: tener a la mano el token del bot de Telegram (ver docs/setup-inicial.md Paso 5)
openclaw onboard --install-daemon

# 3. Correr el script de instalación — hace todo lo demás automáticamente
curl -fsSL https://raw.githubusercontent.com/csacanam/residential-admin-ai/main/scripts/install.sh | bash
```

El script clona el repo, enlaza los skills, copia CLAUDE.md, crea el .env y registra el cron. Te pedirá que completes el .env con las credenciales antes de continuar.

### Primer uso — registrar los conjuntos del cliente

Con OpenClaw corriendo, ejecutar en el chat del agente (Telegram):

```
/configurar-conjunto
```

El agente guiará el proceso para registrar cada conjunto. Repetir para cada conjunto que maneja el administrador.

### Prueba antes de entregar

1. Generar un acta de prueba con la transcripción de ejemplo en `examples/`.
2. Procesar la cartera de ejemplo en `examples/cartera-ejemplo.csv`.
3. Verificar que el acta llegue al correo del administrador.
4. Verificar que el resumen de cartera muestre preview correcto (sin confirmar el envío).

---

## Actualizaciones

Cada instalación tiene un cron job que corre a las 3am y ejecuta `scripts/auto-update.sh`. Este script:

1. Hace `git pull origin main` en `~/residential-admin-ai`
2. Copia `CLAUDE.md` al workspace de OpenClaw
3. Verifica que el symlink de skills siga en pie (y lo recrea si no)

**Para publicar una actualización a todos los clientes:** simplemente haz `git push` al repositorio. Antes del día siguiente todos los clientes tendrán la versión más reciente.

Los logs de cada actualización quedan en `~/residential-admin-ai/logs/auto-update.log`.

Para forzar una actualización inmediata en un cliente específico:

```bash
~/residential-admin-ai/scripts/auto-update.sh
```
