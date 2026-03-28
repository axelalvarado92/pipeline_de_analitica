# 🧠 📊 Explicación de la arquitectura (end-to-end)

Este proyecto implementa un **pipeline de analítica de eventos serverless en AWS**, donde se ingieren, procesan, almacenan y consultan datos de manera escalable.

---

# 🚀 🔄 Flujo completo

## 🧩 1. Ingesta de eventos — Kinesis

Todo comienza cuando se envía un evento a **Amazon Kinesis Data Streams**.

👉 Ejemplo de evento:

```json
{
  "user_id": "123",
  "event_type": "purchase"
}
```

📌 Kinesis actúa como un **stream de datos en tiempo real**, permitiendo:

* alta escalabilidad
* procesamiento asíncrono
* desacoplar productores y consumidores

---

## 🧩 2. Procesamiento — AWS Lambda

Kinesis está conectado a una función Lambda mediante un:

👉 `event_source_mapping`

---

### 🔄 ¿Qué hace Lambda?

Por cada evento:

1. Recibe el batch desde Kinesis
2. Decodifica el mensaje (base64)
3. Lo transforma a JSON
4. Genera una estructura de almacenamiento
5. Guarda el evento en S3

---

### 📌 Ejemplo de almacenamiento:

```bash
s3://pipeline-data-dev/events/2026/03/28/archivo.json
```

---

👉 Esto implementa un patrón de:

💥 **Data Lake (raw events)**

---

## 🧩 3. Almacenamiento — Amazon S3

Los datos se almacenan en un bucket S3 que actúa como:

👉 **capa de persistencia**

Características:

* altamente disponible
* barato
* desacoplado del procesamiento

---

👉 Además:

✔️ versionado habilitado
✔️ encriptación con KMS
✔️ estructura particionada por fecha

---

## 🧩 4. Catalogación — AWS Glue Crawler

Aquí entra **AWS Glue**

---

### 🔍 ¿Qué hace el Crawler?

1. Escanea los archivos en S3
2. Detecta automáticamente el schema (JSON)
3. Crea/actualiza una tabla en el Data Catalog

---

📌 Esto permite:

💥 convertir archivos sin estructura en datos consultables

---

## 🧩 5. Metadata — Glue Data Catalog

Glue crea:

* una **database**
* una **tabla (ej: events)**

---

👉 Esta tabla apunta a:

```bash
s3://pipeline-data-dev/events/
```

---

## 🧩 6. Consulta — Amazon Athena

Athena permite ejecutar SQL directamente sobre S3.

---

### 🔍 Ejemplo:

```sql
SELECT * FROM events LIMIT 10;
```

---

👉 Athena:

1. Lee los datos desde S3
2. Usa el schema definido por Glue
3. Ejecuta la query

---

## 🧩 7. Resultados — S3 (Athena bucket)

Los resultados de la query se guardan en otro bucket:

```bash
s3://pipeline-athena-results-dev/
```

---

👉 Este bucket es:

💥 SOLO para resultados de consultas

---

# 🧠 📌 Componentes clave y su rol

| Componente   | Rol                               |
| ------------ | --------------------------------- |
| Kinesis      | ingesta de eventos en tiempo real |
| Lambda       | procesamiento y transformación    |
| S3 (data)    | almacenamiento de eventos         |
| Glue Crawler | detección de schema               |
| Glue Catalog | metadata                          |
| Athena       | consultas SQL                     |
| S3 (results) | resultados de queries             |

---

# 🔐 Seguridad

La arquitectura incluye:

* IAM roles para cada servicio
* KMS para encriptación
* acceso controlado a S3

---

# ⚡ Ventajas de esta arquitectura

### 🚀 Escalabilidad

* Kinesis + Lambda escalan automáticamente

### 💰 Costos

* serverless → pagás por uso

### 🔄 Desacoplamiento

* cada componente es independiente

### 📊 Analítica en tiempo casi real

* datos disponibles rápidamente en Athena
