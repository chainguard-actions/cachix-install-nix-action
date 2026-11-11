<!-- markdownlint-disable -->

# Hardening Report: cachix--install-nix-action/v31

> This file was generated automatically by the hardening agent.

**Policy SHA:** `374911c4be584df24e6da57af2d990570ef0f859`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **cachix--install-nix-action/v31** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The composite step's script install-nix.sh writes workflow-controlled values to special environment files without first stripping newlines. (1) Line 128: `echo "NIX_PATH=${INPUT_NIX_PATH}" >>"$GITHUB_ENV"` writes the `inputs.nix_path` value as-is. A value with newlines can add any environment variable, such as LD_PRELOAD, NODE_OPTIONS or BASH_ENV. (2) Lines 147, 153, 171 and 181: NIX_LINK is built from the inherited `$NIX_STATE_HOME`, a process env var the calling workflow can set. It is then written to $GITHUB_ENV (`NIX_PROFILES=... $NIX_LINK`, `NIX_SSL_CERT_FILE=$NIX_LINK/...`) and to $GITHUB_PATH (`echo "$NIX_LINK/bin" >>"$GITHUB_PATH"`), again with no newline stripping. Fix: before each write, sanitize the value with `safe=$(printf '%s' "$VAR" | tr -d '\n\r')`.

Locations:

- `install-nix.sh:128`
- `install-nix.sh:153`
- `install-nix.sh:171`
- `install-nix.sh:181`
- `action.yml:29`

### prior-fix (severity: high)

Carried forward from this version's previous harden, which fixed it; fix it again unless the code no longer has the problem. The previous harden changed install-nix.sh without recording a finding for it, and this analysis reported nothing there. Re-apply its security changes unless the code no longer needs them. The previous patch:
```diff
diff --git a/install-nix.sh b/install-nix.sh
index 7bc0c9c..1e275c7 100755
--- a/install-nix.sh
+++ b/install-nix.sh
@@ -125,13 +125,15 @@ echo "::debug::Nix installed, setting up environment"
 
 # Export the path to Nix
 if [[ -n "${INPUT_NIX_PATH:-}" ]]; then
-  echo "NIX_PATH=${INPUT_NIX_PATH}" >>"$GITHUB_ENV"
+  safe_nix_path=$(printf '%s' "$INPUT_NIX_PATH" | tr -d '\n\r')
+  echo "NIX_PATH=${safe_nix_path}" >>"$GITHUB_ENV"
 fi
 
 # Set temporary directory if not already set
 # Fixes https://github.com/cachix/install-nix-action/issues/197
 if [[ -z "${TMPDIR:-}" ]]; then
-  echo "TMPDIR=${RUNNER_TEMP}" >>"$GITHUB_ENV"
+  safe_runner_temp=$(printf '%s' "$RUNNER_TEMP" | tr -d '\n\r')
+  echo "TMPDIR=${safe_runner_temp}" >>"$GITHUB_ENV"
 fi
 
 # Determine the profile path.
@@ -148,6 +150,8 @@ if [[ -n "${NIX_STATE_HOME:-}" ]]; then
 else
   NIX_LINK="$HOME/.nix-profile"
 fi
+# Strip newlines so the value cannot inject extra entries into GITHUB_ENV/GITHUB_PATH
+NIX_LINK=$(printf '%s' "$NIX_LINK" | tr -d '\n\r')
 
 # Set Nix profiles
 echo "NIX_PROFILES=/nix/var/nix/profiles/default $NIX_LINK" >>"$GITHUB_ENV"

```

Locations:

- `install-nix.sh`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, prior-fix

**Notes:**

install-nix.sh: the script now strips newlines from INPUT_NIX_PATH before writing NIX_PATH, and from RUNNER_TEMP before writing TMPDIR. It also strips them from NIX_LINK right after building it from NIX_STATE_HOME or HOME, so the NIX_PROFILES, NIX_SSL_CERT_FILE and GITHUB_PATH writes all use the cleaned value. action.yml: the script path in the run step is now double-quoted. This doesn't change behaviour.

