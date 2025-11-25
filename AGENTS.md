# AGENTS.md - Smart Execute Development Guide

## Build/Test Commands

### Testing
- **Run all tests**: `./test.sh` or `./test.sh full`
- **Basic tests only**: `./test.sh basic`
- **Performance tests**: `./test.sh performance`
- **Interactive test mode**: `./test.sh interactive`
- **Single test function**: Use `test_assert`, `test_function_exists`, or `test_file_exists` helpers in test.sh

### Installation
- **Install**: `./install.sh`
- **Manual setup**: Source `smart_execute_v2.zsh` in shell rc file

## Code Style Guidelines

### Shell Scripting (Zsh)
- Use `#!/bin/zsh` shebang for all Zsh scripts
- Function naming: `_private_function()` for internal, `public_function()` for API
- Global variables: Use `typeset -g` for global scope
- Error handling: Use `set -e` in install scripts, check command existence with `command -v`
- Logging: Use `_smart_log()` function for consistent logging format

### Security Patterns
- Always validate input with `_sanitize_input()` before processing
- Use `_is_blacklisted()` and `_is_whitelisted()` for command filtering
- Implement risk assessment with `_assess_risk()` for command execution
- Audit all operations with `_audit_log()`

### Module Structure
- Core functionality in `smart_execute_v2.zsh`
- Security module: `.smart_execute_security.zsh`
- Provider integrations: `.smart_execute_providers.zsh`
- Cross-shell support: `.smart_execute_cross_shell.zsh`
- Configuration wizard: `.smart_execute_wizard.zsh`

### JSON Handling
- Use `jq` for JSON parsing instead of shell built-ins
- Validate JSON responses with `_parse_json_safely()`
- Handle API errors gracefully with fallback mechanisms

### Testing Patterns
- Use helper functions: `test_assert()`, `test_function_exists()`, `test_file_exists()`
- Test both positive and negative cases
- Include security tests for blacklist/whitelist functionality
- Performance tests should measure execution time in milliseconds

### Configuration
- Store config in `~/.config/smart_execute/`
- Use environment variables for overrides (`SMART_EXECUTE_CONFIG_DIR`)
- Security settings in `.smart_execute_security.conf`
- Blacklist patterns in `.smart_execute_advanced_blacklist.txt`