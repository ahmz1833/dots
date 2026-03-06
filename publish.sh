#!/bin/bash

set -e

S3_BUCKET="s3://ahmz/dots"

echo "Creating tarball of the current repository..."
TEMP_DIR=$(mktemp -d)
cp -R . "${TEMP_DIR}/dots"

# Clean up redundant files before archiving
rm -rf "${TEMP_DIR}/dots/.git" "${TEMP_DIR}/dots/dots.tar.gz"

tar -czf dots.tar.gz -C "$TEMP_DIR" dots
rm -rf "$TEMP_DIR"

echo "Uploading dots.tar.gz to S3..."
s3cmd put dots.tar.gz "${S3_BUCKET}/dots.tar.gz" --acl-public

echo "Preparing forced-S3 version of bootstrap.sh..."
sed 's/FETCH_MODE="interactive"/FETCH_MODE="s3"/' bootstrap.sh > /tmp/bootstrap_s3.sh

echo "Uploading bootstrap.sh to S3..."
s3cmd put /tmp/bootstrap_s3.sh "${S3_BUCKET}/bootstrap.sh" --acl-public
# Install with:
# curl -sL https://s3.ahmz.ir/dots/bootstrap.sh | bash
# For using non-interactive and no-sudo mode:
# curl -sL https://s3.ahmz.ir/dots/bootstrap.sh | bash -s -- --no-sudo

rm dots.tar.gz
rm /tmp/bootstrap_s3.sh

echo "Publish to S3 complete."
