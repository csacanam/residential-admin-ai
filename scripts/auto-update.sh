#!/bin/bash
# =============================================================
# auto-update.sh — Actualización automática de skills
# Corre vía cron. Mantiene los skills y CLAUDE.md al día
# con la última versión del repositorio central.
# =============================================================

REPO_DIR="$HOME/residential-admin-ai"
SKILLS_SRC="$REPO_DIR/skills"
SKILLS_DST="$HOME/.openclaw/skills"
WORKSPACE_DIR="$HOME/.openclaw/workspace"
LOG_DIR="$REPO_DIR/logs"
LOG_FILE="$LOG_DIR/auto-update.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

mkdir -p "$LOG_DIR"

echo "[$TIMESTAMP] Iniciando actualización..." >> "$LOG_FILE"

# 1. Ir al repositorio
cd "$REPO_DIR" || {
  echo "[$TIMESTAMP] ERROR: No se encontró el repositorio en $REPO_DIR" >> "$LOG_FILE"
  exit 1
}

# 2. Obtener cambios del repositorio central (el remoto siempre manda)
git fetch origin 2>&1 >> "$LOG_FILE"
RESET_OUTPUT=$(git reset --hard origin/main 2>&1)
RESET_EXIT=$?

echo "[$TIMESTAMP] git reset: $RESET_OUTPUT" >> "$LOG_FILE"

if [ $RESET_EXIT -ne 0 ]; then
  echo "[$TIMESTAMP] ERROR: git reset falló. Revisa la conexión o el repositorio." >> "$LOG_FILE"
  exit 1
fi

# 3. Sincronizar archivos de instrucciones al workspace de OpenClaw
# Los archivos estáticos se copian directo
for file in AGENTS.md SOUL.md MEMORY.md; do
  cp "$REPO_DIR/openclaw/$file" "$WORKSPACE_DIR/$file" && \
    echo "[$TIMESTAMP] $file sincronizado." >> "$LOG_FILE" || \
    echo "[$TIMESTAMP] ERROR: No se pudo copiar $file" >> "$LOG_FILE"
done

# USER.md e IDENTITY.md se generan desde templates + .env
ENV_FILE="$REPO_DIR/.env"
if [ -f "$ENV_FILE" ]; then
  # Cargar variables del .env
  set -a; source "$ENV_FILE"; set +a

  # Generar USER.md
  sed \
    -e "s/{{ADMIN_NAME}}/${ADMIN_NAME:-[ADMIN_NAME]}/g" \
    -e "s/{{COMPANY_NAME}}/${COMPANY_NAME:-[COMPANY_NAME]}/g" \
    -e "s/{{ADMIN_TELEGRAM_USERNAME}}/${ADMIN_TELEGRAM_USERNAME:-[ADMIN_TELEGRAM_USERNAME]}/g" \
    -e "s/{{INSTALLER_TELEGRAM_USERNAME}}/${INSTALLER_TELEGRAM_USERNAME:-[INSTALLER_TELEGRAM_USERNAME]}/g" \
    "$REPO_DIR/openclaw/USER.md.template" > "$WORKSPACE_DIR/USER.md" && \
    echo "[$TIMESTAMP] USER.md generado." >> "$LOG_FILE" || \
    echo "[$TIMESTAMP] ERROR: No se pudo generar USER.md" >> "$LOG_FILE"

  # Generar IDENTITY.md
  sed \
    -e "s/{{AGENT_NAME}}/${AGENT_NAME:-Asistente}/g" \
    -e "s/{{ADMIN_NAME}}/${ADMIN_NAME:-[ADMIN_NAME]}/g" \
    -e "s/{{COMPANY_NAME}}/${COMPANY_NAME:-[COMPANY_NAME]}/g" \
    "$REPO_DIR/openclaw/IDENTITY.md.template" > "$WORKSPACE_DIR/IDENTITY.md" && \
    echo "[$TIMESTAMP] IDENTITY.md generado." >> "$LOG_FILE" || \
    echo "[$TIMESTAMP] ERROR: No se pudo generar IDENTITY.md" >> "$LOG_FILE"
else
  echo "[$TIMESTAMP] ADVERTENCIA: .env no encontrado — USER.md e IDENTITY.md no generados." >> "$LOG_FILE"
fi

# 4. Agregar symlinks para skills nuevos en el repo
for skill_dir in "$SKILLS_SRC"/*/; do
  skill_name=$(basename "$skill_dir")
  target="$SKILLS_DST/$skill_name"
  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    ln -s "$skill_dir" "$target" && \
      echo "[$TIMESTAMP] Skill agregado: $skill_name" >> "$LOG_FILE" || \
      echo "[$TIMESTAMP] ERROR: No se pudo enlazar $skill_name" >> "$LOG_FILE"
  fi
done

# 5. Eliminar symlinks de skills que ya no existen en el repo
for target in "$SKILLS_DST"/*/; do
  skill_name=$(basename "$target")
  # Solo tocar symlinks que apunten a nuestro repo (no borrar skills de otros)
  if [ -L "$SKILLS_DST/$skill_name" ]; then
    link_target=$(readlink "$SKILLS_DST/$skill_name")
    if [[ "$link_target" == "$SKILLS_SRC"* ]]; then
      if [ ! -d "$link_target" ]; then
        rm "$SKILLS_DST/$skill_name" && \
          echo "[$TIMESTAMP] Skill eliminado: $skill_name" >> "$LOG_FILE"
      fi
    fi
  fi
done

echo "[$TIMESTAMP] Actualización completada." >> "$LOG_FILE"
echo "---" >> "$LOG_FILE"
