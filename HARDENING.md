<!-- markdownlint-disable -->

# Hardening Report: cachix--install-nix-action/v31.11.3

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **cachix--install-nix-action/v31.11.3** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The composite step (action.yml line 29, `run: ${GITHUB_ACTION_PATH}/install-nix.sh`) runs install-nix.sh, which writes untrusted values to special environment files without the `printf '%s' ... | tr -d '\n\r'` sanitization step. (1) Line 129: `echo "NIX_PATH=${INPUT_NIX_PATH}" >>"$GITHUB_ENV"`. INPUT_NIX_PATH comes from `${{ inputs.nix_path }}`, so a value containing a newline can add any environment variable (for example LD_PRELOAD or BASH_ENV). (2) Lines 147-148 set NIX_LINK from the inherited, workflow-controlled env var NIX_STATE_HOME. NIX_LINK is then written unsanitized to GITHUB_ENV at line 154 (`echo "NIX_PROFILES=... $NIX_LINK"`) and line 172, and to GITHUB_PATH at line 181 (`echo "$NIX_LINK/bin" >>"$GITHUB_PATH"`).

Locations:

- `action.yml:29`
- `install-nix.sh:129`
- `install-nix.sh:154`
- `install-nix.sh:172`
- `install-nix.sh:181`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

install-nix.sh: INPUT_NIX_PATH is passed through printf '%s' | tr -d '\n\r' before NIX_PATH is written to GITHUB_ENV. NIX_LINK (which can come from NIX_STATE_HOME) is cleaned the same way right after it is set, so the NIX_PROFILES, NIX_SSL_CERT_FILE and GITHUB_PATH writes all use the cleaned value. These variables are set without command substitution of fallible commands, so no errexit behavior changes. action.yml: added quotes around the script path invocation. Not re-scanned or tested after the edits.

