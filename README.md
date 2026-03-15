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
#    El asistente interactivo configura el workspace, el modelo y los canales
#    ANTES de correr esto: tener a la mano el token del bot de Telegram (ver docs/setup-inicial.md Paso 5)
openclaw onboard --install-daemon

# 3. Clonar este repositorio en una carpeta propia (NO dentro del workspace)
git clone https://github.com/csacanam/residential-admin-ai.git ~/residential-admin-ai

# 4. Enlazar los skills al directorio correcto de OpenClaw (~/.agents/skills)
#    No se reemplaza el directorio completo — se enlaza cada skill individualmente
#    para no borrar skills existentes que OpenClaw pueda tener instalados
ln -s ~/residential-admin-ai/skills/actas-reunion ~/.agents/skills/actas-reunion
ln -s ~/residential-admin-ai/skills/cobro-cartera-whatsapp ~/.agents/skills/cobro-cartera-whatsapp
ln -s ~/residential-admin-ai/skills/configurar-conjunto ~/.agents/skills/configurar-conjunto

# 5. Copiar CLAUDE.md al workspace de OpenClaw
cp ~/residential-admin-ai/CLAUDE.md ~/.openclaw/workspace/CLAUDE.md

# 6. Crear y editar el archivo de credenciales
cp ~/residential-admin-ai/.env.example ~/residential-admin-ai/.env
nano ~/residential-admin-ai/.env
#    Llena los 3 campos vacíos: OPENAI_API_KEY, KAPSO_API_KEY, KAPSO_PHONE_NUMBER_ID
#    Para guardar: Ctrl+O → Enter → Ctrl+X

# 7. Activar la actualización automática de skills (cron diario a las 3am)
chmod +x ~/residential-admin-ai/scripts/auto-update.sh
(crontab -l 2>/dev/null; echo "0 3 * * * $HOME/residential-admin-ai/scripts/auto-update.sh") | crontab -

# 8. Arrancar el gateway
openclaw gateway --port 18789
```

El dashboard queda disponible en `http://127.0.0.1:18789/`

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
