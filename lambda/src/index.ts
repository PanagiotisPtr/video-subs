import { S3Handler } from 'aws-lambda';
import { handleS3Event } from './handler';

export const handler: S3Handler = async (event, context) => {
  await handleS3Event(event);
};
