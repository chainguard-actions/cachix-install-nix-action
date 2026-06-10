<!-- markdownlint-disable -->

# Hardening Report: cachix--install-nix-action/v31.10.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **cachix--install-nix-action/v31.10.6** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

In install-nix.sh, the variable INPUT_NIX_PATH (populated from inputs.nix_path — a workflow-controlled input set via the env: block in action.yml) is written directly to $GITHUB_ENV without the required sanitization step (printf '%s' "$VAR" | tr -d '\n\r'). An attacker controlling the nix_path input can inject arbitrary environment variable definitions into subsequent steps by embedding newlines in the value.

Offending line:
  echo "NIX_PATH=${INPUT_NIX_PATH}" >> "$GITHUB_ENV"

Locations:

- `install-nix.sh:148`

### github-env-injection (severity: high)

In install-nix.sh, the variable NIX_LINK is derived from $NIX_STATE_HOME — an inherited process environment variable that is not set by this script and is therefore controlled by the calling workflow. When $NIX_STATE_HOME is non-empty, NIX_LINK is set to "$NIX_STATE_HOME/profile" and then written unsanitized to $GITHUB_ENV (as part of NIX_PROFILES) and to $GITHUB_PATH. No sanitization (printf '%s' | tr -d '\n\r') is applied before any of these writes, allowing a calling workflow to inject arbitrary environment variables or PATH entries via a crafted NIX_STATE_HOME value.

Offending lines:
  echo "NIX_PROFILES=/nix/var/nix/profiles/default $NIX_LINK" >> "$GITHUB_ENV"  (NIX_LINK from $NIX_STATE_HOME)
  echo "NIX_SSL_CERT_FILE=$NIX_LINK/etc/ssl/certs/ca-bundle.crt" >> "$GITHUB_ENV"  (fallback branch)
  echo "$NIX_LINK/bin" >> "$GITHUB_PATH"

Locations:

- `install-nix.sh:163`
- `install-nix.sh:182`
- `install-nix.sh:190`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

Fixed two github-env-injection findings in install-nix.sh:
1. INPUT_NIX_PATH (line 148): Added `safe_nix_path=$(printf '%s' "$INPUT_NIX_PATH" | tr -d '\n\r')` and used `${safe_nix_path}` in the GITHUB_ENV write.
2. NIX_LINK derived from NIX_STATE_HOME (lines 163, 182, 190): Added a single sanitization step `NIX_LINK=$(printf '%s' "$NIX_LINK" | tr -d '\n\r')` immediately after NIX_LINK is assigned, before any writes to $GITHUB_ENV or $GITHUB_PATH. This single fix covers all three downstream uses of NIX_LINK.

