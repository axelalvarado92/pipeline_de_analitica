import boto3
import json
import time
import os

s3 = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")

table = dynamodb.Table(os.environ["DYNAMODB_TABLE"])

PROCESSED_PREFIX = "processed/events/"
REJECTED_PREFIX = "rejected/events/"

# TTL 24h
TTL_SECONDS = 86400


# -----------------------------
# DEDUP
# -----------------------------
def is_duplicate(event_id):
    resp = table.get_item(Key={"event_id": event_id})
    return "Item" in resp


def mark_processed(event_id):
    table.put_item(Item={
        "event_id": event_id,
        "expires_at": int(time.time()) + TTL_SECONDS
    })


# -----------------------------
# S3 HELPERS
# -----------------------------
def read_s3(bucket, key):
    obj = s3.get_object(Bucket=bucket, Key=key)
    return obj["Body"].read().decode("utf-8")


def write_s3(bucket, key, body):
    s3.put_object(
        Bucket=bucket,
        Key=key,
        Body=body,
        ContentType="application/json"
    )


# -----------------------------
# CORE LOGIC
# -----------------------------
def validate_and_normalize(raw):
    # validar JSON
    payload = json.loads(raw)

    # normalizar (1 línea, Athena-friendly)
    clean = json.dumps(payload, separators=(",", ":"), ensure_ascii=False)

    return clean


def move_to_rejected(bucket, key, raw):
    filename = key.split("/")[-1]

    rejected_key = f"{REJECTED_PREFIX}{filename}"

    write_s3(bucket, rejected_key, raw)

    print(f"Moved to rejected: {rejected_key}")


def move_to_processed(bucket, key, clean):
    filename = key.split("/")[-1]

    processed_key = f"{PROCESSED_PREFIX}{filename}"

    write_s3(bucket, processed_key, clean)

    print(f"Saved to processed: {processed_key}")


# -----------------------------
# HANDLER
# -----------------------------
def lambda_handler(event, context):

    print("Evento recibido:")
    print(json.dumps(event, indent=2))

    for record in event["Records"]:

        bucket = record["s3"]["bucket"]["name"]
        key = record["s3"]["object"]["key"]

        event_id = f"{bucket}:{key}"

        print(f"Procesando: {event_id}")

        # 1️⃣ dedup
        if is_duplicate(event_id):
            print("Skip duplicate:", event_id)
            continue

        try:
            # 2️⃣ leer archivo
            raw = read_s3(bucket, key)

            # 3️⃣ validar + normalizar
            clean = validate_and_normalize(raw)

            # 4️⃣ guardar limpio
            move_to_processed(bucket, key, clean)

            # 5️⃣ marcar procesado SOLO si todo salió bien
            mark_processed(event_id)

        except Exception as e:
            print("Error procesando archivo:", str(e))

            try:
                move_to_rejected(bucket, key, raw)
            except Exception as inner_error:
                print("Error moviendo a rejected:", str(inner_error))

    return {
        "statusCode": 200
    }