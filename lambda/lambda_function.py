import json
import boto3

# Connect to the DynamoDB service
dynamodb = boto3.resource('dynamodb')
# Target our specific table
table = dynamodb.Table('cloud-resume-counter')

def lambda_handler(event, context):
    # 1. Update the item in DynamoDB by adding 1 to visitor_count
    response = table.update_item(
        Key={'id': '0'},
        UpdateExpression='SET visitor_count = visitor_count + :val',
        ExpressionAttributeValues={':val': 1},
        ReturnValues='UPDATED_NEW'
    )
    
    # 2. Extract the newly updated count from AWS's response
    new_count = response['Attributes']['visitor_count']
    
    # 3. Send that number back to whoever called the API
    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*', # Allows our website to safely talk to this API
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Methods': 'GET,OPTIONS'
        },
        'body': json.dumps({'count': int(new_count)})
    }
