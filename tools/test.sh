#!/usr/bin/env bash
# Run the gdUnit4 suite headless — same invocation CI uses.
set -euo pipefail
cd "$(dirname "$0")/.."

godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a tests
