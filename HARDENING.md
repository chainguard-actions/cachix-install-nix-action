<!-- markdownlint-disable -->

# Hardening Report: cachix--install-nix-action/v31.11.3

> This file was generated automatically by the hardening agent.

**Policy SHA:** `374911c4be584df24e6da57af2d990570ef0f859`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **cachix--install-nix-action/v31.11.3** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The composite step `run: ${GITHUB_ACTION_PATH}/install-nix.sh` runs a script that writes untrusted values to the runner's special environment files without stripping newlines (`printf '%s' ... | tr -d '\n\r'`). (1) Line 129: `echo "NIX_PATH=${INPUT_NIX_PATH}" >>"$GITHUB_ENV"`. INPUT_NIX_PATH comes straight from `${{ inputs.nix_path }}`, so a newline in it can inject any variable into GITHUB_ENV (e.g. LD_PRELOAD, BASH_ENV). (2) Lines 148/154/172/181: NIX_LINK is built from `$NIX_STATE_HOME`, an env var inherited from the calling workflow. It is then written to GITHUB_ENV (`NIX_PROFILES=... $NIX_LINK`, `NIX_SSL_CERT_FILE=$NIX_LINK/...`) and to GITHUB_PATH (`echo "$NIX_LINK/bin" >>"$GITHUB_PATH"`), all unsanitized. Before each write, run the value through `printf '%s' "$VAR" | tr -d '\n\r'`.

Locations:

- `install-nix.sh:129`
- `install-nix.sh:154`
- `install-nix.sh:172`
- `install-nix.sh:181`
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
index 299e751..11ade00 100755
--- a/install-nix.sh
+++ b/install-nix.sh
@@ -126,7 +126,8 @@ echo "::debug::Nix installed, setting up environment"
 
 # Export the path to Nix
 if [[ -n "${INPUT_NIX_PATH:-}" ]]; then
-  echo "NIX_PATH=${INPUT_NIX_PATH}" >>"$GITHUB_ENV"
+  safe_nix_path=$(printf '%s' "$INPUT_NIX_PATH" | tr -d '\n\r')
+  echo "NIX_PATH=${safe_nix_path}" >>"$GITHUB_ENV"
 fi
 
 # Set temporary directory if not already set
@@ -149,6 +150,8 @@ if [[ -n "${NIX_STATE_HOME:-}" ]]; then
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

install-nix.sh: INPUT_NIX_PATH is cleaned with printf '%s' | tr -d '\n\r' before it is written as NIX_PATH. NIX_LINK is cleaned once, right after it is set, so the NIX_PROFILES, NIX_SSL_CERT_FILE and GITHUB_PATH writes all use the cleaned value. I also cleaned RUNNER_TEMP before writing TMPDIR, as an extra precaution. action.yml: the run step now calls the script by a quoted path ('"${GITHUB_ACTION_PATH}/install-nix.sh"'), the same change as the earlier patch.

