#!/usr/bin/env bash
# One-command playtest: ./tools/playtest.sh <PR-number>
# Checks out the PR branch, refreshes the import cache, launches the game.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ $# -ne 1 ]; then
	echo "Usage: ./tools/playtest.sh <PR-number>"
	exit 1
fi

# The Godot editor reshuffles project.godot sections on save — that noise is safe
# to discard. Anything else dirty means real uncommitted work: stop.
dirty="$(git diff --name-only)"
if [ "$dirty" = "project.godot" ]; then
	git checkout -- project.godot
elif [ -n "$dirty" ]; then
	echo "Working tree has uncommitted changes:"
	echo "$dirty"
	echo "Commit or stash them first."
	exit 1
fi

gh pr checkout "$1"
godot --headless --import > /dev/null 2>&1 || true

echo "Launching the game (close the window to return)..."
godot --path .
