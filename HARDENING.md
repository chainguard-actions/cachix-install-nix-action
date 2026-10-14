<!-- markdownlint-disable -->

# Hardening Report: cachix--install-nix-action/v31.11.2

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **cachix--install-nix-action/v31.11.2** was hardened automatically. 1 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

install-nix.sh writes untrusted input values to $GITHUB_ENV and $GITHUB_PATH without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`).

1. Line 113: `echo "NIX_PATH=${INPUT_NIX_PATH}" >> "$GITHUB_ENV"` — `INPUT_NIX_PATH` is set from `inputs.nix_path` (caller-controlled) in action.yml's env block and forwarded unsanitized into $GITHUB_ENV. A newline in the input value allows injecting arbitrary environment variables.

2. Line 131: `echo "NIX_PROFILES=/nix/var/nix/profiles/default $NIX_LINK" >> "$GITHUB_ENV"` — `NIX_LINK` is derived from the inherited env var `$NIX_STATE_HOME` (set by the calling workflow, treated as untrusted). Written to $GITHUB_ENV without sanitization.

3. Line 155: `echo "NIX_SSL_CERT_FILE=$NIX_LINK/etc/ssl/certs/ca-bundle.crt" >> "$GITHUB_ENV"` — same `NIX_LINK` / `$NIX_STATE_HOME` issue, written to $GITHUB_ENV without sanitization.

4. Line 161: `echo "$NIX_LINK/bin" >> "$GITHUB_PATH"` — `NIX_LINK` (derived from caller-controlled `$NIX_STATE_HOME`) written to $GITHUB_PATH without sanitization, allowing PATH injection.

All four writes must be preceded by `safe=$(printf '%s' "$VAR" | tr -d '\n\r')` before the echo.

Locations:

- `install-nix.sh:113`
- `install-nix.sh:131`
- `install-nix.sh:155`
- `install-nix.sh:161`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

Fixed all four github-env-injection findings in install-nix.sh:
1. Line 113: Added `safe_nix_path=$(printf '%s' "$INPUT_NIX_PATH" | tr -d '\n\r')` before writing NIX_PATH to $GITHUB_ENV.
2. Line 131: Added `safe_nix_link=$(printf '%s' "$NIX_LINK" | tr -d '\n\r')` before writing NIX_PROFILES to $GITHUB_ENV, using the sanitized value.
3. Line 155: Reused `safe_nix_link` when writing NIX_SSL_CERT_FILE to $GITHUB_ENV (the variable is in scope from fix 2).
4. Line 161: Reused `safe_nix_link` when writing the Nix bin path to $GITHUB_PATH.
All writes now use sanitized values that cannot contain newlines, preventing environment variable injection attacks.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Fixed install-nix.sh line 107: sanitized RUNNER_TEMP before writing to $GITHUB_ENV by adding `safe_runner_temp=$(printf '%s' "$RUNNER_TEMP" | tr -d '\n\r')` and using `${safe_runner_temp}` in the echo statement instead of the raw `${RUNNER_TEMP}`. This prevents newline injection attacks from a malicious calling workflow that sets RUNNER_TEMP to a value containing newlines.

