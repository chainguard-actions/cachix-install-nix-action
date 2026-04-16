# Hardening Report: cachix--install-nix-action/v31

> This file was generated automatically by the hardening agent.

**Policy SHA:** `c40cfe5fa14e08549b1b988e7e5a26da4816abf0`

**Test Policy SHA:** `f2e7d85641cde4267138117189b8eba7ba2bfbde`

Action **cachix--install-nix-action/v31** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

In install-nix.sh, the attacker-controlled input `inputs.nix_path` is mapped to the environment variable `INPUT_NIX_PATH` in action.yml and then written directly to `$GITHUB_ENV` without sanitization: `echo "NIX_PATH=${INPUT_NIX_PATH}" >> "$GITHUB_ENV"`. An attacker can supply a `nix_path` value containing embedded newlines (e.g. `\nFOO=injected`) to inject arbitrary key=value pairs into the runner's environment for subsequent steps. The required sanitization step — `printf '%s' "$INPUT_NIX_PATH" | tr -d '\n\r'` — is absent before the write.

Locations:

- `install-nix.sh:107`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

Fixed github-env-injection in hardened/cachix--install-nix-action/v31/install-nix.sh at line 107. The attacker-controlled INPUT_NIX_PATH value is now sanitized with `printf '%s' "$INPUT_NIX_PATH" | tr -d '\n\r'` before being written to $GITHUB_ENV, preventing newline injection attacks that could inject arbitrary environment variables into subsequent workflow steps.

