#!/bin/sh
# Fake Nix installer used by the tests. It records the arguments it was given,
# saves a copy of the --nix-extra-conf-file, and creates a fake `nix` binary in
# the user profile so later steps can verify PATH wiring.
set -e
printf '%s\n' "$@" > /tmp/fake-nix-install-args
conf=""
prev=""
for a in "$@"; do
  if [ "$prev" = "--nix-extra-conf-file" ]; then
    conf="$a"
  fi
  prev="$a"
done
if [ -n "$conf" ] && [ -f "$conf" ]; then
  cp "$conf" /tmp/fake-nix-extra.conf
fi
mkdir -p "$HOME/.nix-profile/bin"
cat > "$HOME/.nix-profile/bin/nix" <<'EOF'
#!/bin/sh
echo "nix (Nix) 0.0.0-fake"
EOF
chmod +x "$HOME/.nix-profile/bin/nix"
echo "fake nix installer done"
