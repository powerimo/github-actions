#!/bin/bash
set -e

BUCKET="$1"
PREFIX="$2"

KEY=$(sha256sum pom.xml | cut -d ' ' -f1)
CACHE_MAIN="maven-cache/$PREFIX/$KEY.tar.gz"
CACHE_BASE="maven-cache/$PREFIX/${KEY}-base.tar.gz"

echo "📤 Attempting to save Maven cache..."

create_and_upload() {
  local target="$1"
  echo "🗜️ Creating archive..."
  tar -czf cache.tar.gz -C ~/.m2/repository .

  echo "📤 Uploading to s3://$BUCKET/$target..."
  aws s3 cp cache.tar.gz "s3://$BUCKET/$target"
  echo "✅ Uploaded: $target"
}

# Сохраняем основной кэш, если его ещё нет
if aws s3 ls "s3://$BUCKET/$CACHE_MAIN" > /dev/null 2>&1; then
  echo "✅ Main cache already exists: $CACHE_MAIN"
else
  create_and_upload "$CACHE_MAIN"
fi

# Сохраняем базовый кэш, если его ещё нет
if aws s3 ls "s3://$BUCKET/$CACHE_BASE" > /dev/null 2>&1; then
  echo "✅ Base fallback cache already exists: $CACHE_BASE"
else
  create_and_upload "$CACHE_BASE"
fi
