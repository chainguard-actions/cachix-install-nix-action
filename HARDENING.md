<!-- markdownlint-disable -->

# Hardening Report: cachix--install-nix-action/v32.1.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `374911c4be584df24e6da57af2d990570ef0f859`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **cachix--install-nix-action/v32.1.0** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The composite step in action.yml (`run: ${GITHUB_ACTION_PATH}/install-nix.sh`) runs install-nix.sh, and that script writes workflow-controlled values to special environment files without first passing them through `printf '%s' ... | tr -d '\n\r'`. (1) Line 163: `echo "NIX_PATH=${INPUT_NIX_PATH}" >>"$GITHUB_ENV"`. INPUT_NIX_PATH comes from `${{ inputs.nix_path }}`, so a value containing a newline can add any variable to GITHUB_ENV (for example LD_PRELOAD or BASH_ENV). (2) Lines 182/188/206/216: NIX_LINK is built from the inherited env var NIX_STATE_HOME, which the calling workflow controls. It is written to $GITHUB_ENV (`echo "NIX_PROFILES=... $NIX_LINK"`, `echo "NIX_SSL_CERT_FILE=$NIX_LINK/..."`) and to $GITHUB_PATH (`echo "$NIX_LINK/bin" >>"$GITHUB_PATH"`) with no newline stripping.

Locations:

- `install-nix.sh:163`
- `install-nix.sh:188`
- `install-nix.sh:206`
- `install-nix.sh:216`
- `action.yml:10`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

I added a `sanitize` helper (`printf '%s' | tr -d '\n\r'`) to install-nix.sh. It now strips newlines from three values before they are written: INPUT_NIX_PATH (written to $GITHUB_ENV), RUNNER_TEMP (written to TMPDIR in $GITHUB_ENV), and NIX_LINK, which is built from NIX_STATE_HOME or HOME. NIX_LINK is cleaned once, right after it is set, so every later write is covered: NIX_PROFILES, NIX_SSL_CERT_FILE and the $GITHUB_PATH entry. Each value is captured in a plain assignment, so nothing hides a failing exit status. I also put the script path in action.yml in quotes. No other behaviour changed, and I did not run the action to test these edits.

