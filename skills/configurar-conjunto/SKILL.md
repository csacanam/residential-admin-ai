---
name: configurar-conjunto
description: Consulta, crea o actualiza la configuración de los conjuntos residenciales. Permite ver todos los conjuntos, revisar el detalle de uno, y modificar datos de pago, contacto y directorio de apartamentos con WhatsApp.
---

# Skill: Configurar conjunto

## Cuándo usar este skill

- Primera vez que se instala el agente: para registrar todos los conjuntos del administrador.
- Cuando el usuario quiere ver qué conjuntos tiene configurados y su información.
- Cuando cambia un dato del conjunto (banco, cuenta, email, etc.).
- Cuando se agrega o actualiza el directorio de apartamentos con números de WhatsApp.
- El usuario dice algo como: "agrega un conjunto", "muéstrame los conjuntos", "cuáles conjuntos tengo", "actualiza los datos de Bosques", "cambia el banco de La Base", "registra los apartamentos".

---

## Módulo 0 — Ver conjuntos configurados

Este módulo se activa cuando el usuario quiere consultar la información, no modificarla.

### Caso: listar todos los conjuntos

Cuando el usuario dice: "¿qué conjuntos tengo?", "lista los conjuntos", "cuéntame cuáles conjuntos están configurados".

Lee todas las carpetas en `./workspace/conjuntos/` y muestra un resumen así:

```
Conjuntos configurados: 3

1. Bosques del Norte (bosques-del-norte)
   Aliases: bosques, bdn
   Ciudad: Cali
   Plantilla WhatsApp: cobro_cartera_v1 ✓
   Datos de pago: completos ✓
   Directorio de apartamentos: 48 registros

2. Multifamiliares La Base (multifamiliares-la-base)
   Aliases: la base, mlb
   Ciudad: Bogotá
   Plantilla WhatsApp: cobro_cartera_v1 ✓
   Datos de pago: incompletos ⚠ (falta: email)
   Directorio de apartamentos: no configurado ⚠

3. Altos de Santa Rita (altos-de-santa-rita)
   Aliases: santa rita
   Ciudad: Medellín
   Plantilla WhatsApp: no configurada ⚠
   Datos de pago: completos ✓
   Directorio de apartamentos: 32 registros
```

Usa `✓` cuando el campo está completo y `⚠` cuando falta algo crítico. Al final, si hay conjuntos con datos incompletos, ofrece: *"¿Quieres completar la información de alguno?"*

### Caso: ver detalle de un conjunto específico

Cuando el usuario dice: "muéstrame los datos de Bosques", "qué información tiene La Base", "dime todo de Santa Rita".

Lee el `conjunto.json` del conjunto indicado y muéstralo en formato legible:

```
Conjunto: Bosques del Norte
Slug: bosques-del-norte
Aliases: bosques, bdn
Ciudad: Cali
Dirección: Calle 62 # 12B - 140, Cali
Tono: formal_amable

Contacto:
  Administradora: Sandra López
  Teléfono: 3001234567
  Email: administracion@bosquesdelnorte.com

Datos de pago:
  NIT: 805003068-4
  Banco: AV Villas
  Cuenta: Corriente # 177-019265
  Nota pronto pago: "Si cancela la totalidad de su deuda..."

WhatsApp:
  Plantilla: cobro_cartera_v1
  Idioma: es

Directorio de apartamentos: 48 registros
  → Ver en: workspace/conjuntos/bosques-del-norte/residentes/directorio.csv

Notas: Conjunto de 4 bloques, 120 unidades.
```

Al final, pregunta: *"¿Quieres modificar algún dato?"*

---

## Por qué este skill es crítico

Todos los demás skills dependen de que la información del conjunto esté completa y correcta. Si el NIT, el banco, la cuenta o el email están mal, los mensajes de cobro saldrán con información incorrecta. Ejecuta este skill **antes de usar cualquier otro**.

---

## Módulo A — Crear o actualizar datos del conjunto

### Paso A1 — Verificar si el conjunto ya existe

Revisa si ya existe una carpeta en:
```
./workspace/conjuntos/
```

Lista los conjuntos disponibles. Si el usuario no especificó cuál, pregunta si quiere crear uno nuevo o actualizar uno existente.

### Paso A2 — Recopilar datos del conjunto

Solicita o confirma los siguientes datos. Si el conjunto ya existe, muestra los valores actuales y pregunta cuáles quiere actualizar.

**Información general:**
- Nombre completo del conjunto (ej: "Bosques del Norte")
- Ciudad
- Dirección completa
- Slug/identificador (se genera automáticamente a partir del nombre si no se especifica)
- Aliases (nombres cortos o abreviaturas que usará el administrador)

**Datos de pago (para mensajes de cobro):**
- NIT del conjunto
- Banco
- Tipo de cuenta (Corriente / Ahorros)
- Número de cuenta
- Nota de pronto pago (opcional — ej: "Si cancela la totalidad de su deuda recuerde que el descuento pronto pago es de $4.000")

**Contacto:**
- Nombre de la administradora
- Teléfono de administración
- Correo electrónico (para envío de comprobantes)

**Configuración de WhatsApp:**
- Nombre de la plantilla aprobada en Meta (ej: `cobro_cartera_v1`)
- Idioma de la plantilla (por defecto: `es`)

**Tono preferido para mensajes:**
- `formal` — muy formal y protocolario
- `formal_amable` — formal pero cálido (recomendado)
- `amable` — cercano y directo

### Paso A3 — Crear la carpeta del conjunto

Si el conjunto es nuevo, crea la siguiente estructura:

```
./workspace/conjuntos/{slug}/
├── conjunto.json
├── cartera/
│   ├── input/
│   ├── processed/
│   └── sent/
├── residentes/
│   ├── propietarios.csv
│   └── arrendatarios.csv
├── reuniones/
│   ├── audios/
│   ├── transcripciones/
│   └── actas/
└── logs/
```

### Paso A4 — Guardar `conjunto.json`

Guarda el archivo en `./workspace/conjuntos/{slug}/conjunto.json` con esta estructura:

```json
{
  "name": "Bosques del Norte",
  "slug": "bosques-del-norte",
  "aliases": ["bosques", "bdn"],
  "city": "Cali",
  "address": "Calle 62 # 12B - 140, Cali",
  "categoria": "Residencial",
  "tono": "formal_amable",
  "currency": "COP",
  "contacto": {
    "administradora": "Sandra López",
    "telefono_admin": "3001234567",
    "email": "administracion@bosquesdelnorte.com",
    "porteria": ""
  },
  "pago": {
    "nit": "805003068-4",
    "banco": "AV Villas",
    "tipo_cuenta": "Corriente",
    "numero_cuenta": "177-019265",
    "nota_pronto_pago": "Si cancela la totalidad de su deuda recuerde que el descuento pronto pago es de $4.000"
  },
  "whatsapp": {
    "template_cartera": "cobro_cartera_v1",
    "template_language": "es"
  },
  "policies": {
    "allowMassWhatsapp": true,
    "requirePreviewBeforeSend": true
  },
  "notes": ""
}
```

Muestra el JSON final al usuario antes de guardar y pide confirmación.

### Paso A5 — Confirmar

```
Conjunto configurado correctamente.
- Nombre: Bosques del Norte
- Slug: bosques-del-norte
- Datos de pago: completos
- WhatsApp template: cobro_cartera_v1
- Carpeta creada en: workspace/conjuntos/bosques-del-norte/

Puedes continuar agregando el directorio de apartamentos con /configurar-conjunto o comenzar a usar los skills.
```

---

## Módulo B — Directorio de apartamentos con WhatsApp

El directorio es el archivo que permite enviar mensajes a los residentes. Debe mantenerse actualizado.

### Paso B1 — Localizar o crear el directorio

El archivo de contactos vive en:
```
./workspace/conjuntos/{slug}/residentes/directorio.csv
```

Si no existe, créalo con estas columnas:

```csv
apartamento,nombre,telefono,tipo,activo
101,Carlos Pérez Gómez,3001234567,propietario,sí
102,María Rodríguez,3109876543,arrendatario,sí
```

### Paso B2 — Columnas del directorio

| Columna | Descripción | Obligatoria |
|---|---|---|
| `apartamento` | Número o código del apto (ej: `12-101`, `301`, `T2-205`) | Sí |
| `nombre` | Nombre completo del residente | Sí |
| `telefono` | Número de celular con WhatsApp | Sí |
| `tipo` | `propietario` o `arrendatario` | No |
| `activo` | `sí` o `no` — para excluir temporalmente del envío | No (default: sí) |

### Paso B3 — Actualizar el directorio

El administrador puede:

1. **Pegar una lista**: el usuario pega nombres y teléfonos en texto libre y el agente los convierte al formato CSV.
2. **Subir un archivo**: el administrador deja el archivo actualizado en `residentes/` y el agente lo valida y normaliza.
3. **Actualizar un apartamento**: el usuario dice "el apto 205 cambió de número, ahora es 3154567890" y el agente actualiza esa fila.

### Paso B4 — Validar y normalizar teléfonos

Aplica las mismas reglas que en el skill de cartera:
- 10 dígitos comenzando por `3` → agregar `57`
- Ya tiene `57` → dejar como está
- Cualquier otro formato → marcar como `PENDIENTE` y reportar

### Paso B5 — Guardar y reportar

Guarda el directorio actualizado y muestra un resumen:

```
Directorio actualizado.
- Conjunto: Bosques del Norte
- Total de apartamentos registrados: 48
- Teléfonos válidos: 46
- Teléfonos pendientes de verificar: 2 (apto 108, apto 317)
```

---

## Módulo C — Eliminar un conjunto

Se activa cuando el usuario dice: "elimina el conjunto X", "borra La Base", "quita ese conjunto".

### Paso C1 — Confirmar identidad del conjunto

Muestra el nombre completo y el slug del conjunto encontrado y pregunta:

> "¿Confirmas que quieres eliminar **[Nombre del Conjunto]**? Esta acción borrará todos sus datos: configuración, cartera, actas y directorio. No se puede deshacer."

No proceder sin una confirmación explícita ("sí", "confirmo", "elimínalo").

### Paso C2 — Eliminar

Elimina la carpeta completa `./workspace/conjuntos/{slug}/` y todo su contenido.

### Paso C3 — Confirmar

> "Listo. El conjunto **[Nombre]** fue eliminado."

---

## Restricciones del skill

- No inventar datos del conjunto. Si el usuario no sabe un dato, dejarlo vacío con una nota clara.
- No modificar `conjunto.json` sin mostrar el resultado final y pedir confirmación.
- Si el conjunto ya existe y se van a sobrescribir datos, advertirlo antes.
- El campo `nota_pronto_pago` puede quedar vacío string `""` — es opcional.
- Nunca eliminar un conjunto sin confirmación explícita del usuario.
