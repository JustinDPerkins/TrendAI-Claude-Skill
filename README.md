# TrendAI Security Scanner for Claude Code

Scan your code for **vulnerabilities**, **secrets**, **malware**, and **IaC misconfigurations** using TrendMicro Vision One directly from Claude Code.

## Quick Install

```bash
claude plugins add github:JustinDPerkins/TrendAI-Claude-Skill
```

## Setup

After installing, run the setup command in Claude Code:

```
/trendai-setup
```

This will:
1. Install the TMAS CLI (if not already installed)
2. Guide you through API key configuration

### Manual Setup

If you prefer manual setup:

**1. Install TMAS CLI**

```bash
# macOS (Apple Silicon)
curl -L https://cli.artifactscan.cloudone.trendmicro.com/tmas-cli/latest/tmas-cli_Darwin_arm64.zip -o /tmp/tmas.zip && unzip -o /tmp/tmas.zip -d ~/.local/bin && chmod +x ~/.local/bin/tmas

# macOS (Intel)
curl -L https://cli.artifactscan.cloudone.trendmicro.com/tmas-cli/latest/tmas-cli_Darwin_x86_64.zip -o /tmp/tmas.zip && unzip -o /tmp/tmas.zip -d ~/.local/bin && chmod +x ~/.local/bin/tmas

# Linux (x86_64)
curl -L https://cli.artifactscan.cloudone.trendmicro.com/tmas-cli/latest/tmas-cli_Linux_x86_64.tar.gz -o /tmp/tmas.tar.gz && tar -xzf /tmp/tmas.tar.gz -C ~/.local/bin && chmod +x ~/.local/bin/tmas

# Linux (ARM64)
curl -L https://cli.artifactscan.cloudone.trendmicro.com/tmas-cli/latest/tmas-cli_Linux_arm64.tar.gz -o /tmp/tmas.tar.gz && tar -xzf /tmp/tmas.tar.gz -C ~/.local/bin && chmod +x ~/.local/bin/tmas
```

**2. Get a Vision One API Key**

1. Log in to [Trend Vision One](https://portal.xdr.trendmicro.com)
2. Go to **Administration** > **API Keys**
3. Create a new API key with **Cloud Security Operations** permissions
4. Copy the key

**3. Set Environment Variable**

Add to your shell profile (`~/.zshrc` or `~/.bashrc`):

```bash
export TMAS_API_KEY="your-api-key-here"
```

Then reload your shell:
```bash
source ~/.zshrc  # or ~/.bashrc
```

## Usage

Once configured, use the `/trendai-scan` command:

```
/trendai-scan                     # Scan current directory
/trendai-scan ./src               # Scan specific directory
/trendai-scan ./package.json      # Scan specific file
```

### Scan Types

| Target | Command |
|--------|---------|
| Directory | `/trendai-scan /path/to/dir` |
| File | `/trendai-scan /path/to/file` |
| Docker image | Ask Claude to scan `docker:image:tag` |
| Container registry | Ask Claude to scan `registry:image:tag` |

### What It Detects

- **Vulnerabilities** - CVEs in dependencies with CVSS scores and remediation
- **Secrets** - API keys, passwords, tokens, certificates
- **Malware** - Malicious code in container images
- **IaC Misconfigurations** - Security issues in Terraform/CloudFormation

## Requirements

- [Claude Code CLI](https://claude.ai/claude-code)
- [Trend Vision One account](https://www.trendmicro.com/en_us/business/products/vision-one.html)

## License

MIT
