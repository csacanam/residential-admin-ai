# Arquitectura del agente — Guía para el instalador y desarrollador

Este documento explica cómo está estructurado el agente y qué reglas seguir al agregar nuevos skills o modificar su comportamiento.

---

## Cómo funciona OpenClaw

OpenClaw construye su system prompt dinámicamente en cada turno, inyectando archivos del workspace. Los archivos que lee automáticamente son:

| Archivo | Propósito |
|---|---|
| `AGENTS.md` | Manual de operación: skills, modos, reglas de tono, workspace |
| `SOUL.md` | Personalidad, tono y valores del agente |
| `IDENTITY.md` | Nombre y presentación del agente |
| `MEMORY.md` | Reglas de hierro que nunca se rompen |
| `USER.md` | Perfil del administrador y del instalador |

Estos archivos viven en `~/residential-admin-ai/openclaw/` y se copian a `~/.openclaw/workspace/` durante la instalación y en cada `auto-update.sh`.

**CLAUDE.md no es leído por OpenClaw** — es solo referencia para el desarrollador.

---

## Qué personalizar por cliente

Cada instalación es única. Lo que cambia entre clientes va en `.env`:

| Campo | Descripción |
|---|---|
| `AGENT_NAME` | Nombre del agente (ej: Roma, Sofía) |
| `ADMIN_NAME` | Nombre del administrador |
| `COMPANY_NAME` | Nombre de la empresa administradora |
| `ADMIN_TELEGRAM_USERNAME` | Username del administrador en Telegram |
| `INSTALLER_TELEGRAM_USERNAME` | Username del instalador en Telegram |

Los archivos `SOUL.md` e `IDENTITY.md` leen estos campos del `.env` — no se editan directamente por cliente.

---

## Cómo agregar un skill nuevo

1. Crea la carpeta `skills/{nombre-del-skill}/` con su `SKILL.md`
2. El `SKILL.md` sigue la estructura estándar (frontmatter + pasos numerados)
3. Registra el skill en `AGENTS.md` bajo la sección "Skills disponibles"
4. Si el skill requiere nuevas **restricciones o capacidades del agente**, agrégalas en `AGENTS.md` o `MEMORY.md` — nunca dentro del `SKILL.md`
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
| Personalidad y valores del agente | `SOUL.md` |
| Nombre y presentación | `IDENTITY.md` |
| Reglas que nunca se rompen | `MEMORY.md` |
| Quién es el admin y el instalador | `USER.md` |
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
Copia AGENTS.md, SOUL.md, IDENTITY.md, MEMORY.md, USER.md → ~/.openclaw/workspace/
    ↓
Sincroniza symlinks de skills → ~/.openclaw/skills/
```
