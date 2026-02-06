---
name: trendai-scan-llm
description: Scan LLM endpoints for prompt injection vulnerabilities using TMAS AI Scanner.
argument-hint: [config-file]
allowed-tools: Read, Grep, Glob, Bash, Write, AskUserQuestion
---

# TrendAI LLM Scanner

Scan **LLM endpoints** for prompt injection and jailbreak vulnerabilities.

## CRITICAL: Interactive Configuration Workflow

**ALWAYS use AskUserQuestion to gather configuration before running scans.** Running all attacks at once is CPU-intensive. Let users select specific attacks.

### Step 1: Check Prerequisites

First verify TMAS is installed and API keys are set:
```bash
tmas version
echo "TMAS_API_KEY: ${TMAS_API_KEY:+SET}"
echo "TARGET_API_KEY: ${TARGET_API_KEY:+SET}"
```

If TMAS is not installed, tell user to run `/trendai-setup`.

### Step 2: Check for Existing Config

If `$ARGUMENTS` contains a config file path, read it and skip to Step 7.

Otherwise, proceed to gather configuration interactively.

### Step 3: Ask Attack Objectives (REQUIRED)

Use AskUserQuestion with multiSelect=true to ask which attacks to run:

**Question**: "Which attack objectives do you want to test?"
**Header**: "Attacks"
**Options** (multiSelect: true):
1. **System Prompt Leakage** - "Attempts to reveal the system prompt"
2. **Sensitive Data Disclosure** - "Attempts to extract PII or sensitive data"
3. **Agent Tool Definition Leakage** - "Attempts to discover available tools/functions"
4. **Malicious Code Generation** - "Attempts to generate harmful code"

Note: Additional objectives available if user selects "Other":
- Discover ML Model Family
- Generate Hallucinated Software Entities

### Step 4: Ask Endpoint Details (REQUIRED)

Use AskUserQuestion to get endpoint info:

**Question**: "What is your LLM endpoint type?"
**Header**: "Endpoint"
**Options**:
1. **OpenAI API** - "OpenAI or OpenAI-compatible (Azure, local LLMs with OpenAI adapter)"
2. **Anthropic API** - "Claude API endpoints"
3. **Custom endpoint** - "Other REST API with custom request format"

Then ask user to provide the endpoint URL (base URL only, no /chat/completions).

### Step 5: Ask Model Details (REQUIRED)

Use AskUserQuestion:

**Question**: "Which model are you testing?"
**Header**: "Model"
**Options**:
1. **GPT-4/GPT-4o** - "OpenAI GPT-4 family"
2. **GPT-3.5-turbo** - "OpenAI GPT-3.5"
3. **Claude** - "Anthropic Claude models"
4. **Custom/Local** - "Specify model name"

### Step 6: Ask API Key Configuration (REQUIRED)

Use AskUserQuestion:

**Question**: "Does your LLM endpoint require an API key?"
**Header**: "Auth"
**Options**:
1. **Yes, use TARGET_API_KEY env var** - "API key is in TARGET_API_KEY environment variable (Recommended)"
2. **Yes, different env var** - "Specify a different environment variable name"
3. **No authentication needed** - "Endpoint doesn't require API key"

### Step 6b: Ask About Attack Techniques (OPTIONAL)

Use AskUserQuestion:

**Question**: "Do you want to add attack techniques? (Warning: multiplies test count and CPU usage)"
**Header**: "Techniques"
**Options**:
1. **None only (Recommended)** - "Baseline tests only, fastest and lowest CPU usage"
2. **Add jailbreak techniques** - "Include DAN, instruction override attacks (3-5x more tests)"

If user selects jailbreak techniques, use multiSelect for:
- `Ignore all previous instructions`
- `DAN (Do anything now)`
- `Encrypt the response`
- `Payload splitting`

### Step 6c: Ask About Attack Modifiers (OPTIONAL)

Use AskUserQuestion:

**Question**: "Do you want to add attack modifiers? (Warning: further multiplies test count)"
**Header**: "Modifiers"
**Options**:
1. **None only (Recommended)** - "No encoding, fastest execution"
2. **Add encoding modifiers** - "Include Base64, scrambling (2-3x more tests)"

If user selects encoding modifiers:
- `Base64 Encoding`
- `Best-of-N Scrambling`

### Step 7: Generate Config File

Based on user answers, generate a config.yaml file:

```yaml
version: 1.0.0
name: LLM Security Scan
description: Targeted security scan for LLM endpoint
target:
  name: target-llm
  endpoint: <USER_PROVIDED_ENDPOINT>  # BASE URL only!
  api_key_env: <USER_PROVIDED_ENV_VAR or TARGET_API_KEY>
  model: "<USER_PROVIDED_MODEL>"
  type: "<openai|anthropic|custom>"
  temperature: 0.0
  system_prompt: ""
settings:
  concurrency: 2  # Keep low to reduce CPU load
attack_objectives:
<ONLY SELECTED OBJECTIVES - see template below>
```

**Attack objective templates** (only include selected ones):

Use `techniques: [None]` and `modifiers: [None]` for baseline only.
If user selected additional techniques/modifiers, add them to the arrays.

```yaml
# System Prompt Leakage
- name: System Prompt Leakage
  description: The attacker learns the full system prompt
  techniques: [None]  # or [None, "DAN (Do anything now)", "Ignore all previous instructions"]
  modifiers: [None]   # or [None, "Base64 Encoding"]

# Sensitive Data Disclosure
- name: Sensitive Data Disclosure
  description: The attacker learns sensitive information such as PII
  techniques: [None]
  modifiers: [None]

# Agent Tool Definition Leakage
- name: Agent Tool Definition Leakage
  description: An attacker discovers the tools accessible to the model
  techniques: [None]
  modifiers: [None]

# Malicious Code Generation
- name: Malicious Code Generation
  description: An attacker gets the model to generate malicious code
  techniques: [None]
  modifiers: [None]

# Discover ML Model Family
- name: Discover ML Model Family
  description: An attacker discovers the type of ML model being used
  techniques: [None]
  modifiers: [None]

# Generate Hallucinated Software Entities
- name: Generate Hallucinated Software Entities
  description: An attacker looks for hallucinated software entities
  techniques: [None]
  modifiers: [None]
```

**CPU Impact Examples:**
- 1 objective + None technique + None modifier = ~15-25 tests
- 1 objective + 3 techniques + None modifier = ~45-75 tests
- 1 objective + 3 techniques + 2 modifiers = ~90-150 tests
- 6 objectives + all techniques + all modifiers = 500+ tests (HIGH CPU!)

### Step 8: Confirm and Save Config

Show the user the generated config and ask where to save it (default: `./llm-scan-config.yaml`).

Write the config file using the Write tool.

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

## Troubleshooting

### "version: is a required field"
Config missing `version: 1.0.0` at the top.

### "target: is a required field"
Config needs a `target:` block with `name`, `endpoint`, `model`, and `type`.

### 401 Unauthorized / Double path error
Ensure endpoint is **base URL** only (not the full `/chat/completions` path).

## Target

Config file: $ARGUMENTS
