import os
import boto3
import json
import time
from whisper_subtitles import generate_subtitles

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
    print("handling message: ", message)
    body = json.loads(message['Body'])
    bucket = body['bucket']
    key = body['key']
    basename = key.replace("input_videos/", "").replace(".mp4", "")
    dir = "/tmp/" + "/".join(key.replace("input_videos/", "").split("/")[:-1])
    os.makedirs(dir, exist_ok=True)

    local_video_path = f'/tmp/{basename}.mp4'
    print("downloading video: ", bucket, key, local_video_path)
    s3.download_file(bucket, key, local_video_path)

    output_path = f'/tmp/{basename}_processed.mp4'
    print("video path: ", local_video_path)
    subtitles_path = generate_subtitles(local_video_path, output_path)
    print("uploading file")
    s3.upload_file(output_path, bucket, f'output_videos/{basename}.mp4')
    s3.upload_file(subtitles_path, bucket, f'output_videos/{basename}.srt')
    print("completed message processing")


if __name__ == "__main__":
    queue_url = os.environ['SQS_QUEUE_URL']
    while True:
        print("polling")
        poll_sqs(queue_url)
