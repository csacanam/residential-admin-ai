# Arquitectura del agente — Guía para el instalador y desarrollador

Este documento explica cómo está estructurado el agente y qué reglas seguir al agregar nuevos skills o modificar su comportamiento.

---

## Cómo funciona OpenClaw

OpenClaw construye su system prompt dinámicamente en cada turno, inyectando archivos del workspace. Los archivos que lee automáticamente son:

| Archivo | Propósito | Gestionado por |
|---|---|---|
| `AGENTS.md` | Manual de operación: skills, modos, tono, reglas permanentes | Repo (sobrescrito en cada update) |
| `SOUL.md` | Personalidad, tono y valores del agente | Repo (sobrescrito en cada update) |
| `IDENTITY.md` | Nombre y presentación del agente | Scripts (generado desde .env) |
| `USER.md` | Perfil del administrador y del instalador | Scripts (generado desde .env) |
| `MEMORY.md` | Preferencias aprendidas del administrador | Agente (nunca se sobrescribe) |

`AGENTS.md` y `SOUL.md` viven en `~/residential-admin-ai/openclaw/` y se copian a `~/.openclaw/workspace/` en cada `auto-update.sh`. `MEMORY.md` se crea vacío solo en la instalación inicial y el agente lo gestiona libremente.

**CLAUDE.md no es leído por OpenClaw** — es solo referencia para el desarrollador.

---

## Qué personalizar por cliente

Cada instalación es única. Lo que cambia entre clientes va en `.env`:

| Campo | Descripción |
|---|---|
| `AGENT_NAME` | Nombre del agente (ej: Roma, Sofía) |
| `ADMIN_NAME` | Nombre del administrador |
| `ADMIN_TELEGRAM_USERNAME` | Username del administrador en Telegram |
| `INSTALLER_TELEGRAM_USERNAME` | Username del instalador en Telegram |

Los scripts generan `IDENTITY.md` y `USER.md` con estos valores baked in — no se editan directamente por cliente.

---

## Cómo agregar un skill nuevo

1. Crea la carpeta `skills/{nombre-del-skill}/` con su `SKILL.md`
2. El `SKILL.md` sigue la estructura estándar (frontmatter + pasos numerados)
3. Registra el skill en `AGENTS.md` bajo la sección "Skills disponibles"
4. Si el skill requiere nuevas **restricciones o capacidades del agente**, agrégalas en `AGENTS.md` — nunca dentro del `SKILL.md`
5. Si el skill requiere nuevas **credenciales**, agrégalas al `.env.example` con comentario explicativo
6. Haz `git push` — el `auto-update.sh` lo distribuye a todos los clientes

### Estructura mínima de un SKILL.md

```markdown
---
name: nombre-del-skill
description: Una línea describiendo qué hace el skill.
---

# Skill: Nombre del skill

## Cuándo usar este skill

Frases en lenguaje natural que el administrador usaría.

## Paso 1 — ...

## Paso 2 — ...

## Restricciones del skill

- Qué nunca hace este skill.
```

---

## Dónde va cada tipo de contenido

| Contenido | Archivo |
|---|---|
| Qué skills hay y cómo invocarlos | `AGENTS.md` |
| Modo instalador vs administrador | `AGENTS.md` |
| Reglas de tono y comunicación | `AGENTS.md` |
| Reglas que nunca se rompen | `AGENTS.md` (sección "Reglas permanentes") |
| Personalidad y valores del agente | `SOUL.md` |
| Nombre y presentación del agente | `IDENTITY.md` (generado por scripts) |
| Quién es el admin y el instalador | `USER.md` (generado por scripts) |
| Preferencias aprendidas del admin | `MEMORY.md` (gestionado por el agente) |
| Lógica específica de una tarea | `skills/{nombre}/SKILL.md` |
| Credenciales y configuración | `.env` |

---

## Flujo de actualizaciones

```
Tú haces git push
    ↓
auto-update.sh corre en cada cliente (cron 3am)
    ↓
git reset --hard origin/main  ← el remoto siempre manda
    ↓
Copia AGENTS.md, SOUL.md → ~/.openclaw/workspace/
    ↓
Genera IDENTITY.md y USER.md desde .env → ~/.openclaw/workspace/
    ↓
Sincroniza symlinks de skills → ~/.openclaw/skills/
```
