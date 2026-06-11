<!-- markdownlint-disable -->

# Hardening Report: cachix--install-nix-action/v31

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **cachix--install-nix-action/v31** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

In install-nix.sh, the variable INPUT_NIX_PATH (sourced from inputs.nix_path, a caller-controlled input set via action.yml's env: block) is written directly to $GITHUB_ENV without the required sanitization step (printf '%s' ... | tr -d '\n\r'). An attacker who controls the nix_path input can inject newline characters to define arbitrary additional environment variables for subsequent steps. The vulnerable line is: `echo "NIX_PATH=${INPUT_NIX_PATH}" >> "$GITHUB_ENV"`

Locations:

- `install-nix.sh:148`

### github-env-injection (severity: high)

In install-nix.sh, the variable NIX_LINK is derived from NIX_STATE_HOME (an inherited process env var that the calling workflow can set to any value). NIX_LINK is then written unsanitized to both $GITHUB_ENV and $GITHUB_PATH without the required sanitization step (printf '%s' ... | tr -d '\n\r'). This allows a calling workflow to inject newlines and define arbitrary environment variables or path entries. The vulnerable lines are: `echo "NIX_PROFILES=/nix/var/nix/profiles/default $NIX_LINK" >> "$GITHUB_ENV"`, `echo "NIX_SSL_CERT_FILE=$NIX_LINK/etc/ssl/certs/ca-bundle.crt" >> "$GITHUB_ENV"`, and `echo "$NIX_LINK/bin" >> "$GITHUB_PATH"`

Locations:

- `install-nix.sh:167`
- `install-nix.sh:195`
- `install-nix.sh:202`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

Fixed two github-env-injection vulnerabilities in install-nix.sh:
1. INPUT_NIX_PATH (line ~148): Added sanitization via `safe_nix_path=$(printf '%s' "$INPUT_NIX_PATH" | tr -d '\n\r')` before writing to $GITHUB_ENV.
2. NIX_LINK (lines ~167, ~195, ~202): Added a single sanitization step `NIX_LINK=$(printf '%s' "$NIX_LINK" | tr -d '\n\r')` immediately after NIX_LINK is assigned, covering all three downstream writes to $GITHUB_ENV and $GITHUB_PATH.

### Iteration 2

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Fixed two security findings in install-nix.sh:

1. github-env-injection (line 107): Added sanitization for RUNNER_TEMP before writing to $GITHUB_ENV. Added `safe_runner_temp=$(printf '%s' "$RUNNER_TEMP" | tr -d '\n\r')` and write `safe_runner_temp` to prevent newline injection.

2. script-injection (lines 9, 40, 60, 65, 76): Added double quotes around all unquoted workflow-controllable input variables in [[ ]] conditionals: $INPUT_ENABLE_KVM, $INPUT_SET_AS_TRUSTED_USER, $INPUT_EXTRA_NIX_CONFIG (×2), $INPUT_INSTALL_OPTIONS, and $OSTYPE where it appeared alongside input variables.

