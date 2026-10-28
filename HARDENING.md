<!-- markdownlint-disable -->

# Hardening Report: cachix--install-nix-action/31.11.3

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **cachix--install-nix-action/31.11.3** was hardened automatically. 1 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The composite step (action.yml `run: ${GITHUB_ACTION_PATH}/install-nix.sh`) runs install-nix.sh, which writes untrusted values to GitHub environment files without the `printf '%s' ... | tr -d '\n\r'` sanitization step: (1) `echo "NIX_PATH=${INPUT_NIX_PATH}" >>"$GITHUB_ENV"`, where INPUT_NIX_PATH comes from `inputs.nix_path`, so a newline in the input can inject any environment variable (e.g. LD_PRELOAD, BASH_ENV); (2) NIX_LINK is built from the inherited workflow env var NIX_STATE_HOME and written via `echo "NIX_PROFILES=/nix/var/nix/profiles/default $NIX_LINK" >>"$GITHUB_ENV"`, `echo "NIX_SSL_CERT_FILE=$NIX_LINK/etc/ssl/certs/ca-bundle.crt" >>"$GITHUB_ENV"` and `echo "$NIX_LINK/bin" >>"$GITHUB_PATH"`. Fix: strip CR/LF from each value (`safe=$(printf '%s' "$VAR" | tr -d '\n\r')`) before writing it.

Locations:

- `action.yml:29`
- `install-nix.sh:129`
- `install-nix.sh:154`
- `install-nix.sh:172`
- `install-nix.sh:182`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

install-nix.sh: added a sanitize() helper (printf '%s' | tr -d '\n\r'). INPUT_NIX_PATH is sanitized before NIX_PATH is written, and RUNNER_TEMP is sanitized before TMPDIR is written. NIX_LINK, which can come from NIX_STATE_HOME, is sanitized once right after it is set, so the NIX_PROFILES, NIX_SSL_CERT_FILE and GITHUB_PATH writes all use the clean value. Each capture is a plain assignment, so errexit behaviour is unchanged. action.yml: the script path in run: is now double-quoted; nothing else changed.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

install-nix.sh: removed the stray 'fi' and the stray 'hey don't exist at this point.' text left by the previous edit, and put back the comment ('These directories are created by Nix, but they don't exist at this point.'). Moved the NIX_LINK sanitize line to after the if/else that sets NIX_LINK from NIX_STATE_HOME or HOME. It now uses the script's existing sanitize() helper (strips CR/LF). Because of that, the NIX_PROFILES and NIX_SSL_CERT_FILE writes to GITHUB_ENV and the $NIX_LINK/bin write to GITHUB_PATH all get the cleaned value.

