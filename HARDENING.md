<!-- markdownlint-disable -->

# Hardening Report: cachix--install-nix-action/v31.10.7

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **cachix--install-nix-action/v31.10.7** was hardened automatically. 5 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### unsafe-shell (severity: high)

A run: step in test.yml pipes a remote script directly to `sudo bash` without first downloading it to a file. This allows the remote server to serve arbitrary code that is immediately executed with elevated privileges. Offending line: `curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash`

Locations:

- `.github/workflows/test.yml:54`

### unpinned-uses (severity: high)

update-nix.yml references two actions by mutable tag rather than a full 40-character commit SHA, making the workflow vulnerable to supply-chain attacks if the tag is moved: (1) `actions/checkout@v7` and (2) `peter-evans/create-pull-request@v8`.

Locations:

- `.github/workflows/update-nix.yml:11`
- `.github/workflows/update-nix.yml:30`

### missing-permissions (severity: medium)

None of the workflow files define a top-level `permissions:` key, and no individual job defines its own `permissions:` block. Without explicit permissions, workflows run with the default (potentially broad) token permissions, violating the principle of least privilege.

Locations:

- `.github/workflows/test.yml:1`
- `.github/workflows/test-per-system.yml:1`
- `.github/workflows/update-nix.yml:1`

### script-injection (severity: high)

Sub-rule (a): GitHub Actions expressions are interpolated directly inside run: shell command strings. (1) test-per-system.yml line 44: `run: test $NIX_PATH == '${{ env.nixpkgs_channel }}'` — the expression is expanded by the template engine before the shell sees it, allowing metacharacter injection. (2) test-per-system.yml lines 78-80: `${{ inputs.system }}` is interpolated directly into shell commands that download, chmod, and execute a binary (`curl --location ... nar-toolbox-${{ inputs.system }} -O`, `chmod +x ./nar-toolbox-${{ inputs.system }}`, `./nar-toolbox-${{ inputs.system }} serve ...`), allowing an attacker-controlled `inputs.system` value to inject shell metacharacters.

Locations:

- `.github/workflows/test-per-system.yml:44`
- `.github/workflows/test-per-system.yml:78`
- `.github/workflows/test-per-system.yml:79`
- `.github/workflows/test-per-system.yml:80`

### github-env-injection (severity: high)

Unsanitized values derived from untrusted inputs are written to $GITHUB_ENV without the required `printf '%s' ... | tr -d '\n\r'` sanitization step. (1) install-nix.sh: `INPUT_NIX_PATH` (set from `inputs.nix_path` in action.yml) is written directly: `echo "NIX_PATH=${INPUT_NIX_PATH}" >> "$GITHUB_ENV"`. A newline embedded in the input value can inject arbitrary environment variables into subsequent steps. (2) update-nix.yml: `current_nix` and `latest_nix` are derived from the GitHub API (external, potentially attacker-influenced tag names) and written unsanitized: `echo "CURRENT_NIX=${current_nix}" >> $GITHUB_ENV` and `echo "LATEST_NIX=${latest_nix}" >> $GITHUB_ENV`.

Locations:

- `install-nix.sh:118`
- `.github/workflows/update-nix.yml:29`
- `.github/workflows/update-nix.yml:30`

## Iteration Notes

### Iteration 1

**Fixes applied:** unsafe-shell, unpinned-uses, missing-permissions, script-injection, github-env-injection

**Notes:**

Fixed all 5 findings:
1. unsafe-shell (test.yml): Replaced `curl ... | sudo bash` with a two-step approach: download to /tmp/act-install.sh then execute separately.
2. unpinned-uses (update-nix.yml): Pinned actions/checkout@v7 to SHA 3d3c42e5aac5ba805825da76410c181273ba90b1 and peter-evans/create-pull-request@v8 to SHA 5f6978faf089d4d20b00c7766989d076bb2fc7f1.
3. missing-permissions: Added `permissions: {}` at top level of all three workflow files; added job-level `contents: write` and `pull-requests: write` for the update-nix job that needs those permissions.
4. script-injection (test-per-system.yml): Moved ${{ env.nixpkgs_channel }} and ${{ inputs.system }} expressions out of run: shell strings into env: blocks, referencing them as plain env vars in the shell.
5. github-env-injection: Sanitized INPUT_NIX_PATH in install-nix.sh and current_nix/latest_nix in update-nix.yml using `printf '%s' ... | tr -d '\n\r'` before writing to $GITHUB_ENV.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Fixed all four github-env-injection findings in install-nix.sh:
1. RUNNER_TEMP (line 138): sanitized with `safe_runner_temp=$(printf '%s' "$RUNNER_TEMP" | tr -d '\n\r')` before writing TMPDIR to $GITHUB_ENV.
2. NIX_LINK for NIX_PROFILES (line 153): added `safe_nix_link=$(printf '%s' "$NIX_LINK" | tr -d '\n\r')` after NIX_LINK is assigned; used ${safe_nix_link} in the $GITHUB_ENV write.
3. NIX_LINK for NIX_SSL_CERT_FILE (line 172): replaced $NIX_LINK with ${safe_nix_link} in both the path existence check and the $GITHUB_ENV write.
4. NIX_LINK for $GITHUB_PATH (line 178): replaced $NIX_LINK with ${safe_nix_link} in the $GITHUB_PATH write.

