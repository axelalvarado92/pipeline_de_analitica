import boto3
import os

glue = boto3.client('glue')

def lambda_handler(event, context):

    crawler_name = os.environ["CRAWLER_NAME"]

    print(f"Disparando crawler: {crawler_name}")

    try:
        glue.start_crawler(Name=crawler_name)
    except glue.exceptions.CrawlerRunningException:
        print("El crawler ya está corriendo, no pasa nada")

    return {
        "statusCode": 200
    }