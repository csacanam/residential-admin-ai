#!/bin/bash
# =============================================================
# install.sh — Instalación de Residential Admin AI
# Correr una sola vez en el computador del cliente.
# Prerequisitos: OpenClaw instalado y onboarding completado.
# =============================================================

REPO_DIR="$HOME/residential-admin-ai"
SKILLS_DST="$HOME/.openclaw/skills"
WORKSPACE_DIR="$HOME/.openclaw/workspace"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo ""
echo "====================================================="
echo " Residential Admin AI — Instalación"
echo "====================================================="
echo ""

# -------------------------------------------------------------
# 1. Clonar el repositorio
# -------------------------------------------------------------
echo "[1/5] Clonando repositorio..."

if [ -d "$REPO_DIR" ]; then
  echo "  Ya existe $REPO_DIR — actualizando en vez de clonar."
  cd "$REPO_DIR"
  git fetch origin
  git reset --hard origin/main
else
  git clone https://github.com/csacanam/residential-admin-ai.git "$REPO_DIR"
  cd "$REPO_DIR"
fi

echo "  OK"
echo ""

# -------------------------------------------------------------
# 2. Enlazar skills a OpenClaw
# -------------------------------------------------------------
echo "[2/5] Enlazando skills..."

for skill_dir in "$REPO_DIR/skills"/*/; do
  skill_name=$(basename "$skill_dir")
  target="$SKILLS_DST/$skill_name"
  if [ -L "$target" ]; then
    echo "  $skill_name — ya enlazado, omitiendo."
  elif [ -d "$target" ]; then
    echo "  ADVERTENCIA: $skill_name ya existe como carpeta en $SKILLS_DST (no se toca)."
  else
    ln -s "$skill_dir" "$target" && echo "  $skill_name — enlazado."
  fi
done

echo ""

# -------------------------------------------------------------
# 3. Copiar archivos de instrucciones al workspace de OpenClaw
# -------------------------------------------------------------
echo "[3/5] Copiando instrucciones al workspace de OpenClaw..."

OK=true

# Archivos estáticos
for file in AGENTS.md SOUL.md MEMORY.md; do
  cp "$REPO_DIR/openclaw/$file" "$WORKSPACE_DIR/$file" && \
    echo "  $file — OK" || { echo "  ERROR: $file"; OK=false; }
done

# USER.md e IDENTITY.md se generan desde templates + .env (si ya existe)
ENV_FILE="$REPO_DIR/.env"
if [ -f "$ENV_FILE" ]; then
  get_val() { grep "^$1=" "$ENV_FILE" | head -1 | cut -d'=' -f2- | tr -d '\r'; }

  AGENT_NAME=$(get_val AGENT_NAME)
  ADMIN_NAME=$(get_val ADMIN_NAME)
  COMPANY_NAME=$(get_val COMPANY_NAME)
  ADMIN_TG=$(get_val ADMIN_TELEGRAM_USERNAME)
  INSTALLER_TG=$(get_val INSTALLER_TELEGRAM_USERNAME)

  cat > "$WORKSPACE_DIR/USER.md" << EOF
# Perfiles de usuario

## Administrador (cliente)

- **Nombre:** ${ADMIN_NAME:-[pendiente]}
- **Empresa:** ${COMPANY_NAME:-[pendiente]}
- **Telegram username:** @${ADMIN_TG:-[pendiente]}
- **Perfil:** no es técnico. Administra conjuntos residenciales en Colombia. Usa el agente para tareas operativas del día a día.

## Instalador

- **Telegram username:** @${INSTALLER_TG:-[pendiente]}
- **Perfil:** técnico. Configura y mantiene el agente. Tiene acceso completo en modo instalador.

## Regla de identificación

Cuando llegue un mensaje, compara el username de Telegram del remitente con los registrados arriba:

- Si es **@${INSTALLER_TG:-[pendiente]}** → modo instalador
- Si es **@${ADMIN_TG:-[pendiente]}** → modo administrador
- Cualquier otro username → silencio total, no respondas nada
EOF
  echo "  USER.md — generado"

  cat > "$WORKSPACE_DIR/IDENTITY.md" << EOF
# Identidad del agente

## Nombre

Tu nombre es **${AGENT_NAME:-Asistente}**.

## Rol

Asistente de administración de conjuntos residenciales para **${COMPANY_NAME:-[pendiente]}**.

## Cómo presentarte

Si es el primer mensaje de una sesión con el administrador, saluda brevemente:

> "Hola ${ADMIN_NAME:-[pendiente]}, soy ${AGENT_NAME:-Asistente}. ¿En qué te ayudo hoy?"

No te presentes en cada mensaje — solo al inicio si es natural hacerlo.
EOF
  echo "  IDENTITY.md — generado"
else
  echo "  ADVERTENCIA: .env no encontrado — USER.md e IDENTITY.md se generarán después."
  echo "  Corre auto-update.sh una vez que el .env esté completo."
fi

if [ "$OK" = false ]; then
  echo "  Verifica que el onboarding de OpenClaw se haya completado."
  exit 1
fi

echo ""

# -------------------------------------------------------------
# 4. Crear archivo .env
# -------------------------------------------------------------
echo "[4/5] Configurando credenciales (.env)..."

if [ -f "$REPO_DIR/.env" ]; then
  echo "  Ya existe .env — no se sobreescribe."
else
  cp "$REPO_DIR/.env.example" "$REPO_DIR/.env"
  echo "  Archivo .env creado. Completa los campos vacíos:"
  echo ""
  echo "  nano $REPO_DIR/.env"
  echo ""
  echo "  Campos a completar:"
  echo "    AGENT_NAME              ← nombre del agente (ej: Roma, Sofía)"
  echo "    OPENAI_API_KEY"
  echo "    KAPSO_API_KEY"
  echo "    KAPSO_PHONE_NUMBER_ID"
  echo "    AGENT_EMAIL"
  echo "    ADMIN_TELEGRAM_USERNAME"
  echo "    INSTALLER_TELEGRAM_USERNAME"
  echo "    ADMIN_NAME"
  echo "    COMPANY_NAME"
  echo ""
  read -p "  Presiona Enter cuando hayas guardado el .env para continuar..."
fi

echo ""

# -------------------------------------------------------------
# 5. Registrar cron de actualización automática (3am diario)
# -------------------------------------------------------------
echo "[5/5] Registrando actualización automática..."

CRON_CMD="0 3 * * * $REPO_DIR/scripts/auto-update.sh"

if crontab -l 2>/dev/null | grep -qF "auto-update.sh"; then
  echo "  Cron ya registrado — omitiendo."
else
  (crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -
  echo "  OK — correrá diariamente a las 3am."
fi

echo ""

# -------------------------------------------------------------
# Listo
# -------------------------------------------------------------
echo "====================================================="
echo " Instalación completada."
echo "====================================================="
echo ""
echo " Próximos pasos:"
echo ""
echo "   1. Verifica que el .env esté completo:"
echo "      nano $REPO_DIR/.env"
echo ""

# Verificar si GOG está instalado (skill + binario)
GOG_SKILL=$(find "$HOME" -path "*/skills/gogcli/SKILL.md" 2>/dev/null | head -1)
if [ -n "$GOG_SKILL" ] || command -v gog &>/dev/null; then
  echo "   2. Skill gogcli (Google Workspace) — ya instalado."
else
  echo "   2. Skill gogcli no detectado. Pasos:"
  echo "      a. Crea credenciales OAuth en console.cloud.google.com"
  echo "      b. Dile al agente: \"Instala el skill GOG Google Workspace\""
  echo "      c. Autentica con: gog auth credentials client_secret_*.json"
  echo "      Ver docs/setup-inicial.md — Paso 4"
fi

echo ""
echo "   3. Abre Telegram, busca el bot del agente y escríbele."
echo "      El agente te guiará para configurar los conjuntos."
echo ""
echo " Para actualizar manualmente en cualquier momento:"
echo "   $REPO_DIR/scripts/auto-update.sh"
echo ""
