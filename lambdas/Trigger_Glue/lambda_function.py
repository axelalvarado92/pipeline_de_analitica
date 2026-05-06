import boto3
import os

glue = boto3.client('glue')

def lambda_handler(event, context):

    crawler_name = os.environ["CRAWLER_NAME"]

    crawler = glue.get_crawler(Name=crawler_name)
    state = crawler["Crawler"]["State"]

    print(f"State: {state}")

    if state == "READY":
        try:
            glue.start_crawler(Name=crawler_name)
            print("Crawler started")
        except glue.exceptions.ConcurrentRunsExceededException:
            print("Crawler already running, skipping")
    else:
        print("Skipping due to state")

    return {"statusCode": 200}