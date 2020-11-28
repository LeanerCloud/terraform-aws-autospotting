from base64 import b64decode
from boto3 import client
from json import dumps
from os import environ
from sys import exc_info
from traceback import print_exc

lambda_arn = (environ['AUTOSPOTTING_LAMBDA_ARN'])


def parse_region_from_arn(arn):
    return arn.split(':')[3]


def handler(event, context):
    print("Running Lambda function", lambda_arn)
    snsEvent = {
        'Records': [
            {
                'Event': 'aws:sns',
                'EventSource': '1.0',
                'EventSubscriptionArn': 'arn:aws:sns:' + event['region'] + ':FakeAccountId:FakeTopic',
                'Sns': {
                    'Type': 'Notification',
                    'Message': dumps(event),
                }
            }
        ]
    }
    try:
        svc = client('lambda', region_name=parse_region_from_arn(lambda_arn))
        response = svc.invoke(
            FunctionName=lambda_arn,
            LogType='Tail',
            Payload=dumps(snsEvent),
        )
        print("Invoked funcion log tail:\n", b64decode(
            response["LogResult"]).decode('utf-8'))
    except:
        print_exc()
        print("Unexpected error:", exc_info()[0])
