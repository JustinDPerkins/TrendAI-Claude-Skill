# TrendAI Scanner Reference

## TMAS CLI Full Reference

### Artifact Types

| Type | Description | Example |
|------|-------------|---------|
| `dir` | Local directory | `tmas scan dir:./src` |
| `file` | Single file | `tmas scan file:./package.json` |
| `registry` | Container registry image | `tmas scan registry:nginx:latest` |
| `docker` | Local Docker daemon image | `tmas scan docker:myapp:dev` |
| `docker-archive` | Docker save tarball | `tmas scan docker-archive:./image.tar` |
| `oci-archive` | OCI image archive | `tmas scan oci-archive:./oci-image.tar` |
| `oci-dir` | OCI image directory | `tmas scan oci-dir:./oci-layout` |
| `podman` | Podman image | `tmas scan podman:myimage` |
| `singularity` | Singularity image | `tmas scan singularity:./image.sif` |

### Regions

| Region Code | Location |
|-------------|----------|
| `us-east-1` | US East (N. Virginia) |
| `us-west-2` | US West (Oregon) |
| `eu-central-1` | Europe (Frankfurt) |
| `eu-west-1` | Europe (Ireland) |
| `ap-southeast-1` | Asia Pacific (Singapore) |
| `ap-southeast-2` | Asia Pacific (Sydney) |
| `ap-northeast-1` | Asia Pacific (Tokyo) |
| `ap-south-1` | Asia Pacific (Mumbai) |
| `ca-central-1` | Canada (Central) |

### Scanner Flags

| Flag | Description |
|------|-------------|
| `-V, --vulnerabilities` | Enable vulnerability scanning |
| `-S, --secrets` | Enable secret detection |
| `-M, --malware` | Enable malware scanning (container images only) |
| `-r, --region` | Cloud region for API calls |
| `--evaluatePolicy` | Evaluate against configured policies |
| `--redacted` | Redact secret values in output |

### Environment Variables

| Variable | Description |
|----------|-------------|
| `TMAS_API_KEY` | Vision One API token (required) |

## Vulnerability Severity Levels

| Level | CVSS Score | Description |
|-------|------------|-------------|
| Critical | 9.0 - 10.0 | Immediate action required |
| High | 7.0 - 8.9 | Address soon |
| Medium | 4.0 - 6.9 | Plan to address |
| Low | 0.1 - 3.9 | Low priority |
| Negligible | 0.0 | Informational |

## Secret Types Detected

- AWS Access Keys and Secret Keys
- Azure Storage Keys
- GCP Service Account Keys
- GitHub Tokens
- GitLab Tokens
- Slack Tokens
- Stripe API Keys
- Database Connection Strings
- Private Keys (RSA, DSA, EC)
- JWT Tokens
- Generic API Keys and Passwords

## IaC Scanning (via Vision One API)

For Terraform and CloudFormation scanning, the extension uses the Vision One REST API:

### Terraform
- `.tf` files (HCL format)
- Terraform plan JSON output
- Multi-file projects (archived and uploaded)

### CloudFormation
- `.yaml` / `.yml` templates
- `.json` templates

### API Endpoints

| Endpoint | Purpose |
|----------|---------|
| `/beta/cloudPosture/scanTemplate` | Scan single template (CF or TF plan JSON) |
| `/beta/cloudPosture/scanTemplateArchive` | Scan Terraform HCL archive |
| `/beta/cloudPosture/terraformTemplateScannerRules` | Get Terraform rules |
| `/beta/cloudPosture/cloudformationTemplateScannerRules` | Get CloudFormation rules |

## Common Scan Scenarios

### Scan Node.js Project
```bash
tmas scan dir:. -V -S -r us-east-1
```
Detects vulnerabilities in `package.json` / `package-lock.json` and secrets in source files.

### Scan Python Project
```bash
tmas scan dir:. -V -S -r us-east-1
```
Detects vulnerabilities in `requirements.txt`, `Pipfile.lock`, `poetry.lock`.

### Scan Before Docker Build
```bash
tmas scan dir:. -V -S -r us-east-1
docker build -t myapp .
docker save myapp -o /tmp/myapp.tar
tmas scan docker-archive:/tmp/myapp.tar -V -M -r us-east-1
```

### Scan Production Image
```bash
tmas scan registry:myregistry.com/myapp:v1.2.3 -V -S -M -r us-east-1
```

## Troubleshooting

### "API token not configured"
Set the `TMAS_API_KEY` environment variable:
```bash
export TMAS_API_KEY="your-vision-one-api-token"
```

### "Unsupported platform"
TMAS supports:
- macOS (ARM64 and x86_64)
- Linux (ARM64 and x86_64)
- Windows (ARM64 and x86_64)

### "No vulnerabilities found"
This could mean:
- No known vulnerabilities in dependencies
- Package manifest not detected (check file formats)
- Scan region mismatch

### Slow scans
- Large directories may take time
- Container images are scanned layer by layer
- Use `--redacted` if you don't need secret values
