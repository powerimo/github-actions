# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A collection of reusable GitHub Actions for AWS S3-based Maven cache and artifact management. These composite actions allow CI/CD pipelines to store/restore Maven caches and upload/download build artifacts via S3, bypassing GitHub's built-in artifact size limits.

## Actions

All actions live under `.github/actions/`:

| Action | Purpose |
|---|---|
| `save-cache-s3` | Archives `~/.m2/repository` and uploads to S3 using a SHA256 hash of `pom.xml` as the cache key |
| `restore-cache-s3` | Downloads and extracts Maven cache from S3, with fallback from main cache to base cache |
| `upload-artifact-s3` | Collects file paths, creates a `.tar.gz` archive, and uploads to S3 |
| `download-artifact-s3` | Downloads a `.tar.gz` artifact from S3 and extracts it locally |

## Usage in Workflows

Reference actions directly from this repo:

```yaml
- uses: powerimo/github-actions/.github/actions/save-cache-s3@main
  with:
    bucket: my-s3-bucket
    prefix: my-project
```

## S3 Path Layout

- Maven caches: `maven-cache/<prefix>/<sha256-of-pom.xml>.tar.gz`
- Base/fallback cache: `maven-cache/<prefix>/base.tar.gz`
- Artifacts: `artifacts/<prefix>/<artifact-name>.tar.gz`

## Architecture Notes

- All actions use `using: composite` — no Node.js or Docker runtime needed.
- Cache actions with shell scripts (`save.sh`, `restore.sh`) use `set -e` for fail-fast behavior.
- `restore-cache-s3` silently skips missing caches (`aws s3 cp ... || true`) so missing cache is not a workflow failure.
- AWS credentials must be configured before calling any action (e.g., via `aws-actions/configure-aws-credentials`).

## Adding or Modifying Actions

Each action is a directory containing:
- `action.yml` — defines inputs, outputs, and steps
- Optional shell scripts for non-trivial logic

Shell scripts embedded in `action.yml` steps use `shell: bash`. Standalone `.sh` files are invoked via `run: bash ${{ github.action_path }}/script.sh`.