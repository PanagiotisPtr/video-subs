import os
import boto3
import json
from video_processor import process_video
from whisper_subtitles.py import generate_subtitles

sqs = boto3.client('sqs')
s3 = boto3.client('s3')

def poll_sqs(queue_url):
    response = sqs.receive_message(
        QueueUrl=queue_url,
        MaxNumberOfMessages=1,
        WaitTimeSeconds=20
    )

    if 'Messages' in response:
        for message in response['Messages']:
            handle_message(message)
            sqs.delete_message(
                QueueUrl=queue_url,
                ReceiptHandle=message['ReceiptHandle']
            )

def handle_message(message):
    body = json.loads(message['Body'])
    bucket = body['bucket']
    key = body['key']
    uuid = key.split('/')[-1].split('.')[0]

    local_video_path = f'/tmp/{uuid}.mp4'
    download_file(bucket, key, local_video_path)

    resolutions = {'low': 480, 'medium': 720, 'high': 1080}
    for res, height in resolutions.items():
        output_path = f'/tmp/{uuid}_{res}.mp4'
        process_video(local_video_path, output_path, height)
        generate_subtitles(output_path)
        upload_file(bucket, f'output_videos/{uuid}/{res}.mp4', output_path)

def download_file(bucket, key, download_path):
    s3.download_file(bucket, key, download_path)

def upload_file(bucket, key, upload_path):
    s3.upload_file(upload_path, bucket, key)

if __name__ == "__main__":
    queue_url = os.environ['SQS_QUEUE_URL']
    while True:
        poll_sqs(queue_url)
