# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-02-06

### Added
- `/trendai-setup` - Guided setup wizard for API key configuration and TMAS CLI installation
- `/trendai-scan-tmas` - Container image and code scanning for vulnerabilities, secrets, and malware
- `/trendai-scan-iac` - Terraform and CloudFormation security misconfiguration scanning
- `/trendai-scan-llm` - LLM endpoint security testing for prompt injection vulnerabilities
- Multi-platform support (macOS, Linux, Windows via Git Bash)
- Regional Vision One support (US, EU, Japan, Singapore, Australia, India)
- Zero-prompt auto-detection mode for faster workflows
- Advanced mode (`--advanced` / `-a`) for interactive configuration
- Drift tracking with scan history saved to `.trendai-scans/`
- JSON output for detailed scan results and programmatic parsing
