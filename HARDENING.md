<!-- markdownlint-disable -->

# Hardening Report: cachix--install-nix-action/v31.11.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **cachix--install-nix-action/v31.11.1** was hardened automatically. 4 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

install-nix.sh writes the user-controlled input `INPUT_NIX_PATH` (sourced from `inputs.nix_path`) directly to `$GITHUB_ENV` without sanitization. An attacker can supply a value containing newlines to inject arbitrary environment variables into subsequent steps. The required sanitization step (`printf '%s' "$VAR" | tr -d '\n\r'`) is absent before the write: `echo "NIX_PATH=${INPUT_NIX_PATH}" >> "$GITHUB_ENV"`

Locations:

- `install-nix.sh:118`

### github-env-injection (severity: high)

install-nix.sh writes `NIX_LINK` to `$GITHUB_ENV` (as part of `NIX_PROFILES`) without sanitization. `NIX_LINK` is derived from `NIX_STATE_HOME`, an inherited process environment variable that the calling workflow controls. A malicious caller can set `NIX_STATE_HOME` to a value containing newlines, injecting arbitrary environment variables. The write `echo "NIX_PROFILES=/nix/var/nix/profiles/default $NIX_LINK" >> "$GITHUB_ENV"` lacks the required `printf '%s' ... | tr -d '\n\r'` sanitization.

Locations:

- `install-nix.sh:143`

### github-env-injection (severity: high)

install-nix.sh writes `NIX_LINK` (derived from the workflow-controlled `NIX_STATE_HOME` env var) into `$GITHUB_ENV` as part of `NIX_SSL_CERT_FILE` without sanitization: `echo "NIX_SSL_CERT_FILE=$NIX_LINK/etc/ssl/certs/ca-bundle.crt" >> "$GITHUB_ENV"`. A newline embedded in `NIX_STATE_HOME` would allow injection of arbitrary environment variables into subsequent steps.

Locations:

- `install-nix.sh:163`

### github-env-injection (severity: high)

install-nix.sh writes `NIX_LINK` (derived from the workflow-controlled `NIX_STATE_HOME` env var) directly to `$GITHUB_PATH` without sanitization: `echo "$NIX_LINK/bin" >> "$GITHUB_PATH"`. A newline embedded in `NIX_STATE_HOME` would allow injection of arbitrary entries into the PATH of subsequent steps. The required sanitization step (`printf '%s' ... | tr -d '\n\r'`) is absent.

Locations:

- `install-nix.sh:171`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

Fixed all four github-env-injection findings in hardened/action/install-nix.sh:
1. Line 118: Added `safe_nix_path=$(printf '%s' "$INPUT_NIX_PATH" | tr -d '\n\r')` and used `safe_nix_path` when writing NIX_PATH to $GITHUB_ENV.
2. Lines 143, 163, 171: Added a single sanitization of NIX_LINK immediately after it is assigned — `NIX_LINK=$(printf '%s' "$NIX_LINK" | tr -d '\n\r')` — which covers all three downstream writes (NIX_PROFILES to GITHUB_ENV, NIX_SSL_CERT_FILE to GITHUB_ENV, and the bin path to GITHUB_PATH).

