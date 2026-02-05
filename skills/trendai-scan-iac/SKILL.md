---
name: trendai-scan-iac
description: Scan Terraform and CloudFormation templates for security misconfigurations. Automatically finds and scans all IaC files in the current directory.
argument-hint: [optional-directory]
allowed-tools: Bash
---

# TrendAI IaC Scanner

Automatically find and scan all Terraform (.tf) and CloudFormation (.yaml/.yml/.json) files for security misconfigurations.

## How It Works

1. Scans current directory (or specified path) recursively
2. Finds all .tf files → zips and sends to Terraform API
3. Finds all CloudFormation files → sends each to CloudFormation API
4. Reports all findings in a single summary

## Prerequisites

- `TMAS_API_KEY` environment variable set
- `jq` installed

## Run This Script

Execute this single bash script to scan everything. Replace `TARGET_DIR` with `$ARGUMENTS` if provided, otherwise use `.` (current directory):

```bash
#!/bin/bash
TARGET_DIR="${1:-.}"
V1_REGION="${V1_REGION:-api.xdr.trendmicro.com}"

echo "=== TrendAI IaC Security Scan ==="
echo "Target: $TARGET_DIR"
echo ""

ALL_RESULTS="[]"

# --- Terraform Scan ---
TF_COUNT=$(find "$TARGET_DIR" -name "*.tf" -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$TF_COUNT" -gt 0 ]; then
  echo "Found $TF_COUNT Terraform files"
  rm -f /tmp/tf-scan.zip
  (cd "$TARGET_DIR" && find . -name "*.tf" -type f -print0 | xargs -0 zip -@ /tmp/tf-scan.zip) 2>/dev/null

  TF_RESULT=$(curl -s -X POST "https://${V1_REGION}/beta/cloudPosture/scanTemplateArchive" \
    -H "Authorization: Bearer ${TMAS_API_KEY}" \
    -F "type=terraform-archive" \
    -F "file=@/tmp/tf-scan.zip" 2>/dev/null)

  echo "Terraform scan complete"
  echo "$TF_RESULT" | jq -r '.scanResults // [] | .[] | select(.status != "SUCCESS") | "[\(.riskLevel // "MEDIUM")] \(.ruleId): \(.ruleTitle // .description) | Resource: \(.resourceId // "unknown")"' 2>/dev/null
  echo ""
fi

# --- CloudFormation Scan ---
CFN_FILES=$(find "$TARGET_DIR" \( -name "*.yaml" -o -name "*.yml" -o -name "*.json" \) -type f -exec grep -l -E "(AWSTemplateFormatVersion|AWS::)" {} \; 2>/dev/null)
CFN_COUNT=$(echo "$CFN_FILES" | grep -c . 2>/dev/null || echo 0)
if [ "$CFN_COUNT" -gt 0 ]; then
  echo "Found $CFN_COUNT CloudFormation templates"

  for f in $CFN_FILES; do
    echo "Scanning: $f"
    CONTENT=$(cat "$f" | jq -Rs .)
    CFN_RESULT=$(curl -s -X POST "https://${V1_REGION}/beta/cloudPosture/scanTemplate" \
      -H "Authorization: Bearer ${TMAS_API_KEY}" \
      -H "Content-Type: application/json" \
      -d "{\"type\": \"cloudformation-template\", \"content\": $CONTENT}" 2>/dev/null)

    echo "$CFN_RESULT" | jq -r --arg f "$f" '.scanResults // [] | .[] | select(.status != "SUCCESS") | "[\(.riskLevel // "MEDIUM")] \(.ruleId): \(.ruleTitle // .description) | File: \($f) | Resource: \(.resourceId // "unknown")"' 2>/dev/null
  done
  echo ""
fi

if [ "$TF_COUNT" -eq 0 ] && [ "$CFN_COUNT" -eq 0 ]; then
  echo "No IaC files found in $TARGET_DIR"
fi

echo "=== Scan Complete ==="
```

## After Running

Parse the output and present findings grouped by severity:
- VERY_HIGH / CRITICAL first
- HIGH second
- MEDIUM/LOW last

Include the rule ID, description, file, and resource for each finding.

## Target

Directory to scan: $ARGUMENTS (defaults to current directory if not specified)
