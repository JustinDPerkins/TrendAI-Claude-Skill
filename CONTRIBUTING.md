# Contributing to TrendAI Claude Skill

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## Disclaimer

This is an unofficial community project and is not officially supported by Trend Micro. Contributions are welcome but should maintain compatibility with the TMAS CLI and Vision One APIs.

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Install the plugin for testing:
   ```bash
   claude plugin marketplace add . && claude plugin install trendai-security
   ```

## Project Structure

```
TrendAI-Claude-Skill/
├── .claude-plugin/
│   ├── marketplace.json    # Marketplace registration
│   └── plugin.json         # Plugin metadata
├── skills/
│   ├── trendai-setup/      # Setup wizard
│   ├── trendai-scan-tmas/  # Container/code scanning
│   ├── trendai-scan-iac/   # IaC scanning
│   └── trendai-scan-llm/   # LLM security testing
├── CLAUDE.md               # Claude Code instructions
├── README.md               # User documentation
└── CHANGELOG.md            # Version history
```

## Making Changes

### Skills

Each skill lives in `skills/<skill-name>/SKILL.md`. Skills use YAML frontmatter for metadata:

```yaml
---
name: skill-name
description: What the skill does
argument-hint: [optional-args]
allowed-tools: Bash, Read, Write, AskUserQuestion, Glob, Grep
---
```

### Guidelines

- **Keep skills focused** - Each skill should do one thing well
- **Auto-detect when possible** - Minimize user prompts in default mode
- **Provide advanced mode** - Use `--advanced` flag for interactive options
- **Handle errors gracefully** - Check prerequisites and provide helpful messages
- **Document troubleshooting** - Add common issues to the skill's troubleshooting section

### Testing

Before submitting:

1. Test the skill in Claude Code
2. Verify on your platform (macOS/Linux/Windows)
3. Check that prerequisites are validated
4. Ensure error messages are helpful

## Submitting Changes

1. Create a feature branch: `git checkout -b feature/my-feature`
2. Make your changes
3. Update CHANGELOG.md with your changes under `[Unreleased]`
4. Commit with a descriptive message
5. Push to your fork
6. Open a Pull Request

## Code of Conduct

Be respectful and constructive in all interactions. We're all here to make security scanning easier.

## Questions?

Open an issue on GitHub for questions or suggestions.
