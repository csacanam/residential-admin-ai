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
# 3. Copiar CLAUDE.md al workspace de OpenClaw
# -------------------------------------------------------------
echo "[3/5] Copiando CLAUDE.md al workspace..."

cp "$REPO_DIR/CLAUDE.md" "$WORKSPACE_DIR/CLAUDE.md" && echo "  OK" || {
  echo "  ERROR: No se pudo copiar CLAUDE.md a $WORKSPACE_DIR"
  echo "         Verifica que el onboarding de OpenClaw se haya completado."
  exit 1
}

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
  echo "    OPENAI_API_KEY"
  echo "    KAPSO_API_KEY"
  echo "    KAPSO_PHONE_NUMBER_ID"
  echo "    AGENT_EMAIL"
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
  echo "      b. Dile al agente: \"Instala el skill gogcli de ClawHub\""
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
