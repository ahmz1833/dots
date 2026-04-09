#!/bin/bash

set -e

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
if [ -f "${SCRIPT_DIR}/.env" ]; then
	set -a
	. "${SCRIPT_DIR}/.env"
	set +a
fi

S3_BUCKET="${S3_BUCKET:-s3://ahmz/dots}"
S3_ENDPOINT_URL="${S3_ENDPOINT_URL:-https://s3.ir-thr-at1.arvanstorage.ir}"
AWS_REGION="${AWS_REGION:-ir-thr-at1}"
BOOTSTRAP_FETCH_MODE="${BOOTSTRAP_FETCH_MODE:-s3}"
BOOTSTRAP_INSTALL_REGION="${BOOTSTRAP_INSTALL_REGION:-iran}"

echo "Creating tarball of the current repository..."
TEMP_DIR=$(mktemp -d)
cp -R . "${TEMP_DIR}/dots"

# Clean up redundant files before archiving
rm -rf "${TEMP_DIR}/dots/.git" "${TEMP_DIR}/dots/dots.tar.gz"

tar -czf dots.tar.gz -C "$TEMP_DIR" dots
rm -rf "$TEMP_DIR"

echo "Uploading dots.tar.gz to S3..."
aws s3 cp dots.tar.gz "${S3_BUCKET}/dots.tar.gz" --acl public-read --region "$AWS_REGION" --endpoint-url "$S3_ENDPOINT_URL"

echo "Preparing forced-S3 version of bootstrap.sh..."
sed \
	-e "s/FETCH_MODE=\"interactive\"/FETCH_MODE=\"${BOOTSTRAP_FETCH_MODE}\"/" \
	-e "s/INSTALL_REGION=\"\"/INSTALL_REGION=\"${BOOTSTRAP_INSTALL_REGION}\"/" \
	bootstrap.sh > /tmp/bootstrap_s3.sh

echo "Uploading bootstrap.sh to S3..."
aws s3 cp /tmp/bootstrap_s3.sh "${S3_BUCKET}/bootstrap.sh" --acl public-read --region "$AWS_REGION" --endpoint-url "$S3_ENDPOINT_URL"
# Install with:
# curl -sL https://s3.ahmz.ir/dots/bootstrap.sh | bash
# For using non-interactive and no-sudo mode:
# curl -sL https://s3.ahmz.ir/dots/bootstrap.sh | bash -s -- --no-sudo

rm dots.tar.gz
rm /tmp/bootstrap_s3.sh

echo "Publish to S3 complete."
