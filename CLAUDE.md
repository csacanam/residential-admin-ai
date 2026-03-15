# CLAUDE.md — Referencia de desarrollo

> **Este archivo es solo para el desarrollador/instalador.**
> OpenClaw NO lo lee automáticamente. Las instrucciones reales del agente están en `openclaw/AGENTS.md`, `openclaw/SOUL.md`, `openclaw/MEMORY.md`, `openclaw/IDENTITY.md` y `openclaw/USER.md`.
> Ver `docs/arquitectura-agente.md` para entender la estructura completa.

---

## Archivos de instrucciones del agente

| Archivo | Propósito |
|---|---|
| `openclaw/AGENTS.md` | Manual de operación: skills, modos, workspace, tono |
| `openclaw/SOUL.md` | Personalidad y valores |
| `openclaw/IDENTITY.md` | Nombre y presentación |
| `openclaw/MEMORY.md` | Reglas de hierro |
| `openclaw/USER.md` | Perfiles de usuario |

## Skills disponibles

| Skill | Carpeta |
|---|---|
| Configurar conjunto | `skills/configurar-conjunto/` |
| Actas de reunión | `skills/actas-reunion/` |
| Cobro de cartera por WhatsApp | `skills/cobro-cartera-whatsapp/` |

## Para agregar un skill nuevo

Ver `docs/arquitectura-agente.md`.

## Setup en una máquina nueva

Después de clonar el repo, instala el hook de pre-push:

```bash
cp hooks/pre-push .git/hooks/pre-push
```

Esto bloquea pushes que pierdan el bit de ejecución en los scripts u otros problemas básicos.
