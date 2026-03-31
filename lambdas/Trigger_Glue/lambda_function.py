import boto3
import os

glue = boto3.client('glue')

def lambda_handler(event, context):

    crawler_name = os.environ['CRAWLER_NAME']

    print("Evento recibido:", event)

    try:
        glue.start_crawler(Name=crawler_name)
        print(f"Crawler {crawler_name} iniciado")
    except Exception as e:
        print("Error iniciando crawler:", str(e))

    return {"status": "ok"}