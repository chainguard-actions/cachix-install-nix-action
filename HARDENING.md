<!-- markdownlint-disable -->

# Hardening Report: cachix--install-nix-action/v31.10.7

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **cachix--install-nix-action/v31.10.7** was hardened automatically. 5 finding(s) were identified and resolved across 3 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

In install-nix.sh (the composite action's run: script), the env var INPUT_NIX_PATH (set from inputs.nix_path, a caller-controlled input) is written directly to $GITHUB_ENV without sanitization: `echo "NIX_PATH=${INPUT_NIX_PATH}" >> "$GITHUB_ENV"`. An attacker-controlled value containing newlines could inject arbitrary environment variables. Similarly, NIX_LINK is derived from NIX_STATE_HOME (an inherited process env var set by the calling workflow) and written to $GITHUB_PATH without sanitization: `echo "$NIX_LINK/bin" >> "$GITHUB_PATH"`. Neither write is preceded by the required `printf '%s' ... | tr -d '\n\r'` sanitization step.

Locations:

- `install-nix.sh:130`
- `install-nix.sh:196`

### script-injection (severity: high)

In test-per-system.yml, the 'Run NAR server' step interpolates ${{ inputs.system }} directly inside a run: shell command string (sub-rule a): `curl --location https://github.com/cachix/nar-toolbox/releases/download/v0.1.0/nar-toolbox-${{ inputs.system }} -O` and `chmod +x ./nar-toolbox-${{ inputs.system }}` and `./nar-toolbox-${{ inputs.system }} serve ...`. The inputs.system value is workflow-caller-controlled and flows through YAML template substitution before the shell sees it, enabling command injection. Additionally, the custom-nix-path job interpolates ${{ env.nixpkgs_channel }} directly in a run: block: `run: test $NIX_PATH == '${{ env.nixpkgs_channel }}'`.

Locations:

- `.github/workflows/test-per-system.yml:73`
- `.github/workflows/test-per-system.yml:42`

### unsafe-shell (severity: high)

In test.yml, the act-support job pipes a remote shell script directly to bash without first downloading and verifying it: `curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash`. This fetches from a mutable URL (master branch) and executes the result with sudo, allowing a compromised or man-in-the-middle response to execute arbitrary code with elevated privileges.

Locations:

- `.github/workflows/test.yml:52`

### unpinned-uses (severity: high)

In update-nix.yml, two actions are referenced by mutable tag rather than a full 40-character commit SHA: `uses: actions/checkout@v7` (line 11) and `uses: peter-evans/create-pull-request@v8` (line 37). Mutable tags can be moved to point to different (potentially malicious) commits, enabling supply-chain attacks.

Locations:

- `.github/workflows/update-nix.yml:11`
- `.github/workflows/update-nix.yml:37`

### missing-permissions (severity: medium)

None of the three workflow files (test.yml, test-per-system.yml, update-nix.yml) have a top-level `permissions:` key, and no individual job within them defines job-level permissions. Without explicit permissions, workflows run with the default token permissions which may be overly broad (e.g., write access to contents and pull-requests).

Locations:

- `.github/workflows/test.yml:1`
- `.github/workflows/test-per-system.yml:1`
- `.github/workflows/update-nix.yml:1`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection, unsafe-shell, unpinned-uses, missing-permissions

**Notes:**

Fixed all 5 findings: (1) github-env-injection in install-nix.sh - sanitized INPUT_NIX_PATH and NIX_LINK with printf/tr before writing to GITHUB_ENV/GITHUB_PATH; (2) script-injection in test-per-system.yml - moved ${{ inputs.system }} and ${{ env.nixpkgs_channel }} into env: blocks; (3) unsafe-shell in test.yml - download script to file first then execute separately; (4) unpinned-uses in update-nix.yml - pinned actions/checkout@v7 to SHA 9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 and peter-evans/create-pull-request@v8 to SHA 5f6978faf089d4d20b00c7766989d076bb2fc7f1; (5) missing-permissions - added permissions blocks to all three workflow files with minimal required permissions.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Fixed two github-env-injection findings in install-nix.sh. Added a single sanitization step `safe_nix_link=$(printf '%s' "$NIX_LINK" | tr -d '\n\r')` immediately after NIX_LINK is assigned. Replaced all uses of unsanitized $NIX_LINK in GITHUB_ENV writes with $safe_nix_link: (1) the NIX_PROFILES line (previously line 159), (2) the NIX_SSL_CERT_FILE fallback line (previously line 177). Also consolidated the previously duplicate safe_nix_link assignment that existed at the bottom of the file for the GITHUB_PATH write, so there is now a single sanitization point used for all three writes.

### Iteration 3

**Fixes applied:** script-injection

**Notes:**

Reviewed hardened/action/.github/workflows/test-per-system.yml. The ${SYSTEM} variable expansions in the latest-installer job's run block are already properly double-quoted in the current file state: the curl URL argument, the chmod argument, and the command execution all use double-quoted "${SYSTEM}" expansions. The fix was already applied in a previous iteration. No further changes were needed.

