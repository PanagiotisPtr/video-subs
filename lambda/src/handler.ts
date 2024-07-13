import { S3Event } from 'aws-lambda';
import { SQSClient, SendMessageCommand } from '@aws-sdk/client-sqs';

const sqsClient = new SQSClient({ region: process.env.AWS_REGION });

export const handleS3Event = async (event: S3Event): Promise<void> => {
  const queueUrl = process.env.SQS_QUEUE_URL;
  if (!queueUrl) {
    throw new Error('SQS_QUEUE_URL is not set');
  }

  for (const record of event.Records) {
    const s3 = record.s3;
    const bucket = s3.bucket.name;
    const key = s3.object.key;

    const messageBody = JSON.stringify({
      bucket,
      key,
    });

    const params = {
      QueueUrl: queueUrl,
      MessageBody: messageBody,
    };

    try {
      const command = new SendMessageCommand(params);
      await sqsClient.send(command);
      console.log(`Message sent to SQS queue: ${messageBody}`);
    } catch (error) {
      console.error(`Error sending message to SQS queue: ${error}`);
      throw error;
    }
  }
};

