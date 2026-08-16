<!-- markdownlint-disable -->

# Hardening Report: cachix--install-nix-action/v31.10.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **cachix--install-nix-action/v31.10.6** was hardened automatically. 5 finding(s) were identified and resolved across 3 iteration(s).

## Findings Fixed

### unsafe-shell (severity: high)

A `run:` block pipes a remote script directly to `sudo bash` without first downloading and inspecting it. The pattern `curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash` fetches and executes arbitrary remote content in a single pipeline, allowing a compromised upstream to execute malicious code with elevated privileges.

Locations:

- `.github/workflows/test.yml:57`

### script-injection (severity: high)

Sub-rule (a): GitHub Actions expressions are interpolated directly inside `run:` shell command strings. In the `latest-installer` job, `${{ inputs.system }}` is embedded three times in a multi-line run block (used in a filename, chmod, and execution path). In the `custom-nix-path` job, `${{ env.nixpkgs_channel }}` is interpolated directly in a `run:` command. These substitutions happen before the shell parses the command, allowing an attacker who controls the workflow inputs to inject arbitrary shell commands.

Locations:

- `.github/workflows/test-per-system.yml:72`
- `.github/workflows/test-per-system.yml:43`

### github-env-injection (severity: high)

In `install-nix.sh`, the inherited environment variable `INPUT_NIX_PATH` (set from `inputs.nix_path` by action.yml) is written directly to `$GITHUB_ENV` without sanitization: `echo "NIX_PATH=${INPUT_NIX_PATH}" >> "$GITHUB_ENV"`. A calling workflow can supply a value containing newlines to inject arbitrary environment variables (e.g., `ACTIONS_RUNTIME_TOKEN=attacker-value`) into subsequent steps. The required sanitization step `printf '%s' "$INPUT_NIX_PATH" | tr -d '\n\r'` is absent.

Locations:

- `install-nix.sh:113`

### unpinned-uses (severity: high)

Two `uses:` references in `update-nix.yml` are pinned to mutable tags rather than immutable 40-character commit SHAs, making them vulnerable to supply-chain attacks if the referenced tag is moved or the repository is compromised:
- `uses: actions/checkout@v6` (tag `v6`)
- `uses: peter-evans/create-pull-request@v8` (tag `v8`)
These should be pinned to full SHA digests, e.g. `actions/checkout@<40-hex-sha> # v6`.

Locations:

- `.github/workflows/update-nix.yml:11`
- `.github/workflows/update-nix.yml:32`

### missing-permissions (severity: medium)

None of the three workflow files define a top-level `permissions:` block, and no individual job within them defines job-level `permissions:` either. Without explicit permissions, workflows inherit the repository's default token permissions (which may be `write-all` for older repositories), granting unnecessarily broad access. Explicit minimal permissions should be declared for each workflow.

Locations:

- `.github/workflows/test.yml:1`
- `.github/workflows/test-per-system.yml:1`
- `.github/workflows/update-nix.yml:1`

## Iteration Notes

### Iteration 1

**Fixes applied:** unsafe-shell, script-injection, github-env-injection, unpinned-uses, missing-permissions

**Notes:**

Fixed all 5 findings:
1. unsafe-shell (test.yml): Replaced `curl ... | sudo bash` with a two-step approach: download to /tmp/act-install.sh then execute separately.
2. script-injection (test-per-system.yml): Moved ${{ inputs.system }} (latest-installer job, 3 uses) and ${{ env.nixpkgs_channel }} (custom-nix-path job) into step-level env: blocks, referencing them as plain shell variables.
3. github-env-injection (install-nix.sh): Sanitized INPUT_NIX_PATH with `printf '%s' "$INPUT_NIX_PATH" | tr -d '\n\r'` before writing to GITHUB_ENV.
4. unpinned-uses (update-nix.yml): Pinned actions/checkout@v6 to SHA df4cb1c069e1874edd31b4311f1884172cec0e10 and peter-evans/create-pull-request@v8 to SHA 5f6978faf089d4d20b00c7766989d076bb2fc7f1.
5. missing-permissions: Added `permissions: {}` top-level block to all three workflow files; added job-level `contents: write` and `pull-requests: write` to update-nix.yml's update-nix-releases job which requires those permissions.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In install-nix.sh, added a sanitization step immediately after NIX_LINK is assigned: `NIX_LINK=$(printf '%s' "$NIX_LINK" | tr -d '\n\r')`. This strips any newline or carriage-return characters from NIX_LINK before it is used in writes to $GITHUB_ENV (NIX_PROFILES and NIX_SSL_CERT_FILE) and $GITHUB_PATH. The NIX_STATE_HOME environment variable is workflow-controlled and could contain newlines that would allow injection of arbitrary key=value pairs into the runner environment. The fix follows the same pattern already used for INPUT_NIX_PATH in the same script.

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

Fixed install-nix.sh line 108: Added sanitization of the RUNNER_TEMP environment variable before writing it to $GITHUB_ENV. The fix introduces `safe_runner_temp=$(printf '%s' "$RUNNER_TEMP" | tr -d '\n\r')` and uses `safe_runner_temp` in the echo statement instead of the raw `RUNNER_TEMP` value. This prevents newline injection attacks where a malicious RUNNER_TEMP value containing newlines could inject additional key=value pairs into $GITHUB_ENV.

