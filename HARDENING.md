<!-- markdownlint-disable -->

# Hardening Report: cachix--install-nix-action/31.11.3

> This file was generated automatically by the hardening agent.

**Policy SHA:** `374911c4be584df24e6da57af2d990570ef0f859`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **cachix--install-nix-action/31.11.3** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The composite step (`run: ${GITHUB_ACTION_PATH}/install-nix.sh`) runs install-nix.sh, and that script writes workflow-controlled values to the runner's special files without the `printf '%s' ... | tr -d '\n\r'` sanitization step. (1) Line 129: `echo "NIX_PATH=${INPUT_NIX_PATH}" >>"$GITHUB_ENV"`. INPUT_NIX_PATH comes from `inputs.nix_path`. If the value contains a newline, the caller can add any environment variable they like, such as LD_PRELOAD, BASH_ENV or NODE_OPTIONS, for later steps. (2) Line 148 sets NIX_LINK from the inherited env var `$NIX_STATE_HOME`, which the calling workflow controls. NIX_LINK is then written unsanitized to $GITHUB_ENV at line 154 (`echo "NIX_PROFILES=... $NIX_LINK"`) and line 172 (`echo "NIX_SSL_CERT_FILE=$NIX_LINK/..."`), and to $GITHUB_PATH at line 182 (`echo "$NIX_LINK/bin" >>"$GITHUB_PATH"`). A newline in NIX_STATE_HOME would add extra env entries or PATH entries.

Locations:

- `install-nix.sh:129`
- `install-nix.sh:154`
- `install-nix.sh:172`
- `install-nix.sh:182`
- `action.yml:29`

### prior-fix (severity: high)

Carried forward from this version's previous harden, which fixed it; fix it again unless the code no longer has the problem. The previous harden changed action.yml without recording a finding for it, and this analysis reported nothing there. Re-apply its security changes unless the code no longer needs them. The previous patch:
```diff
diff --git a/action.yml b/action.yml
index fd22752..0c8e2b1 100644
--- a/action.yml
+++ b/action.yml
@@ -26,7 +26,24 @@ branding:
 runs:
   using: 'composite'
   steps:
-    - run : ${GITHUB_ACTION_PATH}/install-nix.sh
+    - run : '"${GITHUB_ACTION_PATH}/install-nix.sh"'
       shell: bash
       env:
         INPUT_EXTRA_NIX_CONFIG: ${{ inputs.extra_nix_config }}

```

Locations:

- `action.yml`

### prior-fix (severity: high)

Carried forward from this version's previous harden, which fixed it; fix it again unless the code no longer has the problem. The previous harden changed install-nix.sh without recording a finding for it, and this analysis reported nothing there. Re-apply its security changes unless the code no longer needs them. The previous patch:
```diff
diff --git a/install-nix.sh b/install-nix.sh
index 299e751..294df98 100755
--- a/install-nix.sh
+++ b/install-nix.sh
@@ -124,15 +124,22 @@ sh "$workdir/install" "${installer_options[@]}"
 # GitHub doesn't evaluate profiles or rc scripts by default, so we set up the environment manually.
 echo "::debug::Nix installed, setting up environment"
 
+# Strip CR/LF so values cannot inject extra entries into GitHub environment files
+sanitize() {
+  printf '%s' "$1" | tr -d '\n\r'
+}
+
 # Export the path to Nix
 if [[ -n "${INPUT_NIX_PATH:-}" ]]; then
-  echo "NIX_PATH=${INPUT_NIX_PATH}" >>"$GITHUB_ENV"
+  safe_nix_path=$(sanitize "$INPUT_NIX_PATH")
+  echo "NIX_PATH=${safe_nix_path}" >>"$GITHUB_ENV"
 fi
 
 # Set temporary directory if not already set
 # Fixes https://github.com/cachix/install-nix-action/issues/197
 if [[ -z "${TMPDIR:-}" ]]; then
-  echo "TMPDIR=${RUNNER_TEMP}" >>"$GITHUB_ENV"
+  safe_runner_temp=$(sanitize "${RUNNER_TEMP}")
+  echo "TMPDIR=${safe_runner_temp}" >>"$GITHUB_ENV"
 fi
 
 # Determine the profile path.
@@ -142,13 +149,15 @@ fi
 #   - XDG_STATE_HOME, defaulting to .local/state/nix/profile
 #   - $HOME/.nix-profile
 #
-# These directories are created by calling `nix profile`, so they don't exist at this point.
+# These directories are created by Nix, but they don't exist at this point.
 # Without parsing the Nix version, our best bet is the legacy-ish ~/.nix-profile.
 if [[ -n "${NIX_STATE_HOME:-}" ]]; then
   NIX_LINK="$NIX_STATE_HOME/profile"
 else
   NIX_LINK="$HOME/.nix-profile"
 fi
+# Sanitize once; every write of NIX_LINK to GITHUB_ENV/GITHUB_PATH below uses this value
+NIX_LINK=$(sanitize "$NIX_LINK")
 
 # Set Nix profiles
 echo "NIX_PROFILES=/nix/var/nix/profiles/default $NIX_LINK" >>"$GITHUB_ENV"

```

Locations:

- `install-nix.sh`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, prior-fix

**Notes:**

install-nix.sh: added a sanitize() helper (printf '%s' | tr -d '\n\r'). It now cleans INPUT_NIX_PATH and RUNNER_TEMP before they are written to GITHUB_ENV. NIX_LINK is cleaned once after it is set, so the later writes of NIX_PROFILES and NIX_SSL_CERT_FILE to GITHUB_ENV and the bin path to GITHUB_PATH all get the cleaned value. action.yml: the script path is quoted again, as the previous harden did. These edits have not been run or tested.

