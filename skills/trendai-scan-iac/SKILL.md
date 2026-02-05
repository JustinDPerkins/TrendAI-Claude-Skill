---
name: trendai-scan-iac
description: Scan Terraform and CloudFormation templates for security misconfigurations using Vision One Cloud Posture API.
argument-hint: [directory-or-file]
allowed-tools: Read, Bash
---

# TrendAI IaC Scanner

Scan **Terraform** and **CloudFormation** templates for security misconfigurations.

## Prerequisites

1. `TMAS_API_KEY` environment variable (Vision One API token with Cloud Posture permissions)
2. `jq` installed for JSON processing

Optional: `V1_REGION` (default: `api.xdr.trendmicro.com`)

## IMPORTANT: Batch Scanning

When given a directory, scan ALL IaC files in a single operation:
- **Terraform**: Zip all `.tf` files together → one API call
- **CloudFormation**: Combine all templates → one API call per template type

DO NOT prompt for each file individually. Run ONE bash command that handles everything.

## Scan Directory (Recommended)

Use this single command to scan an entire directory:

```bash
#!/bin/bash
set -e
TARGET_DIR="${1:-.}"
V1_REGION="${V1_REGION:-api.xdr.trendmicro.com}"
RESULTS_FILE="/tmp/iac-scan-results.json"
echo "[]" > "$RESULTS_FILE"

# Scan Terraform files
TF_FILES=$(find "$TARGET_DIR" -name "*.tf" -type f 2>/dev/null | head -100)
if [ -n "$TF_FILES" ]; then
  echo "Found Terraform files, creating archive..."
  rm -f /tmp/tf-scan.zip
  cd "$TARGET_DIR"
  find . -name "*.tf" -type f | xargs zip -@ /tmp/tf-scan.zip 2>/dev/null

  echo "Scanning Terraform archive..."
  TF_RESULT=$(curl -s -X POST "https://${V1_REGION}/beta/cloudPosture/scanTemplateArchive" \
    -H "Authorization: Bearer ${TMAS_API_KEY}" \
    -F "type=terraform-archive" \
    -F "file=@/tmp/tf-scan.zip")
  echo "$TF_RESULT" | jq -r '.scanResults // []' >> "$RESULTS_FILE"
fi

# Scan CloudFormation files
CFN_FILES=$(find "$TARGET_DIR" \( -name "*.yaml" -o -name "*.yml" -o -name "*.json" \) -type f 2>/dev/null | xargs grep -l "AWSTemplateFormatVersion\|AWS::" 2>/dev/null | head -50)
if [ -n "$CFN_FILES" ]; then
  echo "Found CloudFormation templates..."
  for f in $CFN_FILES; do
    echo "Scanning: $f"
    CONTENT=$(cat "$f" | jq -Rs .)
    CFN_RESULT=$(curl -s -X POST "https://${V1_REGION}/beta/cloudPosture/scanTemplate" \
      -H "Authorization: Bearer ${TMAS_API_KEY}" \
      -H "Content-Type: application/json" \
      -d "{\"type\": \"cloudformation-template\", \"content\": $CONTENT}")
    echo "$CFN_RESULT" | jq -r --arg file "$f" '.scanResults // [] | map(. + {file: $file})'
  done
fi

echo "Scan complete."
```

## Scan Single File

### Terraform (.tf)
```bash
V1_REGION="${V1_REGION:-api.xdr.trendmicro.com}"
DIR=$(dirname "$FILE")
cd "$DIR" && zip -j /tmp/tf-scan.zip *.tf
curl -s -X POST "https://${V1_REGION}/beta/cloudPosture/scanTemplateArchive" \
  -H "Authorization: Bearer ${TMAS_API_KEY}" \
  -F "type=terraform-archive" \
  -F "file=@/tmp/tf-scan.zip"
```

### CloudFormation (.yaml/.yml/.json)
```bash
V1_REGION="${V1_REGION:-api.xdr.trendmicro.com}"
curl -s -X POST "https://${V1_REGION}/beta/cloudPosture/scanTemplate" \
  -H "Authorization: Bearer ${TMAS_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"type\": \"cloudformation-template\", \"content\": $(cat "$FILE" | jq -Rs .)}"
```

## Response Format

```json
{
  "scanResults": [
    {
      "ruleId": "AWS-S3-001",
      "ruleTitle": "S3 bucket encryption not enabled",
      "riskLevel": "HIGH",
      "status": "FAILURE",
      "resourceId": "aws_s3_bucket.data",
      "resolutionReferenceLink": "https://..."
    }
  ]
}
```

Only report findings where `status` is `FAILURE`.

## Workflow

1. Check target is file or directory
2. If directory: Run batch scan script above (ONE bash command)
3. If file: Detect type and run single-file scan
4. Collect all results and present summary

## Output Format

```
## IaC Security Scan Results

**Target**: /path/to/infrastructure
**Files Scanned**: 12 Terraform, 3 CloudFormation
**Scanned**: 2026-02-05

### Summary
| Severity | Count |
|----------|-------|
| Critical | 1 |
| High | 5 |
| Medium | 8 |
| Low | 3 |

### Critical/High Findings

#### [CRITICAL] AWS-IAM-001: IAM policy allows *
- **File**: iam.tf
- **Resource**: aws_iam_policy.admin
- **Fix**: Restrict to specific resources

#### [HIGH] AWS-S3-001: S3 bucket not encrypted
- **File**: s3.tf
- **Resource**: aws_s3_bucket.data
- **Fix**: Add server_side_encryption_configuration

### Medium/Low Findings
(list remaining...)
```

## Vision One Regions

| Region | Endpoint |
|--------|----------|
| US | api.xdr.trendmicro.com |
| EU | api.eu.xdr.trendmicro.com |
| Japan | api.xdr.trendmicro.co.jp |
| Singapore | api.sg.xdr.trendmicro.com |
| Australia | api.au.xdr.trendmicro.com |

## Target

$ARGUMENTS
