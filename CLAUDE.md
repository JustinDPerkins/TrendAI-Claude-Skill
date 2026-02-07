# TrendAI Claude Skill

Claude Code plugin for security scanning using Trend Micro TMAS.

## Skills

| Skill | Description |
|-------|-------------|
| `/trendai-scan-llm` | Scan LLM endpoints for prompt injection vulnerabilities |
| `/trendai-scan-tmas` | Scan code for vulnerabilities and secrets |
| `/trendai-scan-iac` | Scan Terraform/CloudFormation for misconfigurations |
| `/trendai-setup` | Configure API keys and install TMAS CLI |

## Prerequisites

- **TMAS CLI**: `tmas version` (install via `/trendai-setup`)
- **TMAS_API_KEY**: Vision One API token (set in environment)
- **TARGET_API_KEY**: For authenticated LLM endpoints (optional)

## Development

After cloning, the plugin can be installed locally:

```bash
claude plugin marketplace add . && claude plugin install trendai-security
```

Plugin locations after installation:
- **Installed**: `~/.claude/plugins/marketplaces/<marketplace>/plugins/trendai-security/`
- **Cache**: `~/.claude/plugins/cache/<marketplace>/trendai-security/<version>/`
