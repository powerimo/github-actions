#!/bin/bash
set -e

BUCKET="$1"
PREFIX="$2"

KEY=$(sha256sum pom.xml | cut -d ' ' -f1)
CACHE_MAIN="maven-cache/$PREFIX/$KEY.tar.gz"
CACHE_BASE="maven-cache/$PREFIX/${KEY}-base.tar.gz"

mkdir -p ~/.m2/repository

restore_from_s3() {
  local path="$1"
  echo "📦 Trying to restore cache from s3://$BUCKET/$path..."
  if aws s3 ls "s3://$BUCKET/$path" > /dev/null 2>&1; then
    aws s3 cp "s3://$BUCKET/$path" cache.tar.gz
    tar -xzf cache.tar.gz -C ~/.m2/repository
    echo "✅ Cache restored from: $path"
    return 0
  fi
  return 1
}

if restore_from_s3 "$CACHE_MAIN"; then
  exit 0
fi

if restore_from_s3 "$CACHE_BASE"; then
  echo "ℹ️ Using fallback base cache"
  exit 0
fi

echo "❌ No cache found (main or base)"
exit 0
