---
name: trendai-setup
description: Set up the TrendAI Security Scanner - configure API key, region, and install TMAS CLI.
allowed-tools: Bash, AskUserQuestion
---

# TrendAI Setup Assistant

Configure the TrendAI Security Scanner with API credentials and install required tools.

## Setup Flow

### Step 1: Ask for Vision One API Key

Use AskUserQuestion to ask the user for their Vision One API token:

**Question**: "Enter your Vision One API Key"
**Header**: "API Key"
**Options**:
- "I have my API key ready" - User will paste it
- "I need to create one" - Guide them to Vision One console

If they need to create one, tell them:
1. Log in to [Trend Vision One](https://portal.xdr.trendmicro.com)
2. Go to **Administration** > **API Keys**
3. Create a new API key with these permissions:
   - **Cloud Security** > **Cloud Posture** (for IaC scanning)
   - **Artifact Security** (for TMAS vulnerability/secret scanning)
4. Copy the token

### Step 2: Ask for Vision One Region

Use AskUserQuestion to ask which region they use:

**Question**: "Which Vision One region are you using?"
**Header**: "Region"
**Options**:
- "US (api.xdr.trendmicro.com)"
- "EU (api.eu.xdr.trendmicro.com)"
- "Japan (api.xdr.trendmicro.co.jp)"
- "Singapore (api.sg.xdr.trendmicro.com)"

### Step 3: Save Configuration

After getting the API key and region, tell the user to add these to their shell profile (~/.zshrc or ~/.bashrc):

```bash
# TrendAI Security Scanner Configuration
export TMAS_API_KEY="<their-api-key>"
export V1_REGION="<their-region-endpoint>"
```

Then run:
```bash
source ~/.zshrc  # or ~/.bashrc
```

### Step 4: Install TMAS CLI

Check if TMAS is installed:

```bash
~/.local/bin/tmas version 2>/dev/null || echo "NOT_INSTALLED"
```

If not installed, run:

```bash
OS=$(uname -s)
ARCH=$(uname -m)
mkdir -p ~/.local/bin

if [ "$OS" = "Darwin" ] && [ "$ARCH" = "arm64" ]; then
    curl -L https://cli.artifactscan.cloudone.trendmicro.com/tmas-cli/latest/tmas-cli_Darwin_arm64.zip -o /tmp/tmas.zip
    unzip -o /tmp/tmas.zip -d ~/.local/bin
elif [ "$OS" = "Darwin" ] && [ "$ARCH" = "x86_64" ]; then
    curl -L https://cli.artifactscan.cloudone.trendmicro.com/tmas-cli/latest/tmas-cli_Darwin_x86_64.zip -o /tmp/tmas.zip
    unzip -o /tmp/tmas.zip -d ~/.local/bin
elif [ "$OS" = "Linux" ] && [ "$ARCH" = "x86_64" ]; then
    curl -L https://cli.artifactscan.cloudone.trendmicro.com/tmas-cli/latest/tmas-cli_Linux_x86_64.tar.gz -o /tmp/tmas.tar.gz
    tar -xzf /tmp/tmas.tar.gz -C ~/.local/bin
elif [ "$OS" = "Linux" ]; then
    curl -L https://cli.artifactscan.cloudone.trendmicro.com/tmas-cli/latest/tmas-cli_Linux_arm64.tar.gz -o /tmp/tmas.tar.gz
    tar -xzf /tmp/tmas.tar.gz -C ~/.local/bin
fi

chmod +x ~/.local/bin/tmas
~/.local/bin/tmas version
```

### Step 5: Verify Setup

Run verification:

```bash
echo "=== TrendAI Setup Verification ==="
echo ""
echo "TMAS CLI:"
~/.local/bin/tmas version 2>/dev/null && echo "OK" || echo "NOT INSTALLED"
echo ""
echo "API Key:"
[ -n "$TMAS_API_KEY" ] && echo "Configured (${#TMAS_API_KEY} chars)" || echo "NOT SET"
echo ""
echo "Region:"
echo "${V1_REGION:-api.xdr.trendmicro.com (default)}"
```

## Success Message

When setup is complete, tell the user:

**Setup Complete!** You can now use these commands:
- `/trendai-scan-tmas` - Scan for vulnerabilities and secrets
- `/trendai-scan-iac` - Scan Terraform/CloudFormation for misconfigs
- `/trendai-scan-llm` - Test LLM endpoints for prompt injection
