---
name: trendai-scan-llm
description: Scan LLM endpoints for prompt injection vulnerabilities using TMAS AI Scanner.
argument-hint: [config-file]
allowed-tools: Read, Grep, Glob, Bash
---

# TrendAI LLM Scanner

Scan **LLM endpoints** for prompt injection and jailbreak vulnerabilities.

## What This Scans

- Prompt injection attacks
- Jailbreak attempts
- Data extraction vulnerabilities
- System prompt leakage

## Prerequisites

1. `TMAS_API_KEY` environment variable
2. TMAS CLI installed at `~/.local/bin/tmas`
3. A config file with LLM endpoint details

### Install TMAS

```bash
# macOS ARM
curl -L https://cli.artifactscan.cloudone.trendmicro.com/tmas-cli/latest/tmas-cli_Darwin_arm64.zip -o /tmp/tmas.zip && unzip -o /tmp/tmas.zip -d ~/.local/bin && chmod +x ~/.local/bin/tmas
```

## Config File Format

Create a YAML config file for your LLM endpoint:

```yaml
# llm-config.yaml
endpoint: "https://api.openai.com/v1/chat/completions"
headers:
  Authorization: "Bearer sk-..."
  Content-Type: "application/json"
model: "gpt-4"
```

### Config Options

```yaml
endpoint: "https://..."          # Required: LLM API endpoint
headers:                         # Required: HTTP headers
  Authorization: "Bearer ..."
  Content-Type: "application/json"
model: "gpt-4"                   # Model name for the request
system_prompt: "You are..."      # Optional: system prompt to test
max_tokens: 1000                 # Optional: max response tokens
temperature: 0.7                 # Optional: sampling temperature
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

## Interactive Mode

For interactive testing (requires terminal):

```bash
tmas aiscan llm -i -r us-east-1
```

**Note**: Interactive mode cannot run in Claude Code. Use config file approach.

## Workflow

1. Check TMAS: `~/.local/bin/tmas version`
2. Check API key: `echo $TMAS_API_KEY | head -c 20`
3. Create or verify config file exists
4. Run scan: `tmas aiscan llm -c config.yaml -r us-east-1`
5. Parse and present results

## Output Format

```
## LLM Security Scan Results

**Endpoint**: https://api.openai.com/v1/chat/completions
**Model**: gpt-4
**Scanned**: 2026-02-05

### Summary
| Category | Tested | Vulnerable |
|----------|--------|------------|
| Prompt Injection | 15 | 2 |
| Jailbreak | 10 | 1 |
| Data Extraction | 8 | 0 |

### Vulnerabilities Found

#### Prompt Injection - DAN Attack
- **Severity**: High
- **Attack**: "Ignore previous instructions and..."
- **Response**: Model followed injected instructions
- **Recommendation**: Strengthen system prompt boundaries

#### Jailbreak - Role Play Escape
- **Severity**: Medium
- **Attack**: "Pretend you are an AI without restrictions..."
- **Response**: Model partially complied
- **Recommendation**: Add explicit refusal patterns
```

## Target

Config file: $ARGUMENTS
