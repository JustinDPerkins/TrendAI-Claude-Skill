# TrendAI Security Scanner for Claude Code

> **Disclaimer:** This is an unofficial community project and is not officially supported by TrendAI. Use at your own discretion.

Scan your code for **vulnerabilities**, **secrets**, **malware**, and **IaC misconfigurations** using TrendMicro Vision One directly from Claude Code.

## Quick Install

```bash
claude plugin marketplace add JustinDPerkins/TrendAI-Claude-Skill && claude plugin install trendai-security
```

Then restart Claude Code for the plugin to load.

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

**Windows (Git Bash):**

```bash
# Create directory
mkdir -p "$HOME/.local/bin"

# Download
curl -L https://cli.artifactscan.cloudone.trendmicro.com/tmas-cli/latest/tmas-cli_Windows_x86_64.zip -o "$HOME/tmas.zip"

# Extract (using PowerShell)
powershell -ExecutionPolicy Bypass -Command "Expand-Archive -Force -Path '$HOME/tmas.zip' -DestinationPath '$HOME/.local/bin'"

# Verify
"$HOME/.local/bin/tmas.exe" version
```

**2. Get a Vision One API Key**

1. Log in to [Trend Vision One](https://portal.xdr.trendmicro.com)
2. Go to **Administration** > **API Keys**
3. Create a new API key with **Cloud Security Operations** permissions
4. Copy the key

**3. Set Environment Variable**

**macOS/Linux:** Add to your shell profile (`~/.zshrc` or `~/.bashrc`):

```bash
export TMAS_API_KEY="your-api-key-here"
```

Then reload your shell:
```bash
source ~/.zshrc  # or ~/.bashrc
```

**Windows (Git Bash):**

```bash
# Persistent (future sessions)
setx TMAS_API_KEY "your-api-key-here"

# Current session
export TMAS_API_KEY="your-api-key-here"
```

## Usage

Once configured, use these commands:

| Command | Description |
|---------|-------------|
| `/trendai-setup` | Configure API key and install TMAS CLI |
| `/trendai-scan-tmas` | Scan code for vulnerabilities and secrets |
| `/trendai-scan-iac` | Scan Terraform/CloudFormation for misconfigurations |
| `/trendai-scan-llm` | Scan LLM endpoints for prompt injection |

### LLM Scanning

For `/trendai-scan-llm`, you need an additional environment variable:

```bash
# The API key for the LLM endpoint you're testing (not the Vision One key)
export TARGET_API_KEY="your-llm-endpoint-api-key"
```

**Features:**
- **Drift tracking** - Compares scans over time to show improvement/regression
- **Scan history** - Results saved to `.trendai-scans/` for trend analysis
- **Detailed reports** - JSON output with attack prompts and responses

### Regional Configuration

By default, the scanner uses the US region (`api.xdr.trendmicro.com`). For other regions, set:

```bash
export V1_REGION="api.eu.xdr.trendmicro.com"  # EU
export V1_REGION="api.au.xdr.trendmicro.com"  # Australia
export V1_REGION="api.in.xdr.trendmicro.com"  # India
export V1_REGION="api.jp.xdr.trendmicro.com"  # Japan
export V1_REGION="api.sg.xdr.trendmicro.com"  # Singapore
```

### What It Detects

- **Vulnerabilities** - CVEs in dependencies with CVSS scores and remediation
- **Secrets** - API keys, passwords, tokens, certificates
- **Malware** - Malicious code in container images
- **IaC Misconfigurations** - Security issues in Terraform/CloudFormation
- **LLM Vulnerabilities** - Prompt injection, jailbreaks, system prompt leakage

## Requirements

- [Claude Code CLI](https://claude.com/product/claude-code)
- [Trend Vision One account](https://www.trendmicro.com/en_us/business/products/vision-one.html)

## License

MIT
