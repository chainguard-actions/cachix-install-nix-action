<!-- markdownlint-disable -->

# Hardening Report: cachix--install-nix-action/v32.0.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `374911c4be584df24e6da57af2d990570ef0f859`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **cachix--install-nix-action/v32.0.0** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The composite step runs install-nix.sh, which writes workflow-controlled values to special environment files without first stripping newlines (printf '%s' ... | tr -d '\n\r'): (1) `echo "NIX_PATH=${INPUT_NIX_PATH}" >>"$GITHUB_ENV"`. INPUT_NIX_PATH comes from inputs.nix_path, so a value containing a newline can add any environment variable, such as LD_PRELOAD or BASH_ENV. (2) NIX_LINK is built from the inherited env var NIX_STATE_HOME and then written unsanitized in `echo "NIX_PROFILES=/nix/var/nix/profiles/default $NIX_LINK" >>"$GITHUB_ENV"`, `echo "NIX_SSL_CERT_FILE=$NIX_LINK/etc/ssl/certs/ca-bundle.crt" >>"$GITHUB_ENV"` and `echo "$NIX_LINK/bin" >>"$GITHUB_PATH"`. (3) `echo "TMPDIR=${RUNNER_TEMP}" >>"$GITHUB_ENV"` forwards an inherited env var without sanitization.

Locations:

- `install-nix.sh:134`
- `install-nix.sh:140`
- `install-nix.sh:159`
- `install-nix.sh:176`
- `install-nix.sh:187`
- `action.yml:29`

### script-injection (severity: high)

Rule (b): the composite run block expands an inherited process env var without quotes: `run : ${GITHUB_ACTION_PATH}/install-nix.sh`. The shell splits the unquoted value on whitespace and expands globs. Quote it: `"${GITHUB_ACTION_PATH}/install-nix.sh"`.

Locations:

- `action.yml:29`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Added a sanitize() helper to install-nix.sh (printf '%s' | tr -d '\n\r'). It now strips newlines from INPUT_NIX_PATH, RUNNER_TEMP and NIX_LINK before they are written to GITHUB_ENV or GITHUB_PATH. NIX_LINK is cleaned once right after it is set, so all three later writes use the cleaned value. Each value is captured into a variable first and then echoed, so no command substitution is nested inside another call. In action.yml the run line is now quoted: "${GITHUB_ACTION_PATH}/install-nix.sh". Nothing was run or tested after the edits.

