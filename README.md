# powerimo/github-actions

Reusable GitHub Actions for storing and restoring Maven caches and build artifacts via AWS S3.

## Prerequisites

All actions require AWS credentials to be configured before use. The recommended way is via [aws-actions/configure-aws-credentials](https://github.com/aws-actions/configure-aws-credentials):

```yaml
- uses: aws-actions/configure-aws-credentials@v5
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: us-east-1
```

## Actions

### `save-cache-s3`

Archives `~/.m2/repository` and uploads it to S3. Skips upload if the cache already exists.

**Inputs**

| Input | Required | Description |
|---|---|---|
| `bucket` | yes | S3 bucket name |
| `prefix` | yes | Path prefix inside the bucket (e.g. `my-project`) |

**S3 paths used**
- Main cache: `maven-cache/<prefix>/<sha256-of-pom.xml>.tar.gz`
- Base fallback: `maven-cache/<prefix>/base.tar.gz`

**Example**

```yaml
- uses: powerimo/github-actions/.github/actions/save-cache-s3@main
  with:
    bucket: my-ci-bucket
    prefix: my-project
```

---

### `restore-cache-s3`

Downloads and extracts Maven cache from S3 into `~/.m2/repository`. First tries the exact cache for the current `pom.xml`; falls back to the stable base cache if not found. Never fails the workflow if no cache exists.

**Inputs**

| Input | Required | Description |
|---|---|---|
| `bucket` | yes | S3 bucket name |
| `prefix` | yes | Path prefix inside the bucket |

**Example**

```yaml
- uses: powerimo/github-actions/.github/actions/restore-cache-s3@main
  with:
    bucket: my-ci-bucket
    prefix: my-project
```

---

### `upload-artifact-s3`

Collects one or more files, bundles them into a `.tar.gz` archive, and uploads to S3. Mirrors the interface of GitHub's built-in `upload-artifact` action.

**Inputs**

| Input | Required | Description |
|---|---|---|
| `name` | yes | Artifact name (used as the archive filename) |
| `bucket` | yes | S3 bucket name |
| `prefix` | yes | Path prefix inside the bucket |
| `paths` | yes | Newline-separated list of file paths or globs to include |

**S3 path**: `artifacts/<prefix>/<name>.tar.gz`

**Example**

```yaml
- uses: powerimo/github-actions/.github/actions/upload-artifact-s3@main
  with:
    name: my-app
    bucket: my-ci-bucket
    prefix: my-project
    paths: |
      target/my-app.jar
      target/my-app-sources.jar
```

---

### `download-artifact-s3`

Downloads a `.tar.gz` artifact from S3 and extracts it to a local directory.

**Inputs**

| Input | Required | Default | Description |
|---|---|---|---|
| `name` | yes | — | Artifact name |
| `bucket` | yes | — | S3 bucket name |
| `prefix` | yes | — | Path prefix inside the bucket |
| `destination` | no | `./` | Local directory to extract files into |

**Example**

```yaml
- uses: powerimo/github-actions/.github/actions/download-artifact-s3@main
  with:
    name: my-app
    bucket: my-ci-bucket
    prefix: my-project
    destination: ./dist
```

---

## Full workflow example

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5

      - uses: aws-actions/configure-aws-credentials@v5
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - uses: powerimo/github-actions/.github/actions/restore-cache-s3@main
        with:
          bucket: my-ci-bucket
          prefix: my-project

      - run: mvn package

      - uses: powerimo/github-actions/.github/actions/save-cache-s3@main
        with:
          bucket: my-ci-bucket
          prefix: my-project

      - uses: powerimo/github-actions/.github/actions/upload-artifact-s3@main
        with:
          name: my-app
          bucket: my-ci-bucket
          prefix: my-project
          paths: target/my-app.jar

  deploy:
    runs-on: ubuntu-latest
    needs: build
    steps:
      - uses: aws-actions/configure-aws-credentials@v5
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - uses: powerimo/github-actions/.github/actions/download-artifact-s3@main
        with:
          name: my-app
          bucket: my-ci-bucket
          prefix: my-project
          destination: ./dist
```

## Cache key strategy

The Maven cache actions use the SHA256 hash of `pom.xml` as the main cache key. When `pom.xml` hasn't changed since the last run, the exact cache is restored instantly. When `pom.xml` changes (new dependencies added), the main cache won't exist yet, so a stable base cache (`base.tar.gz`) is used as a warm starting point. After the build, both a new main cache and (if absent) a new base cache are saved.

## License

Apache 2.0
