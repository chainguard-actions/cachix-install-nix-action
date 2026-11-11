<!-- markdownlint-disable -->

# Hardening Report: cachix--install-nix-action/v31.11.5

> This file was generated automatically by the hardening agent.

**Policy SHA:** `374911c4be584df24e6da57af2d990570ef0f859`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **cachix--install-nix-action/v31.11.5** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The composite step (action.yml line 29) runs install-nix.sh, and that script writes values the workflow controls to special environment files without the `printf '%s' ... | tr -d '\n\r'` newline strip. (1) Line 128: `echo "NIX_PATH=${INPUT_NIX_PATH}" >>"$GITHUB_ENV"`. INPUT_NIX_PATH comes from `inputs.nix_path`, so a value containing a newline can add extra environment variables such as LD_PRELOAD or BASH_ENV. (2) Line 147 sets `NIX_LINK="$NIX_STATE_HOME/profile"`, and NIX_STATE_HOME is inherited from the calling workflow's environment. NIX_LINK is then written unsanitized to $GITHUB_ENV at line 153 (`echo "NIX_PROFILES=/nix/var/nix/profiles/default $NIX_LINK"`) and line 171 (`echo "NIX_SSL_CERT_FILE=$NIX_LINK/..."`), and to $GITHUB_PATH at line 181 (`echo "$NIX_LINK/bin" >>"$GITHUB_PATH"`). (3) Line 134 also forwards the inherited `${RUNNER_TEMP}` into $GITHUB_ENV unsanitized. Fix: strip newlines from each value with `printf '%s' "$VAR" | tr -d '\n\r'` before writing it.

Locations:

- `action.yml:29`
- `install-nix.sh:128`
- `install-nix.sh:134`
- `install-nix.sh:153`
- `install-nix.sh:171`
- `install-nix.sh:181`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

install-nix.sh now strips newlines from four values before writing them: INPUT_NIX_PATH (written to NIX_PATH) and RUNNER_TEMP (written to TMPDIR) go through `printf '%s' ... | tr -d '\n\r'` first. NIX_LINK, which can come from the inherited NIX_STATE_HOME, is stripped once right after it is set. It is stripped again inline wherever it is written: NIX_PROFILES, NIX_SSL_CERT_FILE and the GITHUB_PATH entry. Strip pipelines are only used on plain variables, never wrapped around a command that could fail, so errexit still behaves as before. action.yml needed no changes because its run line uses no ${{ }} expressions. Nothing was run to test this.

