#!/bin/bash

set -euo pipefail

OUTPUT_DIR=archive
CURRENT_DIR=$(pwd)
ROOT_DIR="$( dirname "${BASH_SOURCE[0]}" )"/..
APP_VERSION=$(date +%s)
STACK_NAME=graphql-apollo-server-lambda-nodejs

cd "$ROOT_DIR"

echo "cleaning up old build.."
[ -d $OUTPUT_DIR ] && rm -rf $OUTPUT_DIR

mkdir archive

echo "zipping source code.."
zip -rq $OUTPUT_DIR/base-graphql-api-"$APP_VERSION".zip src node_modules package.json

echo "uploading source code to S3.."
aws s3 cp $OUTPUT_DIR/base-graphql-api-"$APP_VERSION".zip s3://"$S3_BUCKET"/base-graphql-api-"$APP_VERSION".zip

echo "deploying application..."
aws cloudformation deploy \
  --template-file "$ROOT_DIR"/cloudformation.yml \
  --stack-name $STACK_NAME \
  --parameter-overrides Version="$APP_VERSION" BucketName="$S3_BUCKET" \
  --capabilities CAPABILITY_IAM

API_URL=$(
  aws cloudformation describe-stacks \
  --stack-name=$STACK_NAME \
  --query "Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue" \
  --output text
)

echo -e "\n$API_URL"

cd "$CURRENT_DIR"


