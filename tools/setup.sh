#!/usr/bin/env bash
# One-time dev machine setup (macOS). Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")/.."

command -v brew >/dev/null 2>&1 || { echo "Install Homebrew first: https://brew.sh"; exit 1; }

brew list --cask godot >/dev/null 2>&1 || brew install --cask godot
command -v git-lfs >/dev/null 2>&1 || brew install git-lfs

# The cask doesn't link a `godot` CLI binary — create a shim
if ! command -v godot >/dev/null 2>&1; then
	ln -sf "/Applications/Godot.app/Contents/MacOS/Godot" "$(brew --prefix)/bin/godot"
fi

git lfs install

# Vendor the gdUnit4 addon so both machines and CI share one version
if [ ! -d addons/gdUnit4 ]; then
	tag=$(curl -fsSL https://api.github.com/repos/MikeSchulze/gdUnit4/releases/latest \
		| python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"])')
	echo "Installing gdUnit4 $tag"
	tmp=$(mktemp -d)
	curl -fsSL -o "$tmp/gdunit4.zip" "https://github.com/MikeSchulze/gdUnit4/archive/refs/tags/${tag}.zip"
	unzip -q "$tmp/gdunit4.zip" -d "$tmp"
	mkdir -p addons
	cp -R "$tmp"/gdUnit4-*/addons/gdUnit4 addons/
	rm -rf "$tmp"
fi

# Enable the plugin in project.godot
if ! grep -q "gdUnit4/plugin.cfg" project.godot; then
	printf '\n[editor_plugins]\n\nenabled=PackedStringArray("res://addons/gdUnit4/plugin.cfg")\n' >> project.godot
fi

# First import so the editor opens clean
godot --headless --import >/dev/null 2>&1 || true

echo
echo "Done. Versions:"
godot --version
git lfs version | head -1
echo
echo "If addons/gdUnit4 is new, commit it:"
echo "  git add addons project.godot && git commit -m 'chore: vendor gdUnit4'"
