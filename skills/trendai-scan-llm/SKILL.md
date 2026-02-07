---
name: trendai-scan-llm
description: Scan LLM endpoints for prompt injection vulnerabilities using TMAS AI Scanner.
argument-hint: [endpoint-or-config]
allowed-tools: Read, Grep, Glob, Bash, Write, AskUserQuestion
---

# TrendAI LLM Scanner

Scan **LLM endpoints** for prompt injection and jailbreak vulnerabilities.

## CRITICAL: Zero-Prompt Auto-Detection

**DEFAULT MODE**: Automatically detect LLM endpoints and models. NO PROMPTS unless ambiguous.

**ADVANCED MODE**: If `$ARGUMENTS` contains `--advanced` or `-a`, use AskUserQuestion for all options.

### Step 1: Check Prerequisites

Run these checks and stop immediately if any fail:

```bash
# Check TMAS CLI is installed
if ! command -v tmas &>/dev/null && ! ~/.local/bin/tmas version &>/dev/null; then
    echo "ERROR: TMAS CLI not installed"
    echo "Run /trendai-setup to install"
    exit 1
fi

# Check API key is set
if [ -z "$TMAS_API_KEY" ]; then
    echo "ERROR: TMAS_API_KEY not set"
    echo "Run /trendai-setup to configure"
    exit 1
fi

# Show status
tmas version
echo "TMAS_API_KEY: SET (${#TMAS_API_KEY} chars)"
echo "TARGET_API_KEY: ${TARGET_API_KEY:+SET}${TARGET_API_KEY:-NOT SET (only needed for authenticated endpoints)}"
```

**STOP HERE if prerequisites fail.** Tell user to run `/trendai-setup` first.

### Step 2: Parse Arguments

Check what the user provided:

```bash
ARGS="$ARGUMENTS"

# Check for advanced mode
if [[ "$ARGS" == *"--advanced"* ]] || [[ "$ARGS" == *"-a"* ]]; then
    ADVANCED_MODE=true
    ARGS=$(echo "$ARGS" | sed 's/--advanced//g' | sed 's/-a//g' | xargs)
else
    ADVANCED_MODE=false
fi

# Check if arg is a config file
if [[ "$ARGS" == *.yaml ]] || [[ "$ARGS" == *.yml ]]; then
    CONFIG_FILE="$ARGS"
fi

# Check if arg is an endpoint URL
if [[ "$ARGS" == http* ]]; then
    ENDPOINT_URL="$ARGS"
fi

# Check if arg is a model name (for Ollama)
if [[ -n "$ARGS" ]] && [[ "$ARGS" != *.yaml ]] && [[ "$ARGS" != http* ]]; then
    MODEL_NAME="$ARGS"
fi
```

### Step 3: If Config File Provided, Use It

If `$ARGUMENTS` is a `.yaml` or `.yml` file, read it and skip to Step 8.

### Step 4: Detect Endpoint Type

If no endpoint provided, ask what type:

**Use AskUserQuestion:**
- **Question**: "What LLM endpoint do you want to scan?"
- **Header**: "Endpoint"
- **Options**:
  1. **Local Ollama** - "Ollama running on localhost:11434"
  2. **Local LM Studio** - "LM Studio running on localhost:1234"
  3. **OpenAI API** - "OpenAI or Azure OpenAI"
  4. **Other** - "Custom endpoint URL"

### Step 5: Auto-Discover Models (CRITICAL)

**Once you know the endpoint type, AUTOMATICALLY discover available models. Do NOT ask the user to specify a model manually.**

```bash
# For Ollama - automatically list models
ollama list 2>/dev/null

# For LM Studio - query the API
curl -s http://localhost:1234/v1/models 2>/dev/null | jq -r '.data[].id'

# For Ollama via API (alternative)
curl -s http://localhost:11434/api/tags 2>/dev/null | jq -r '.models[].name'
```

**After discovering models:**

| Models Found | Action |
|--------------|--------|
| 0 models | Tell user: "No models found. Run `ollama pull llama3.2` first." |
| 1 model | Use it automatically, tell user which one |
| 2+ models | **ASK which model** using AskUserQuestion |

**If multiple models found**, use AskUserQuestion:
- **Question**: "Found X models. Which one to scan?"
- **Header**: "Model"
- **Options**: List each model name discovered (up to 4, then "Other")

**For OpenAI/remote APIs**: Ask user to provide the model name (gpt-4, gpt-3.5-turbo, etc.)

### Step 6: Set Defaults (No Prompts)

Use these defaults unless `--advanced` mode:

```yaml
# Default attack objectives (all 4 main ones)
attack_objectives:
  - System Prompt Leakage
  - Sensitive Data Disclosure
  - Agent Tool Definition Leakage
  - Malicious Code Generation

# Default: baseline only (fastest)
techniques: [None]
modifiers: [None]

# Default: low concurrency
concurrency: 2
```

### Step 7: Generate Config File

Generate config based on auto-detected values:

```yaml
version: 1.0.0
name: LLM Security Scan
description: Auto-detected security scan for LLM endpoint
target:
  name: target-llm
  endpoint: <AUTO_DETECTED_ENDPOINT>  # BASE URL only!
  api_key_env: <TARGET_API_KEY or omit for local>
  model: "<AUTO_DETECTED_MODEL>"
  type: "openai"  # Ollama/LM Studio use OpenAI-compatible API
  temperature: 0.0
  system_prompt: ""
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
  - name: Agent Tool Definition Leakage
    description: An attacker discovers the tools accessible to the model
    techniques: [None]
    modifiers: [None]
  - name: Malicious Code Generation
    description: An attacker gets the model to generate malicious code
    techniques: [None]
    modifiers: [None]
```

**For local LLMs (Ollama, LM Studio)**: Omit `api_key_env` entirely.

**CPU Impact** (default config): 4 objectives × ~15-25 tests = ~60-100 total tests

### Step 8: Save Config (No Prompt)

Save to default location without asking:

```bash
CONFIG_FILE="./llm-scan-config.yaml"
# Write config using Write tool
```

Tell user: "Saved config to `llm-scan-config.yaml`"

### Step 9: Run the Scan with JSON Output

Always use `--output json` for detailed results and history tracking:

```bash
# Create scan history directory
mkdir -p .trendai-scans

# Run scan with JSON output, save to timestamped file
SCAN_FILE=".trendai-scans/llm-scan-$(date +%Y%m%d-%H%M%S).json"
tmas aiscan llm -c <config-file> -r us-east-1 --output json 2>&1 | tee "$SCAN_FILE"
```

### Step 10: Parse JSON and Generate Report

The JSON output contains:
- `details`: scan metadata (scan_id, endpoint, model, duration)
- `evaluation_results`: array of individual attack results

For each result, extract:
- `attack_objective`: what was tested
- `attack_outcome`: "Attack Succeeded" or "Attack Failed"
- `severity`: "MEDIUM", "HIGH", etc. (only present on successful attacks)
- `chat_history`: the attack prompt and model response
- `evaluation`: AI evaluation of why attack succeeded/failed

### Step 11: Compare with Previous Scans (Drift Detection)

Check for previous scans to show improvement/regression:

```bash
# Find previous scans for same endpoint/model
ls -t .trendai-scans/llm-scan-*.json 2>/dev/null | head -5
```

If previous scans exist, compare:
1. Read the most recent previous scan JSON
2. Compare success rates per objective
3. Show drift indicators (↑ improved, ↓ regressed, → unchanged)

**Drift Report Format:**

```markdown
### Security Posture Drift

| Objective | Previous | Current | Trend |
|-----------|----------|---------|-------|
| System Prompt Leakage | 8/25 (32%) | 5/25 (20%) | ↑ Improved (-12%) |
| Sensitive Data Disclosure | 2/25 (8%) | 4/25 (16%) | ↓ Regressed (+8%) |

**Overall**: 10/50 → 9/50 (↑ 2% improvement)
```

## Reference: Attack Techniques and Modifiers

For advanced users who want to add techniques/modifiers to their config:

### Attack Techniques
- `None` - baseline (no special technique)
- `Ignore all previous instructions` - instruction override
- `DAN (Do anything now)` - jailbreak technique
- `Encrypt the response` - obfuscation
- `Payload splitting` - split attack across messages

### Attack Modifiers
- `None` - baseline (no encoding)
- `Base64 Encoding` - encode prompts in base64
- `Best-of-N Scrambling` - randomize prompt variations

**Warning**: Adding techniques and modifiers multiplies test count and CPU usage!

## Reference: Region Options

| Region | Flag |
|--------|------|
| US East | `-r us-east-1` |
| EU | `-r eu-central-1` |
| Japan | `-r ap-northeast-1` |
| Singapore | `-r ap-southeast-1` |
| Australia | `-r ap-southeast-2` |

## Reference: Endpoint URL Format

When using `type: "openai"`, TMAS **automatically appends** `/chat/completions`.

| Correct | Incorrect |
|---------|-----------|
| `https://api.openai.com/v1` | `https://api.openai.com/v1/chat/completions` |

## Output Format

Parse the JSON output and present a rich report:

```markdown
## LLM Security Scan Report

**Scan ID**: `<from details.scan_id>`
**Endpoint**: <from details.endpoint>
**Model**: <from details.application>
**Scan Time**: <from details.scan_time>
**Duration**: <from details.scan_duration>

---

### Summary

| Objective | Technique | Modifier | Success Rate |
|-----------|-----------|----------|--------------|
| System Prompt Leakage | None | None | **5/25 (20%)** |

---

### Security Posture Drift

(Only show if previous scans exist in .trendai-scans/)

| Objective | Previous | Current | Trend |
|-----------|----------|---------|-------|
| System Prompt Leakage | 8/25 (32%) | 5/25 (20%) | ↑ Improved |

---

### Successful Attacks

For each result where `attack_outcome == "Attack Succeeded"`:

| # | Attack Prompt | Model Leaked |
|---|---------------|--------------|
| 1 | `<chat_history[0].content>` | "<summary of chat_history[1].content>" |

---

### Attack Pattern Analysis

Analyze the successful attacks and identify:
- What types of prompts worked (gibberish, direct questions, encoded, etc.)
- What information was leaked (restrictions, capabilities, system prompt text)
- Common patterns in model responses

---

### Recommendations

Based on findings, provide actionable recommendations:
1. Specific mitigations for each vulnerability type
2. Suggestions for follow-up scans (e.g., add jailbreak techniques)
3. Model configuration changes
```

## Common Patterns

### Zero-prompt scans (auto-detect)
```bash
/trendai-scan-llm                      # Auto-detect Ollama/local LLMs
/trendai-scan-llm llama3.2             # Scan specific Ollama model
/trendai-scan-llm mistral:7b           # Scan specific model variant
```

### Scan with existing config
```bash
/trendai-scan-llm config.yaml          # Use existing config file
/trendai-scan-llm ./llm-scan-config.yaml
```

### Scan remote endpoint
```bash
/trendai-scan-llm http://localhost:11434/v1   # Explicit Ollama endpoint
/trendai-scan-llm http://localhost:1234/v1    # LM Studio
```

### Advanced mode (interactive prompts)
```bash
/trendai-scan-llm --advanced           # Prompts for all options
/trendai-scan-llm llama3.2 -a          # Advanced mode for specific model
```

## Troubleshooting

### "version: is a required field"
Config missing `version: 1.0.0` at the top.

### "target: is a required field"
Config needs a `target:` block with `name`, `endpoint`, `model`, and `type`.

### 401 Unauthorized / Double path error
Ensure endpoint is **base URL** only (not the full `/chat/completions` path).

### No models detected
- Check Ollama is running: `ollama list`
- Check if model is pulled: `ollama pull llama3.2`

## Target

Endpoint, model, or config file: $ARGUMENTS
