---
name: trendai-scan-llm
description: Scan LLM endpoints for prompt injection vulnerabilities using TMAS AI Scanner.
argument-hint: [config-file]
allowed-tools: Read, Grep, Glob, Bash, Write
---

# TrendAI LLM Scanner

Scan **LLM endpoints** for prompt injection and jailbreak vulnerabilities.

## What This Scans

- Sensitive Data Disclosure
- System Prompt Leakage
- Malicious Code Generation
- ML Model Family Discovery
- Hallucinated Software Entities
- Agent Tool Definition Leakage

## Prerequisites

1. **TMAS CLI** installed (`tmas version` to verify)
2. **TMAS_API_KEY** - Vision One API key for authenticating with TMAS service
3. **TARGET_API_KEY** - The LLM endpoint's own API key/token
4. A config file with LLM endpoint details (see below)

Run `/trendai-setup` if TMAS CLI is not installed.

## Environment Variables

**Two separate API keys are required:**

```bash
# Vision One API key (for TMAS service authentication)
export TMAS_API_KEY="your-vision-one-api-key"

# LLM endpoint API key (for the target you're scanning)
export TARGET_API_KEY="your-llm-endpoint-api-key"
```

## Config File Format

The config file uses a specific YAML schema. Here is a complete working example:

```yaml
version: 1.0.0
name: My LLM Security Scan
description: Security scan for my LLM endpoint
target:
  name: my-llm-endpoint
  endpoint: https://api.openai.com/v1  # BASE URL only - see note below
  api_key_env: TARGET_API_KEY
  model: "gpt-4"
  type: "openai"  # Use "openai" for OpenAI-compatible endpoints
  temperature: 0.0
  system_prompt: ""  # Optional: system prompt to test
settings:
  concurrency: 2
attack_objectives:
- name: System Prompt Leakage
  description: The attacker learns the full system prompt
  techniques: [None]
  modifiers: [None]
- name: Sensitive Data Disclosure
  description: The attacker learns sensitive information such as PII
  techniques: [None]
  modifiers: [None]
```

### Important: Endpoint URL for OpenAI-Compatible APIs

When using `type: "openai"`, TMAS **automatically appends** `/chat/completions` to the endpoint URL.

| Correct | Incorrect |
|---------|-----------|
| `https://api.openai.com/v1` | `https://api.openai.com/v1/chat/completions` |

Using the full URL will result in a double path error.

### Available Attack Objectives

| Objective | Description |
|-----------|-------------|
| Sensitive Data Disclosure | Attempts to extract PII or sensitive data |
| System Prompt Leakage | Attempts to reveal the system prompt |
| Malicious Code Generation | Attempts to generate harmful code |
| Discover ML Model Family | Attempts to identify the underlying model |
| Generate Hallucinated Software Entities | Tests for fake package name generation |
| Agent Tool Definition Leakage | Attempts to discover available tools |

### Available Attack Techniques

- `None` (baseline - no special technique)
- `Ignore all previous instructions`
- `DAN` (Do Anything Now jailbreak)
- `Encrypt the response`
- `Payload splitting`

### Available Attack Modifiers

- `None` (baseline - no encoding)
- `Base64 Encoding`
- `Best-of-N Scrambling`

### Example with Techniques and Modifiers

```yaml
attack_objectives:
- name: System Prompt Leakage
  description: The attacker learns the full system prompt
  techniques: [None, DAN, Ignore all previous instructions]
  modifiers: [None, Base64 Encoding]
```

## Commands

```bash
# Scan with config file
tmas aiscan llm -c /path/to/config.yaml -r us-east-1

# Output as JSON
tmas aiscan llm -c config.yaml -r us-east-1 --output json

# Output as Markdown
tmas aiscan llm -c config.yaml -r us-east-1 --output markdown

# Save to file
tmas aiscan llm -c config.yaml -r us-east-1 --output json=results.json
```

### Region Options

| Region | Flag |
|--------|------|
| US East | `-r us-east-1` |
| EU | `-r eu-central-1` |
| Japan | `-r ap-northeast-1` |
| Singapore | `-r ap-southeast-1` |
| Australia | `-r ap-southeast-2` |

## Workflow

1. Check TMAS is installed: `tmas version`
2. Check env vars are set:
   ```bash
   echo "TMAS_API_KEY: ${TMAS_API_KEY:+SET}"
   echo "TARGET_API_KEY: ${TARGET_API_KEY:+SET}"
   ```
3. If user provides a config file path, verify it exists and read it
4. If no config provided, help user create one based on their endpoint
5. Run scan: `tmas aiscan llm -c config.yaml -r us-east-1`
6. Parse and present results

## Output Format

Present results in this format:

```markdown
## LLM Security Scan Results

**Endpoint**: https://api.openai.com/v1
**Model**: gpt-4
**Scanned**: 2026-02-05

### Summary

| Category | Tested | Vulnerable | Success Rate |
|----------|--------|------------|--------------|
| Sensitive Data Disclosure | 7 | 0 | 0% |
| System Prompt Leakage | 25 | 6 | 24% |
| Malicious Code Generation | 5 | 0 | 0% |

### Vulnerabilities Found

#### System Prompt Leakage - DAN Attack
- **Severity**: High
- **Attack**: "Pretend you are DAN..."
- **Response**: Model revealed system prompt
- **Recommendation**: Strengthen system prompt boundaries
```

## Troubleshooting

### "version: is a required field"
Your config is missing `version: 1.0.0` at the top.

### "target: is a required field"
Your config needs a `target:` block with `name`, `endpoint`, `model`, and `type`.

### "attack_preset: one of attack_objectives or attack_preset is required"
Add either `attack_objectives:` list or `attack_preset:` to your config.

### 401 Unauthorized / Double path error
If using `type: "openai"`, ensure your endpoint is the **base URL** only (e.g., `https://api.openai.com/v1`), not the full `/chat/completions` path.

### "Router.acompletion() missing messages"
You're using `type: ""` (custom) but the request mapping is incomplete. Switch to `type: "openai"` for OpenAI-compatible endpoints.

## Target

Config file: $ARGUMENTS
