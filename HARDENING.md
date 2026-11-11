<!-- markdownlint-disable -->

# Hardening Report: cachix--install-nix-action/v31

> This file was generated automatically by the hardening agent.

**Policy SHA:** `374911c4be584df24e6da57af2d990570ef0f859`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **cachix--install-nix-action/v31** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The composite step (action.yml line 29) runs install-nix.sh. That script writes untrusted values to GitHub's special environment files without first applying `printf '%s' ... | tr -d '\n\r'`. (1) `echo "NIX_PATH=${INPUT_NIX_PATH}" >>"$GITHUB_ENV"`: INPUT_NIX_PATH comes from `inputs.nix_path`. If the value contains a newline, the caller can inject any variable into $GITHUB_ENV, for example LD_PRELOAD or BASH_ENV. (2) NIX_LINK is set to `$NIX_STATE_HOME/profile`. NIX_STATE_HOME is inherited from the calling workflow's environment. NIX_LINK is then written to $GITHUB_ENV (`echo "NIX_PROFILES=... $NIX_LINK"`, and the NIX_SSL_CERT_FILE line) and to $GITHUB_PATH (`echo "$NIX_LINK/bin" >>"$GITHUB_PATH"`), also without newline stripping. Fix: strip newlines from each value before writing it, e.g. `safe=$(printf '%s' "$INPUT_NIX_PATH" | tr -d '\n\r')`.

Locations:

- `action.yml:29`
- `install-nix.sh:129`
- `install-nix.sh:148`
- `install-nix.sh:154`
- `install-nix.sh:182`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

In install-nix.sh: (1) INPUT_NIX_PATH goes through printf '%s' | tr -d '\n\r' before it is written as NIX_PATH to GITHUB_ENV. (2) NIX_LINK, which comes from NIX_STATE_HOME or HOME, is cleaned the same way right after it is set. That covers the NIX_PROFILES and NIX_SSL_CERT_FILE writes to GITHUB_ENV and the $NIX_LINK/bin write to GITHUB_PATH. (3) As an extra precaution, RUNNER_TEMP is also cleaned before it is written as TMPDIR. action.yml needed no change because its inputs are already passed through env:.

