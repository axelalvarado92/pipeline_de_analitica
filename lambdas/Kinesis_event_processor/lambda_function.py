import boto3
import json
import base64
import uuid
from datetime import datetime
import os

s3 = boto3.client('s3')

def lambda_handler(event, context):

    print("Evento completo recibido:")
    print(json.dumps(event, indent=2))

    bucket_name = os.environ["BUCKET_NAME"]

    for record in event['Records']:
        try:
            # 1. Obtener data en base64
            encoded_data = record['kinesis']['data']

            # 2. Decodificar base64 → bytes
            decoded_bytes = base64.b64decode(encoded_data)

            # 3. Convertir bytes → string
            decoded_str = decoded_bytes.decode('utf-8')

            # 4. Convertir string → JSON
            payload = json.loads(decoded_str)

            print("Payload procesado:")
            print(json.dumps(payload, indent=2))

            # 5. Generar path dinámico (particionado)
            key = f"events/year={year}/month={month}/day={day}/{uuid}.json"

            print(f"Guardando en S3 → {key}")

            # 6. Guardar en S3
            s3.put_object(
                Bucket=bucket_name,
                Key=key,
                Body=json.dumps(payload),
                ContentType="application/json"
            )

        except Exception as e:
            print("Error procesando record:")
            print(str(e))

    return {
        "statusCode": 200,
        "body": json.dumps("Procesamiento completo")
    }