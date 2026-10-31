# CLAUDE.md

@AGENTS.md

AGENTS.md is the single source of project rules. Change rules there, not here; this file holds only Claude-specific additions.

## Sandboxed sessions

Headless Godot runs need `HOME="$TMPDIR/gdhome"` in front of `./tools/test.sh` and `godot` (already in the repo's allow list).
