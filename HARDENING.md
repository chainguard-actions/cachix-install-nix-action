# Hardening Report: cachix--install-nix-action/v31.10.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `ff50f15e4b79bfbf764dafdfd2579175a6ea9771`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **cachix--install-nix-action/v31.10.6** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

In install-nix.sh, the attacker-controlled input `inputs.nix_path` is passed via the `INPUT_NIX_PATH` environment variable (set from `${{ inputs.nix_path }}` in action.yml) and then written directly to `$GITHUB_ENV` without sanitization: `echo "NIX_PATH=${INPUT_NIX_PATH}" >> "$GITHUB_ENV"`. An attacker can supply a value containing newline characters to inject arbitrary key=value pairs into the GitHub Actions environment, potentially overwriting sensitive environment variables used by subsequent steps. The required sanitization step (`printf '%s' "$INPUT_NIX_PATH" | tr -d '\n\r'`) is absent before the write.

Locations:

- `install-nix.sh:121`
- `action.yml:33`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

Fixed github-env-injection vulnerability in install-nix.sh at line 121. The INPUT_NIX_PATH environment variable (derived from user-controlled input `inputs.nix_path`) was being written directly to $GITHUB_ENV without sanitization. Fixed by adding `safe_nix_path=$(printf '%s' "$INPUT_NIX_PATH" | tr -d '\n\r')` before the echo command, and using `$safe_nix_path` instead of `$INPUT_NIX_PATH` when writing to $GITHUB_ENV. This prevents newline injection attacks that could overwrite arbitrary environment variables in subsequent workflow steps.

