import json
import os
import uuid

import boto3


dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])


def lambda_handler(event, context):
    try:
        body = json.loads(event.get("body") or "{}")
        message = body.get("message")

        if not message:
            return {
                "statusCode": 400,
                "body": json.dumps({
                    "error": "message is required"
                })
            }

        item = {
            "id": str(uuid.uuid4()),
            "message": message
        }

        table.put_item(Item=item)

        return {
            "statusCode": 201,
            "body": json.dumps({
                "message": "Event created successfully",
                "id": item["id"]
            })
        }

    except Exception as error:
        print(f"Error processing request: {error}")

        return {
            "statusCode": 500,
            "body": json.dumps({
                "error": "Internal server error"
            })
        }