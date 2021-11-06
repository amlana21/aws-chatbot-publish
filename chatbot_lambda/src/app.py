import boto3
import os
import json

client = boto3.client('sns')


def lambda_handler(event, context):
    print(event)

    jobState='error'
    errMsg=''
    jobName=''
    statusMsg=''

    if 'detail' in event.keys():
        jobState=event['detail']['state']
        jobName=event['detail']['jobName']
        if jobState=='FAILED':
            # jobName=event['detail']['jobName']
            errMsg=event['detail']['message']
            statusMsg=f'Job Name: {jobName}--------Job Status: {jobState}------Error Reason: {errMsg}'
        else:
            statusMsg=f'Job Name: {jobName}--------Job Status: {jobState}'
    else:
        print('error in identifying job')
        return 'error'

    
    event['detail-type']=statusMsg
    response = client.publish(
    TopicArn=os.getenv('ERRSNSTOPIC'),
    Message=json.dumps(event)
)



