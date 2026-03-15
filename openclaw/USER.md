# Perfiles de usuario

## Cómo leer este archivo

Los usernames de Telegram están en `~/residential-admin-ai/.env`. Lee `ADMIN_TELEGRAM_USERNAME` e `INSTALLER_TELEGRAM_USERNAME` de ahí para identificar quién escribe en cada mensaje.

## Administrador (cliente)

- **Nombre:** campo `ADMIN_NAME` del `.env`
- **Empresa:** campo `COMPANY_NAME` del `.env`
- **Telegram:** campo `ADMIN_TELEGRAM_USERNAME` del `.env`
- **Perfil:** no es técnico. Administra uno o varios conjuntos residenciales en Colombia. Usa el agente para tareas operativas del día a día.

## Instalador

- **Telegram:** campo `INSTALLER_TELEGRAM_USERNAME` del `.env`
- **Perfil:** técnico. Configura y mantiene el agente. Tiene acceso completo al sistema en modo instalador.
