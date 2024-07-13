#!/bin/bash

LAMBDA_BUCKET="video-processing-lambda-bucket"
LAMBDA_KEY="lambda/s3-trigger-lambda.zip"
LAMBDA_FUNCTION_NAME="s3-trigger-lambda"

cd lambda

npm install
npm run build

zip -r dist.zip dist/*

aws s3 cp dist.zip s3://$LAMBDA_BUCKET/$LAMBDA_KEY

aws lambda update-function-code --function-name $LAMBDA_FUNCTION_NAME --s3-bucket $LAMBDA_BUCKET --s3-key $LAMBDA_KEY

rm dist.zip

echo "Lambda function deployed successfully"
