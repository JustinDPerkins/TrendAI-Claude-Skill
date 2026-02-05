---
name: trendai-scan
description: Scan code for vulnerabilities and secrets using TMAS CLI. Use for dependency scanning (package.json, go.mod, etc.), secret detection, and container image scanning.
argument-hint: [file-or-directory-or-image]
allowed-tools: Read, Grep, Glob, Bash
---

# TrendAI Security Scanner (TMAS)

Scan code for **vulnerabilities** and **secrets** using TrendMicro Artifact Scanner (TMAS).

## What This Scans

| Target | Flags | What It Finds |
|--------|-------|---------------|
| Directory | `-V -S` | Dependency vulnerabilities, hardcoded secrets |
| File | `-V -S` | Dependency vulnerabilities, hardcoded secrets |
| Container image | `-V -S -M` | Vulnerabilities, secrets, malware |

## Prerequisites

1. `TMAS_API_KEY` environment variable set
2. TMAS CLI installed at `~/.local/bin/tmas`

### Install TMAS

```bash
# macOS ARM (M1/M2/M3)
curl -L https://cli.artifactscan.cloudone.trendmicro.com/tmas-cli/latest/tmas-cli_Darwin_arm64.zip -o /tmp/tmas.zip && unzip -o /tmp/tmas.zip -d ~/.local/bin && chmod +x ~/.local/bin/tmas

# macOS Intel
curl -L https://cli.artifactscan.cloudone.trendmicro.com/tmas-cli/latest/tmas-cli_Darwin_x86_64.zip -o /tmp/tmas.zip && unzip -o /tmp/tmas.zip -d ~/.local/bin && chmod +x ~/.local/bin/tmas

# Linux x86_64
curl -L https://cli.artifactscan.cloudone.trendmicro.com/tmas-cli/latest/tmas-cli_Linux_x86_64.tar.gz -o /tmp/tmas.tar.gz && tar -xzf /tmp/tmas.tar.gz -C ~/.local/bin && chmod +x ~/.local/bin/tmas
```

## Commands

```bash
# Scan directory
tmas scan dir:/path/to/project -V -S -r us-east-1

# Scan file
tmas scan file:/path/to/file -V -S -r us-east-1

# Scan container image
tmas scan registry:nginx:latest -V -S -M -r us-east-1
tmas scan docker:myimage:tag -V -S -M -r us-east-1
tmas scan docker-archive:/path/to/image.tar -V -S -M -r us-east-1
```

## Flags

- `-V` - Vulnerability scanning
- `-S` - Secret scanning
- `-M` - Malware scanning (images only)
- `-r` - Region (us-east-1, eu-central-1, ap-southeast-2)
- `--saveSBOM` - Save software bill of materials

## Workflow

1. Check TMAS: `~/.local/bin/tmas version`
2. Check API key: `echo $TMAS_API_KEY | head -c 20`
3. Run scan with appropriate command
4. Parse JSON output and present findings

## Output Format

```
## Security Scan Results

**Target**: /path/to/project
**Scanned**: 2026-02-05

### Summary
| Category | Count |
|----------|-------|
| Critical | 1 |
| High | 3 |
| Secrets | 2 |

### Critical Vulnerabilities

#### CVE-2024-1234 - lodash
- **Package**: lodash@4.17.20
- **Fix**: Update to 4.17.21
- **CVSS**: 9.8

### Secrets Detected

#### AWS Access Key
- **File**: src/config.js:15
- **Action**: Remove and rotate immediately
```

## Target

$ARGUMENTS
