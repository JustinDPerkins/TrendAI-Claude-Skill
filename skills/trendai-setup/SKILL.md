---
name: trendai-setup
description: Set up the TrendAI Security Scanner by installing TMAS CLI and configuring the API key. Run this after installing the plugin.
allowed-tools: Bash
---

# TrendAI Setup Assistant

Help users set up the TrendAI Security Scanner by checking and installing prerequisites.

## Steps

### 1. Check if TMAS is installed

```bash
which tmas || ~/.local/bin/tmas version 2>/dev/null
```

### 2. If TMAS is not installed, install it

Detect the platform and install appropriately:

```bash
# Detect platform
OS=$(uname -s)
ARCH=$(uname -m)

# Install based on platform
if [ "$OS" = "Darwin" ] && [ "$ARCH" = "arm64" ]; then
    # macOS Apple Silicon
    mkdir -p ~/.local/bin
    curl -L https://cli.artifactscan.cloudone.trendmicro.com/tmas-cli/latest/tmas-cli_Darwin_arm64.zip -o /tmp/tmas.zip
    unzip -o /tmp/tmas.zip -d ~/.local/bin
    chmod +x ~/.local/bin/tmas
elif [ "$OS" = "Darwin" ] && [ "$ARCH" = "x86_64" ]; then
    # macOS Intel
    mkdir -p ~/.local/bin
    curl -L https://cli.artifactscan.cloudone.trendmicro.com/tmas-cli/latest/tmas-cli_Darwin_x86_64.zip -o /tmp/tmas.zip
    unzip -o /tmp/tmas.zip -d ~/.local/bin
    chmod +x ~/.local/bin/tmas
elif [ "$OS" = "Linux" ] && [ "$ARCH" = "x86_64" ]; then
    # Linux x86_64
    mkdir -p ~/.local/bin
    curl -L https://cli.artifactscan.cloudone.trendmicro.com/tmas-cli/latest/tmas-cli_Linux_x86_64.tar.gz -o /tmp/tmas.tar.gz
    tar -xzf /tmp/tmas.tar.gz -C ~/.local/bin
    chmod +x ~/.local/bin/tmas
elif [ "$OS" = "Linux" ] && [ "$ARCH" = "aarch64" ]; then
    # Linux ARM64
    mkdir -p ~/.local/bin
    curl -L https://cli.artifactscan.cloudone.trendmicro.com/tmas-cli/latest/tmas-cli_Linux_arm64.tar.gz -o /tmp/tmas.tar.gz
    tar -xzf /tmp/tmas.tar.gz -C ~/.local/bin
    chmod +x ~/.local/bin/tmas
fi
```

### 3. Check if API key is set

```bash
if [ -n "$TMAS_API_KEY" ]; then
    echo "TMAS_API_KEY is configured"
else
    echo "TMAS_API_KEY is NOT set"
fi
```

### 4. If API key is not set, guide the user

Tell them:

1. Log in to [Trend Vision One](https://portal.xdr.trendmicro.com)
2. Go to **Administration** > **API Keys**
3. Create a new API key with **Cloud Security Operations** permissions
4. Add to their shell profile:

```bash
export TMAS_API_KEY="your-api-key-here"
```

Then reload:
```bash
source ~/.zshrc  # or ~/.bashrc
```

### 5. Verify setup

Once both are configured, run a quick verification:

```bash
~/.local/bin/tmas version
```

## Success Message

When setup is complete, inform the user they can now use `/trendai-scan` to scan their code for security issues.
