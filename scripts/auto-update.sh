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

# 2. Obtener cambios del repositorio central
PULL_OUTPUT=$(git pull origin main 2>&1)
PULL_EXIT=$?

echo "[$TIMESTAMP] git pull: $PULL_OUTPUT" >> "$LOG_FILE"

if [ $PULL_EXIT -ne 0 ]; then
  echo "[$TIMESTAMP] ERROR: git pull falló. Revisa la conexión o el repositorio." >> "$LOG_FILE"
  exit 1
fi

# 3. Sincronizar CLAUDE.md al workspace de OpenClaw
cp "$REPO_DIR/CLAUDE.md" "$WORKSPACE_DIR/CLAUDE.md" && \
  echo "[$TIMESTAMP] CLAUDE.md sincronizado." >> "$LOG_FILE" || \
  echo "[$TIMESTAMP] ERROR: No se pudo copiar CLAUDE.md a $WORKSPACE_DIR" >> "$LOG_FILE"

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
