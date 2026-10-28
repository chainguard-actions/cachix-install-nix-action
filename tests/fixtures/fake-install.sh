#!/bin/sh
# Fake Nix installer used by tests. Records the installer arguments and the
# generated nix.conf (passed via --nix-extra-conf-file), and installs a fake
# `nix` binary into ~/.nix-profile/bin.
set -e
out=/tmp/fake-nix
mkdir -p "$out"
printf '%s\n' "$@" > "$out/args"
prev=""
for a in "$@"; do
  if [ "$prev" = "--nix-extra-conf-file" ]; then
    cp "$a" "$out/nix.conf"
  fi
  prev="$a"
done
mkdir -p "$HOME/.nix-profile/bin"
cat > "$HOME/.nix-profile/bin/nix" <<'EOF'
#!/bin/sh
echo "nix (Nix) 0.0.0-fake"
EOF
chmod +x "$HOME/.nix-profile/bin/nix"
echo "fake nix installed"
