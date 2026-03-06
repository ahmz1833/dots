#!/bin/bash

set -e

S3_BUCKET="s3://ahmz"
DOTS_DIR="dots"

cd ..

echo "Creating tarball of the dots directory..."
tar -czf dots.tar.gz "$DOTS_DIR"

echo "Uploading dots.tar.gz to S3..."
s3cmd put dots.tar.gz "${S3_BUCKET}/dots/dots.tar.gz" --acl-public

cd dots

echo "Preparing forced-S3 version of bootstrap.sh..."
sed 's/FETCH_MODE="interactive"/FETCH_MODE="s3"/' bootstrap.sh > /tmp/bootstrap_s3.sh

echo "Uploading bootstrap.sh to S3..."
s3cmd put /tmp/bootstrap_s3.sh "${S3_BUCKET}/dots/bootstrap.sh" --acl-public

rm dots.tar.gz
rm /tmp/bootstrap_s3.sh

echo "Publish to S3 complete."
