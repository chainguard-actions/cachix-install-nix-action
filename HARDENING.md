# Hardening Report: cachix--install-nix-action/v31.10.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `ff50f15e4b79bfbf764dafdfd2579175a6ea9771`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **cachix--install-nix-action/v31.10.6** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

In install-nix.sh, the attacker-controlled input INPUT_NIX_PATH (mapped from inputs.nix_path via action.yml env:) is written directly to $GITHUB_ENV without sanitization. An attacker can supply a value containing newline characters to inject arbitrary environment variable assignments for subsequent workflow steps. The required sanitization step (printf '%s' "$INPUT_NIX_PATH" | tr -d '\n\r') is absent before the write: `echo "NIX_PATH=${INPUT_NIX_PATH}" >> "$GITHUB_ENV"`

Locations:

- `install-nix.sh:130`
- `action.yml:36`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

Fixed github-env-injection in install-nix.sh at line 130. The INPUT_NIX_PATH value (mapped from inputs.nix_path in action.yml) was being written directly to $GITHUB_ENV without sanitization. Added a sanitization step using `safe_nix_path=$(printf '%s' "$INPUT_NIX_PATH" | tr -d '\n\r')` before the write, and updated the echo statement to use the sanitized variable instead of the raw INPUT_NIX_PATH.

