---
name: trendai-scan-tmas
description: Scan code for vulnerabilities and secrets using TMAS CLI. Automatically scans current directory for dependencies and secrets.
argument-hint: [optional-directory-or-image]
allowed-tools: Bash, AskUserQuestion, Read, Write, Glob
---

# TrendAI Security Scanner (TMAS)

Scan code for **vulnerabilities**, **secrets**, and **malware** using TrendMicro Artifact Scanner (TMAS).

## CRITICAL: Interactive Configuration Workflow

**ALWAYS use AskUserQuestion to gather configuration before running scans.** This ensures the right scan type and options are used.

### Step 1: Check Prerequisites

First verify TMAS is installed and API key is set:
```bash
tmas version
echo "TMAS_API_KEY: ${TMAS_API_KEY:+SET}"
```

If TMAS is not installed, tell user to run `/trendai-setup`.

### Step 2: Determine Target

If `$ARGUMENTS` contains a target path or image, use that. Otherwise, ask the user.

Use AskUserQuestion:

**Question**: "What do you want to scan?"
**Header**: "Target"
**Options**:
1. **Current directory** - "Scan the current working directory for vulnerabilities and secrets"
2. **Container image** - "Scan a Docker/OCI image for vulnerabilities, secrets, and malware"
3. **Specific path** - "Scan a specific directory or file"
4. **Existing SBOM** - "Scan vulnerabilities from a CycloneDX/SPDX SBOM file"

### Step 3: Get Target Details (if needed)

For **Container image**, ask:

**Question**: "Where is the container image?"
**Header**: "Image Source"
**Options**:
1. **Docker daemon** - "Local Docker image (docker:image:tag)"
2. **Container registry** - "Pull from registry (registry:repo/image:tag)"
3. **Docker archive** - "Tarball from 'docker save' (docker-archive:path.tar)"
4. **OCI archive** - "OCI format tarball (oci-archive:path.tar)"

Then ask for the image name/path.

### Step 4: Ask Scan Options

Use AskUserQuestion with multiSelect=true:

**Question**: "Which scans do you want to run?"
**Header**: "Scans"
**Options** (multiSelect: true):
1. **Vulnerabilities (-V)** - "Scan for known CVEs in dependencies (Recommended)"
2. **Secrets (-S)** - "Scan for hardcoded API keys, passwords, tokens (Recommended)"
3. **Malware (-M)** - "Scan for malware (container images only)"

### Step 5: Ask Additional Options

Use AskUserQuestion with multiSelect=true:

**Question**: "Do you want any additional options?"
**Header**: "Options"
**Options** (multiSelect: true):
1. **Generate SBOM** - "Save CycloneDX SBOM for compliance (--saveSBOM)"
2. **Evaluate policy** - "Check against Vision One policy, fail if violated (--evaluatePolicy)"
3. **Redact secrets** - "Hide secret values in output (--redacted)"
4. **None** - "Run with default options"

### Step 6: Run the Scan

Build and run the command based on user selections:

```bash
# Create scan history directory
mkdir -p .trendai-scans

# Build scan command
# Format: tmas scan <artifact-type>:<path-or-image> [flags] -r <region>

# Examples:
tmas scan dir:. -V -S -r us-east-1                           # Directory
tmas scan docker:myimage:tag -V -S -M -r us-east-1           # Docker image
tmas scan registry:nginx:latest -V -S -M -r us-east-1        # Registry image
tmas scan file:package-lock.json -V -r us-east-1             # Single file
tmas scan sbom:cyclonedx.json -V -r us-east-1                # Existing SBOM

# Save output to timestamped file for drift tracking
SCAN_FILE=".trendai-scans/tmas-scan-$(date +%Y%m%d-%H%M%S).json"
tmas scan <artifact> [flags] -r us-east-1 2>&1 | tee "$SCAN_FILE"
```

### Step 7: Parse Results and Generate Report

The output is JSON with this structure:
```json
{
  "vulnerabilities": {
    "totalVulnCount": 5,
    "criticalCount": 1,
    "highCount": 2,
    "mediumCount": 2,
    "lowCount": 0,
    "findings": {
      "package-name": [{
        "id": "CVE-2024-1234",
        "severity": "Critical",
        "fixedInVersion": "1.2.3",
        "cvss": 9.8
      }]
    }
  },
  "secrets": {
    "totalFilesScanned": 100,
    "unmitigatedFindingsCount": 2,
    "findings": {
      "src/config.js": [{
        "ruleId": "aws-access-key",
        "line": 15
      }]
    }
  },
  "malware": {
    "scanResult": 0,
    "findings": []
  }
}
```

### Step 8: Compare with Previous Scans (Drift Detection)

Check for previous scans to show improvement/regression:

```bash
# Find previous scans
ls -t .trendai-scans/tmas-scan-*.json 2>/dev/null | head -5
```

If previous scans exist, compare:
1. Read the most recent previous scan JSON
2. Compare vulnerability counts by severity
3. Compare secrets count
4. Show drift indicators (↑ improved, ↓ regressed, → unchanged)

## Artifact Types Reference

| Type | Vulns | Secrets | Malware | Example |
|------|:-----:|:-------:|:-------:|---------|
| `dir:` | ✓ | ✓ | - | `dir:/path/to/project` |
| `file:` | ✓ | ✓ | - | `file:package-lock.json` |
| `registry:` | ✓ | ✓ | ✓ | `registry:nginx:latest` |
| `docker:` | ✓ | ✓ | ✓ | `docker:myimage:tag` |
| `podman:` | ✓ | ✓ | - | `podman:myimage:tag` |
| `docker-archive:` | ✓ | ✓ | ✓ | `docker-archive:image.tar` |
| `oci-archive:` | ✓ | ✓ | ✓ | `oci-archive:image.tar` |
| `oci-dir:` | ✓ | ✓ | ✓ | `oci-dir:/path/to/oci` |
| `singularity:` | ✓ | ✓ | - | `singularity:image.sif` |
| `sbom` | ✓ | - | - | `sbom:cyclonedx.json` |

## Flags Reference

| Flag | Description |
|------|-------------|
| `-V, --vulnerabilities` | Scan for known CVEs |
| `-S, --secrets` | Scan for hardcoded secrets |
| `-M, --malware` | Scan for malware (images only) |
| `--saveSBOM` | Save CycloneDX 1.6 SBOM to current directory |
| `--evaluatePolicy` | Check against Vision One policy (exit code 2 if violated) |
| `--redacted` | Hide secret values in output |
| `-o, --override` | Path to override rules YAML file |
| `--distro` | Distro for vuln matching (e.g., `alpine:3.18`) |
| `-p, --platform` | Platform for multi-arch images (default: `linux/amd64`) |
| `-r, --region` | Vision One region |

## Region Options

| Region | Flag |
|--------|------|
| US East | `-r us-east-1` |
| EU (Frankfurt) | `-r eu-central-1` |
| EU (London) | `-r eu-west-2` |
| Canada | `-r ca-central-1` |
| India | `-r ap-south-1` |
| Japan | `-r ap-northeast-1` |
| Singapore | `-r ap-southeast-1` |
| Australia | `-r ap-southeast-2` |
| Middle East | `-r me-central-1` |

## Output Format

Present results in this format:

```markdown
## Security Scan Results

**Target**: /path/to/project (or image:tag)
**Scan Time**: 2026-02-06 10:15:00
**Scan ID**: .trendai-scans/tmas-scan-20260206-101500.json

---

### Summary

| Category | Count | Status |
|----------|-------|--------|
| Critical | 1 | 🔴 |
| High | 3 | 🟠 |
| Medium | 5 | 🟡 |
| Low | 2 | 🟢 |
| Secrets | 2 | 🔴 |
| Malware | 0 | ✅ |

---

### Security Posture Drift

(Only show if previous scans exist)

| Category | Previous | Current | Trend |
|----------|----------|---------|-------|
| Critical | 2 | 1 | ↑ Improved |
| High | 3 | 3 | → Unchanged |
| Secrets | 1 | 2 | ↓ Regressed |

---

### Critical Vulnerabilities (1)

#### CVE-2024-1234 - lodash
- **Package**: lodash@4.17.20
- **Severity**: Critical (CVSS 9.8)
- **Fix**: Update to 4.17.21
- **Description**: Prototype pollution vulnerability

---

### High Vulnerabilities (3)

(List each CVE with package, fix version, CVSS)

---

### Secrets Detected (2)

| # | Type | File | Line | Action |
|---|------|------|------|--------|
| 1 | AWS Access Key | src/config.js | 15 | Rotate immediately |
| 2 | GitHub Token | .env.example | 3 | Remove from repo |

---

### SBOM Generated

(Only if --saveSBOM was used)

**File**: SBOM_Directory_projectname_1234567890.json
**Format**: CycloneDX 1.6
**Components**: 127 packages

---

### Recommendations

1. **Critical**: Update lodash to 4.17.21 immediately
2. **Secrets**: Rotate AWS access key and remove from codebase
3. **CI/CD**: Add `--evaluatePolicy` to fail builds on policy violations
```

## Troubleshooting

### "TMAS_API_KEY not set"
Set the environment variable with your Vision One API token.

### "malware scan not supported"
Malware scanning (`-M`) only works with container images, not directories or files.

### "failed to get image"
For Docker images, ensure Docker daemon is running. For registry images, check authentication.

### Exit code 2 with --evaluatePolicy
The scan completed but policy violations were found. Review the output for details.

## Target

$ARGUMENTS
