import boto3
import os

glue = boto3.client('glue')

def lambda_handler(event, context):

    crawler_name = os.environ["CRAWLER_NAME"]

    print(f"Disparando crawler: {crawler_name}")

    # 🔍 1. Chequear estado primero
    crawler = glue.get_crawler(Name=crawler_name)
    state = crawler["Crawler"]["State"]

    print(f"Estado actual del crawler: {state}")

    # 🧠 2. Solo iniciar si está listo
    if state == "READY":
        glue.start_crawler(Name=crawler_name)
        print("Crawler iniciado correctamente")
    else:
        print(f"No se inicia crawler porque está en estado: {state}")

    return {
        "statusCode": 200
    }