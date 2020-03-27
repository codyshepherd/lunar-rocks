import boto3
import json
import os

s3 = boto3.client('s3')

def handler(event, context):
    print("serve_client_fn")
    method = event['httpMethod']
    page_bucket_name = os.environ['S3_BUCKET']

    path = event.get('path', '')
    widget_name = path.split('/')[1] if path.startswith('/') else path;

    if method == "GET":
      # GET / to get the index.html page
      if path == "/":
        # We grab the current file pointer first
        # TODO: using a current file may not be necessary with versioned s3 bucket
        current = s3.get_object(Bucket=page_bucket_name, Key='current.txt')
        index_target = current['Body'].read().decode('utf-8').strip()
        print(f'index target: {index_target}')

        index_page = s3.get_object(Bucket=page_bucket_name, Key=index_target)

        return {
          "body": json.dumps(index_page['Body'].read().decode('utf-8')),
          "headers": {
            'content-type': "text/html",
          },
          "isBase64Encoded": False,
          "statusCode": 200,
        }


