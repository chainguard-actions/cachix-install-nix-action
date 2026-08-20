<!-- markdownlint-disable -->

# Hardening Report: cachix--install-nix-action/v31

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **cachix--install-nix-action/v31** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

install-nix.sh writes the user-controlled input `INPUT_NIX_PATH` (sourced from `inputs.nix_path`) directly to `$GITHUB_ENV` without sanitization. An attacker can inject newlines into this value to set arbitrary environment variables for subsequent steps. The required sanitization step (`printf '%s' "$VAR" | tr -d '\n\r'`) is absent.

Offending line:
  echo "NIX_PATH=${INPUT_NIX_PATH}" >> "$GITHUB_ENV"

Locations:

- `install-nix.sh:129`

### github-env-injection (severity: high)

install-nix.sh writes `NIX_LINK` to `$GITHUB_ENV` (as part of `NIX_PROFILES`) without sanitization. `NIX_LINK` is derived from `NIX_STATE_HOME`, an inherited process environment variable that is fully controlled by the calling workflow. A calling workflow can set `NIX_STATE_HOME` to a value containing newlines, injecting arbitrary environment variables into `$GITHUB_ENV`.

Offending line:
  echo "NIX_PROFILES=/nix/var/nix/profiles/default $NIX_LINK" >> "$GITHUB_ENV"

Locations:

- `install-nix.sh:152`

### github-env-injection (severity: high)

install-nix.sh writes `$NIX_LINK/bin` to `$GITHUB_PATH` without sanitization. `NIX_LINK` is derived from `NIX_STATE_HOME`, an inherited process environment variable controlled by the calling workflow. A calling workflow can set `NIX_STATE_HOME` to a value containing newlines, injecting arbitrary entries into `$GITHUB_PATH` and enabling path-hijacking attacks.

Offending line:
  echo "$NIX_LINK/bin" >> "$GITHUB_PATH"

Locations:

- `install-nix.sh:185`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

Fixed all three github-env-injection findings in install-nix.sh:
1. Line 129 (INPUT_NIX_PATH → GITHUB_ENV): Added `safe_nix_path=$(printf '%s' "$INPUT_NIX_PATH" | tr -d '\n\r')` and used `safe_nix_path` in the echo.
2. Lines 152 & 185 (NIX_LINK → GITHUB_ENV and GITHUB_PATH): Added a single sanitization step `NIX_LINK=$(printf '%s' "$NIX_LINK" | tr -d '\n\r')` immediately after NIX_LINK is set, so all downstream uses of NIX_LINK are already clean.

