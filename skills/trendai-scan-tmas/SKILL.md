---
name: trendai-scan-tmas
description: Scan container images and code for vulnerabilities, secrets, and malware using TMAS CLI. Auto-detects Dockerfiles, image tars, and builds images for scanning.
argument-hint: [path-or-image] [--advanced]
allowed-tools: Bash, AskUserQuestion, Read, Write, Glob
---

# TrendAI Security Scanner (TMAS)

Scan **container images** and code for **vulnerabilities**, **secrets**, and **malware**.

## CRITICAL: Zero-Prompt Auto-Detection

**DEFAULT MODE**: Automatically detect artifact type and scan with sensible defaults. NO PROMPTS.

**ADVANCED MODE**: If `$ARGUMENTS` contains `--advanced` or `-a`, then use AskUserQuestion for options.

```bash
# Check for advanced mode
if [[ "$ARGUMENTS" == *"--advanced"* ]] || [[ "$ARGUMENTS" == *"-a"* ]]; then
    ADVANCED_MODE=true
    # Remove flag from arguments
    TARGET=$(echo "$ARGUMENTS" | sed 's/--advanced//g' | sed 's/-a//g' | xargs)
else
    ADVANCED_MODE=false
    TARGET="$ARGUMENTS"
fi
```

### Step 1: Check Prerequisites

```bash
tmas version
echo "TMAS_API_KEY: ${TMAS_API_KEY:+SET}"
docker --version 2>/dev/null || echo "Docker not available"
```

If TMAS is not installed, tell user to run `/trendai-setup`.

### Step 2: Determine Target Path

Use `$ARGUMENTS` if provided, otherwise use the current working directory.

```bash
TARGET="${ARGUMENTS:-.}"
```

### Step 3: Auto-Detect Artifact Type

Analyze the target to determine what type of scan to run. Check in this order:

```bash
# Check what we're dealing with
TARGET_PATH="/path/to/target"

# 1. Is it a container image reference? (contains : but not a file path)
#    Examples: nginx:latest, myrepo/myimage:v1.0, registry.io/app:tag
if [[ "$TARGET" =~ ^[a-zA-Z0-9._-]+(/[a-zA-Z0-9._-]+)*(:[a-zA-Z0-9._-]+)?$ ]] && [[ ! -e "$TARGET" ]]; then
    echo "DETECTED: Container image reference"
fi

# 2. Is it a .tar file? (docker-archive or oci-archive)
ls "$TARGET_PATH"/*.tar 2>/dev/null

# 3. Is there a Dockerfile? (can build and scan)
ls "$TARGET_PATH"/Dockerfile* 2>/dev/null

# 4. Is there a docker-compose.yml? (extract image names)
ls "$TARGET_PATH"/docker-compose*.yml 2>/dev/null

# 5. Is it a directory with code? (scan for deps and secrets)
ls "$TARGET_PATH"/package.json "$TARGET_PATH"/go.mod "$TARGET_PATH"/requirements.txt "$TARGET_PATH"/Gemfile "$TARGET_PATH"/pom.xml "$TARGET_PATH"/build.gradle 2>/dev/null
```

### Step 4: Execute Based on Detection

#### If: Container Image Reference (e.g., `nginx:latest`, `myapp:v1`)
```bash
# Check if image exists locally first
if docker image inspect "$IMAGE" &>/dev/null; then
    # Scan from local Docker daemon
    tmas scan docker:"$IMAGE" -V -S -M -r us-east-1
else
    # Pull from registry and scan
    tmas scan registry:"$IMAGE" -V -S -M -r us-east-1
fi
```

#### If: Image Tar File Found (*.tar)
```bash
# Detect if it's docker-archive or oci-archive
# docker-archive has manifest.json at root
# oci-archive has oci-layout file
if tar -tf "$TAR_FILE" | grep -q "^manifest.json$"; then
    tmas scan docker-archive:"$TAR_FILE" -V -S -M -r us-east-1
elif tar -tf "$TAR_FILE" | grep -q "oci-layout"; then
    tmas scan oci-archive:"$TAR_FILE" -V -S -M -r us-east-1
fi
```

#### If: Dockerfile Found

**Default mode**: Automatically build and scan the image.
**Advanced mode**: Ask user if they want to build or just scan directory.

```bash
# Default: Build and scan automatically
IMAGE_NAME="tmas-scan-$(basename "$TARGET_PATH"):$(date +%s)"

echo "Building image from Dockerfile..."
docker build -t "$IMAGE_NAME" "$TARGET_PATH"

echo "Scanning image..."
tmas scan docker:"$IMAGE_NAME" -V -S -M -r us-east-1

# Clean up the temporary image
docker rmi "$IMAGE_NAME" 2>/dev/null
```

If `ADVANCED_MODE=true`, use AskUserQuestion:
- **Question**: "Found Dockerfile. Build and scan, or scan directory only?"
- **Options**: "Build and scan image" / "Scan directory only"

#### If: docker-compose.yml Found

**Default mode**: Extract all images and scan them sequentially.
**Advanced mode**: Ask which images to scan.

```bash
# Extract and scan all images
for IMAGE in $(grep -E "^\s+image:" docker-compose*.yml | awk '{print $2}'); do
    echo "Scanning $IMAGE..."
    tmas scan registry:"$IMAGE" -V -S -M -r us-east-1
done
```

#### If: Code Directory (no Docker artifacts)

Scan the directory for vulnerabilities and secrets (no malware - not supported for dirs):
```bash
tmas scan dir:"$TARGET_PATH" -V -S -r us-east-1
```

### Step 5: Run Scan with History Tracking

Always save results for drift tracking:

```bash
mkdir -p .trendai-scans

# Determine scan type label
SCAN_TYPE="image"  # or "dir" based on detection

SCAN_FILE=".trendai-scans/tmas-${SCAN_TYPE}-$(date +%Y%m%d-%H%M%S).json"

# Run scan and save
tmas scan <artifact> -V -S -M -r us-east-1 2>&1 | tee "$SCAN_FILE"
```

### Step 6: Parse and Report Results

The JSON output structure:
```json
{
  "vulnerabilities": {
    "totalVulnCount": 15,
    "criticalCount": 2,
    "highCount": 5,
    "mediumCount": 6,
    "lowCount": 2,
    "findings": { ... }
  },
  "secrets": {
    "totalFilesScanned": 1847,
    "unmitigatedFindingsCount": 3,
    "findings": { ... }
  },
  "malware": {
    "scanResult": 0,
    "findings": []
  }
}
```

### Step 7: Drift Detection

Compare with previous scans:
```bash
# Find previous scans of same type
PREV_SCAN=$(ls -t .trendai-scans/tmas-${SCAN_TYPE}-*.json 2>/dev/null | sed -n '2p')

if [[ -n "$PREV_SCAN" ]]; then
    # Compare vulnerability counts
    echo "Previous scan: $PREV_SCAN"
fi
```

## Detection Priority

| Priority | Artifact | Scan Command | Flags |
|----------|----------|--------------|-------|
| 1 | Image reference | `docker:` or `registry:` | `-V -S -M` |
| 2 | Image tar file | `docker-archive:` or `oci-archive:` | `-V -S -M` |
| 3 | Dockerfile | Build → `docker:` | `-V -S -M` |
| 4 | docker-compose.yml | Extract images → scan each | `-V -S -M` |
| 5 | Code directory | `dir:` | `-V -S` |

## Scan Flags by Artifact Type

| Artifact | Vulns (-V) | Secrets (-S) | Malware (-M) |
|----------|:----------:|:------------:|:------------:|
| Container images | ✓ | ✓ | ✓ |
| Directories | ✓ | ✓ | - |
| Files | ✓ | ✓ | - |

## Output Format

```markdown
## Container Security Scan Results

**Image**: myapp:v1.2.3
**Scan Time**: 2026-02-06 10:15:00
**Scan File**: .trendai-scans/tmas-image-20260206-101500.json

---

### Summary

| Category | Count | Severity |
|----------|-------|----------|
| Critical | 2 | 🔴 CRITICAL |
| High | 5 | 🟠 HIGH |
| Medium | 6 | 🟡 MEDIUM |
| Low | 2 | 🟢 LOW |
| Secrets | 3 | 🔴 SECRETS |
| Malware | 0 | ✅ CLEAN |

---

### Drift (vs previous scan)

| Category | Previous | Current | Trend |
|----------|----------|---------|-------|
| Critical | 3 | 2 | ↑ -1 |
| High | 5 | 5 | → 0 |
| Secrets | 1 | 3 | ↓ +2 |

---

### Critical Vulnerabilities (2)

#### 1. CVE-2024-1234 - openssl
- **Package**: openssl 3.0.1
- **Layer**: /usr/lib/x86_64-linux-gnu/libssl.so
- **CVSS**: 9.8 (Critical)
- **Fix**: Update to openssl 3.0.12
- **Description**: Buffer overflow in X.509 certificate verification

#### 2. CVE-2024-5678 - curl
- **Package**: curl 7.88.0
- **CVSS**: 9.1 (Critical)
- **Fix**: Update to curl 8.4.0

---

### High Vulnerabilities (5)

(List each with package, CVSS, fix version)

---

### Secrets Detected (3)

| # | Type | Location | Action |
|---|------|----------|--------|
| 1 | AWS Access Key | /app/config.py:23 | Rotate + remove |
| 2 | Private Key | /app/certs/key.pem | Remove from image |
| 3 | Database Password | /app/.env:5 | Use secrets manager |

---

### Malware Scan

✅ No malware detected

---

### Recommendations

1. **CRITICAL**: Rebuild base image with updated openssl (3.0.12+) and curl (8.4.0+)
2. **SECRETS**: Never embed credentials in images - use runtime secrets injection
3. **BASE IMAGE**: Consider using a distroless or minimal base image to reduce attack surface
4. **CI/CD**: Add `tmas scan` to your build pipeline with `--evaluatePolicy` to block vulnerable images
```

## Common Patterns

### Quick scan (no prompts)
```bash
/trendai-scan-tmas                     # Scan current directory
/trendai-scan-tmas nginx:latest        # Scan Docker Hub image
/trendai-scan-tmas ./myapp             # Scan path (auto-detects Dockerfile)
/trendai-scan-tmas myapp.tar           # Scan image tarball
```

### Advanced mode (interactive prompts)
```bash
/trendai-scan-tmas --advanced          # Prompts for options
/trendai-scan-tmas ./myapp -a          # Advanced mode for path
```

### Scan a Docker Hub image
```bash
/trendai-scan-tmas nginx:latest
/trendai-scan-tmas python:3.11-slim
/trendai-scan-tmas ghcr.io/org/app:v1
```

### Scan a local Docker image
```bash
/trendai-scan-tmas myapp:dev
```

### Build and scan from Dockerfile
```bash
/trendai-scan-tmas .
# Auto-detects Dockerfile, builds image, scans, cleans up
```

### Scan an exported image tar
```bash
docker save myapp:latest -o myapp.tar
/trendai-scan-tmas myapp.tar
```

## Region Options

| Region | Flag |
|--------|------|
| US East (default) | `-r us-east-1` |
| EU Frankfurt | `-r eu-central-1` |
| EU London | `-r eu-west-2` |
| Canada | `-r ca-central-1` |
| Japan | `-r ap-northeast-1` |
| Singapore | `-r ap-southeast-1` |
| Australia | `-r ap-southeast-2` |

## Troubleshooting

### "failed to get image"
- For `docker:` - ensure Docker daemon is running
- For `registry:` - check authentication (docker login)

### "malware scan not supported"
Malware (`-M`) only works with container images, not directories.

### Build fails
Check Dockerfile syntax and ensure all build dependencies are available.

## Target

$ARGUMENTS
