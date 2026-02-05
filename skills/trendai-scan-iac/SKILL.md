---
name: trendai-scan-iac
description: Scan Terraform and CloudFormation templates for security misconfigurations using Vision One Cloud Posture API.
argument-hint: [template-file-or-directory]
allowed-tools: Read, Grep, Glob, Bash
---

# TrendAI IaC Scanner

Scan **Terraform** and **CloudFormation** templates for security misconfigurations.

## What This Scans

| File Type | Method | Examples |
|-----------|--------|----------|
| CloudFormation | Template API | `.yaml`, `.yml`, `.json` with `AWSTemplateFormatVersion` |
| Terraform HCL | Archive API | `.tf` files |
| Terraform Plan | Template API | `plan.json` from `terraform show -json` |

## Prerequisites

1. `TMAS_API_KEY` environment variable (Vision One API token)
2. Token must have **Cloud Posture** permissions enabled

Optional: `V1_REGION` for non-US regions (default: `api.xdr.trendmicro.com`)

### Vision One Regions

| Region | Endpoint |
|--------|----------|
| US | api.xdr.trendmicro.com |
| EU | api.eu.xdr.trendmicro.com |
| Japan | api.xdr.trendmicro.co.jp |
| Singapore | api.sg.xdr.trendmicro.com |
| Australia | api.au.xdr.trendmicro.com |

## Scan CloudFormation

```bash
V1_REGION="${V1_REGION:-api.xdr.trendmicro.com}"

curl -s -X POST "https://${V1_REGION}/beta/cloudPosture/scanTemplate" \
  -H "Authorization: Bearer ${TMAS_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"type\": \"cloudformation-template\", \"content\": $(cat /path/to/template.yaml | jq -Rs .)}"
```

## Scan Terraform HCL (.tf files)

```bash
# Create zip archive of .tf files
cd /path/to/terraform/dir
zip -r /tmp/tf-scan.zip *.tf modules/ 2>/dev/null || zip -r /tmp/tf-scan.zip *.tf

# Send to API
V1_REGION="${V1_REGION:-api.xdr.trendmicro.com}"
curl -s -X POST "https://${V1_REGION}/beta/cloudPosture/scanTemplateArchive" \
  -H "Authorization: Bearer ${TMAS_API_KEY}" \
  -F "type=terraform-archive" \
  -F "file=@/tmp/tf-scan.zip"
```

## Scan Terraform Plan JSON

```bash
# Generate plan JSON first
terraform plan -out=plan.out && terraform show -json plan.out > plan.json

# Scan
V1_REGION="${V1_REGION:-api.xdr.trendmicro.com}"
curl -s -X POST "https://${V1_REGION}/beta/cloudPosture/scanTemplate" \
  -H "Authorization: Bearer ${TMAS_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"type\": \"terraform-template\", \"content\": $(cat plan.json | jq -Rs .)}"
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
      "description": "S3 bucket should have encryption",
      "resourceId": "aws_s3_bucket.data",
      "resourceType": "aws_s3_bucket",
      "resolutionReferenceLink": "https://..."
    }
  ]
}
```

- Only show findings where `status` is `FAILURE`
- `riskLevel`: VERY_HIGH, HIGH, MEDIUM, LOW

## Workflow

1. Detect template type (CloudFormation vs Terraform)
2. Check API key: `echo $TMAS_API_KEY | head -c 20`
3. Run appropriate curl command
4. Parse JSON and present findings

## Detecting Template Type

**CloudFormation** - Look for in `.yaml`/`.yml`/`.json`:
- `AWSTemplateFormatVersion`
- `Resources` with `AWS::` types
- `Transform: AWS::Serverless`

**Terraform** - File extension:
- `.tf` = HCL (use archive endpoint)
- `.tf.json` or `plan.json` = JSON (use template endpoint)

## Output Format

```
## IaC Security Scan Results

**Target**: /path/to/main.tf
**Type**: Terraform
**Scanned**: 2026-02-05

### Summary
| Severity | Count |
|----------|-------|
| Critical | 0 |
| High | 3 |
| Medium | 5 |

### Findings

#### [HIGH] AWS-S3-001: S3 bucket encryption not enabled
- **Resource**: aws_s3_bucket.data
- **Description**: S3 bucket should have server-side encryption
- **Fix**: Add `server_side_encryption_configuration` block
- **Reference**: https://...

#### [MEDIUM] AWS-S3-005: S3 bucket versioning disabled
- **Resource**: aws_s3_bucket.data
- **Description**: Enable versioning for data protection
- **Fix**: Add `versioning { enabled = true }`
```

## Target

$ARGUMENTS
