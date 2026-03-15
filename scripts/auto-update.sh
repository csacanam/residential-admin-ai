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

# USER.md e IDENTITY.md se generan desde .env con valores reales
ENV_FILE="$REPO_DIR/.env"
if [ -f "$ENV_FILE" ]; then
  # Leer valores del .env de forma segura (soporta espacios, tildes, caracteres especiales)
  get_val() { grep "^$1=" "$ENV_FILE" | head -1 | cut -d'=' -f2- | tr -d '\r'; }

  AGENT_NAME=$(get_val AGENT_NAME)
  ADMIN_NAME=$(get_val ADMIN_NAME)
  ADMIN_TG=$(get_val ADMIN_TELEGRAM_USERNAME)
  INSTALLER_TG=$(get_val INSTALLER_TELEGRAM_USERNAME)

  # Generar USER.md
  cat > "$WORKSPACE_DIR/USER.md" << EOF
# Perfiles de usuario

## Administrador (cliente)

- **Nombre:** ${ADMIN_NAME:-[pendiente]}
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
  echo "[$TIMESTAMP] USER.md generado." >> "$LOG_FILE"

  # Generar IDENTITY.md
  cat > "$WORKSPACE_DIR/IDENTITY.md" << EOF
# Identidad del agente

## Nombre

Tu nombre es **${AGENT_NAME:-Asistente}**.

## Rol

Asistente de administración de conjuntos residenciales.

## Cómo presentarte

Si es el primer mensaje de una sesión con el administrador, saluda brevemente:

> "Hola ${ADMIN_NAME:-[pendiente]}, soy ${AGENT_NAME:-Asistente}. ¿En qué te ayudo hoy?"

No te presentes en cada mensaje — solo al inicio si es natural hacerlo.
EOF
  echo "[$TIMESTAMP] IDENTITY.md generado." >> "$LOG_FILE"
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
