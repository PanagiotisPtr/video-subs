#!/bin/bash

# Define variables
LAMBDA_BUCKET="video-processing-bucket"
LAMBDA_KEY="lambda/s3-trigger-lambda.zip"
LAMBDA_FUNCTION_NAME="s3-trigger-lambda"

# Navigate to the lambda directory
cd lambda

# Install dependencies and build the project
npm install
npm run build

# Zip the contents of the dist directory
zip -r dist.zip dist/*

# Upload the zip file to S3
aws s3 cp dist.zip s3://$LAMBDA_BUCKET/$LAMBDA_KEY

# Update the Lambda function code
aws lambda update-function-code --function-name $LAMBDA_FUNCTION_NAME --s3-bucket $LAMBDA_BUCKET --s3-key $LAMBDA_KEY

# Cleanup
rm dist.zip

echo "Lambda function deployed successfully"
