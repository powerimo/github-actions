#!/bin/bash
set -e

BUCKET="$1"
PREFIX="$2"

KEY=$(sha256sum pom.xml | cut -d ' ' -f1)
CACHE_MAIN="maven-cache/$PREFIX/$KEY.tar.gz"
CACHE_BASE="maven-cache/$PREFIX/base.tar.gz"
ARCHIVE="/tmp/maven-cache-$KEY.tar.gz"

echo "📤 Attempting to save Maven cache..."

create_archive() {
  if [[ ! -f "$ARCHIVE" ]]; then
    echo "🗜️ Creating archive..."
    tar -czf "$ARCHIVE" -C ~/.m2/repository .
  fi
}

# Save main cache if it doesn't exist yet
if aws s3 ls "s3://$BUCKET/$CACHE_MAIN" > /dev/null 2>&1; then
  echo "✅ Main cache already exists: $CACHE_MAIN"
else
  create_archive
  echo "📤 Uploading to s3://$BUCKET/$CACHE_MAIN..."
  aws s3 cp "$ARCHIVE" "s3://$BUCKET/$CACHE_MAIN"
  echo "✅ Uploaded: $CACHE_MAIN"
fi

# Save base fallback cache if it doesn't exist yet
if aws s3 ls "s3://$BUCKET/$CACHE_BASE" > /dev/null 2>&1; then
  echo "✅ Base fallback cache already exists: $CACHE_BASE"
else
  create_archive
  echo "📤 Uploading to s3://$BUCKET/$CACHE_BASE..."
  aws s3 cp "$ARCHIVE" "s3://$BUCKET/$CACHE_BASE"
  echo "✅ Uploaded: $CACHE_BASE"
fi
