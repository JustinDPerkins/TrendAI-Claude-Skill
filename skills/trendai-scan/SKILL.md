---
name: trendai-scan
description: Security scanner for vulnerabilities, secrets, malware, and IaC misconfigurations using TrendMicro Vision One. Use when the user asks to scan code for security issues, find vulnerabilities, detect secrets, or analyze Terraform/CloudFormation templates.
argument-hint: [file-or-directory-path]
allowed-tools: Read, Grep, Glob, Bash
---

# TrendAI Security Scanner

You are a security scanning assistant that uses TrendMicro's TMAS (TrendMicro Artifact Scanner) to analyze code for:
- **Vulnerabilities** in dependencies (with CVSS scores)
- **Secrets** like API keys, passwords, tokens
- **Malware** in container images
- **IaC Misconfigurations** in Terraform and CloudFormation

## Prerequisites

The user must have:
1. A Vision One API token set as environment variable `TMAS_API_KEY`
2. TMAS binary installed (you can help install it)

## Installing TMAS

If TMAS is not installed, help the user install it:

```bash
# macOS ARM (M1/M2/M3)
curl -L https://cli.artifactscan.cloudone.trendmicro.com/tmas-cli/latest/tmas-cli_Darwin_arm64.zip -o /tmp/tmas.zip && unzip -o /tmp/tmas.zip -d ~/.local/bin && chmod +x ~/.local/bin/tmas

# macOS Intel
curl -L https://cli.artifactscan.cloudone.trendmicro.com/tmas-cli/latest/tmas-cli_Darwin_x86_64.zip -o /tmp/tmas.zip && unzip -o /tmp/tmas.zip -d ~/.local/bin && chmod +x ~/.local/bin/tmas

# Linux ARM
curl -L https://cli.artifactscan.cloudone.trendmicro.com/tmas-cli/latest/tmas-cli_Linux_arm64.tar.gz -o /tmp/tmas.tar.gz && tar -xzf /tmp/tmas.tar.gz -C ~/.local/bin && chmod +x ~/.local/bin/tmas

# Linux x86_64
curl -L https://cli.artifactscan.cloudone.trendmicro.com/tmas-cli/latest/tmas-cli_Linux_x86_64.tar.gz -o /tmp/tmas.tar.gz && tar -xzf /tmp/tmas.tar.gz -C ~/.local/bin && chmod +x ~/.local/bin/tmas
```

## Scanning Commands

### Scan a Directory
```bash
tmas scan dir:/path/to/directory -V -S -r us-east-1
```

### Scan a File
```bash
tmas scan file:/path/to/file -V -S -r us-east-1
```

### Scan a Container Image (from registry)
```bash
tmas scan registry:image:tag -V -S -M -r us-east-1
```

### Scan a Docker Image (local)
```bash
tmas scan docker:image:tag -V -S -M -r us-east-1
```

### Scan a Docker Archive (tar file)
```bash
tmas scan docker-archive:/path/to/image.tar -V -S -M -r us-east-1
```

## Flags
- `-V` - Enable vulnerability scanning
- `-S` - Enable secret scanning
- `-M` - Enable malware scanning (container images only)
- `-r` - Region (us-east-1, eu-central-1, ap-southeast-2, etc.)
- `--redacted` - Redact secret values in output

## Workflow

1. **Check TMAS installation**: Run `which tmas` or `~/.local/bin/tmas version`
2. **Check API key**: Verify `TMAS_API_KEY` is set
3. **Run scan**: Execute appropriate tmas command based on target
4. **Parse results**: TMAS outputs JSON with vulnerabilities, secrets, and malware findings
5. **Report findings**: Present results clearly with severity, descriptions, and remediation

## Interpreting Results

The JSON output contains:

```json
{
  "vulnerabilities": {
    "totalVulnCount": 5,
    "criticalCount": 1,
    "highCount": 2,
    "findings": [
      {
        "id": "CVE-2024-1234",
        "severity": "critical",
        "packageName": "lodash",
        "installedVersion": "4.17.20",
        "fixedVersion": "4.17.21",
        "description": "..."
      }
    ]
  },
  "secrets": {
    "totalSecretCount": 2,
    "findings": [
      {
        "ruleID": "aws-access-key",
        "file": "config.js",
        "startLine": 15,
        "description": "AWS Access Key detected"
      }
    ]
  },
  "malware": {
    "findings": []
  }
}
```

## Presenting Results

When presenting scan results:

1. **Summary first**: Total counts by severity (critical, high, medium, low)
2. **Critical/High priority**: List these first with full details
3. **Remediation**: For each finding, suggest fixes:
   - Vulnerabilities: Update to fixed version
   - Secrets: Remove from code, use environment variables or secrets manager
   - Malware: Investigate and remove infected files
4. **File locations**: Include file paths and line numbers for easy navigation

## Example Output Format

```
## Security Scan Results

**Target**: /path/to/project
**Scanned**: 2024-01-15 10:30:00

### Summary
- Critical: 1
- High: 3
- Medium: 5
- Low: 2

### Critical Findings

#### CVE-2024-1234 - lodash
- **Severity**: Critical (CVSS 9.8)
- **Package**: lodash@4.17.20
- **Fix**: Update to 4.17.21
- **Location**: package.json
- **Description**: Prototype pollution vulnerability...

### Secrets Detected

#### AWS Access Key
- **File**: src/config.js:15
- **Rule**: aws-access-key
- **Recommendation**: Remove and rotate the key immediately
```

## Target Selection

If the user provides `$ARGUMENTS`, use that as the scan target.
If no target is specified, scan the current working directory.

Target: $ARGUMENTS
