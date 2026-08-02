# Agent instructions — Cockroach Game

Godot 4.7, GDScript only (no C#). 3D rendering, gameplay locked to the XZ plane.
Game concept and mechanics roadmap: `docs/design.md`.

## Your role

You are the **implementation agent**. You receive a GitHub issue containing a spec
(goal, acceptance criteria, invariants, out of scope). Implement exactly that scope —
nothing more. Specs are written and PRs reviewed by the architect agent; a review bot
and CI gate every merge. Humans playtest and merge.

## Per-issue workflow

1. Sync: `git checkout main && git pull`
2. Branch: `feat/<issue#>-<slug>` (or `fix/`, `chore/`, `docs/` matching the issue type)
   Then announce: `gh issue comment <issue#> --body "Started — branch <branch-name>"` and
   `gh issue edit <issue#> --add-label in-progress` (the linked PR supersedes this later;
   remove the label when the PR opens)
3. Implement within scope. Your territory: `scenes/`, `scripts/`, `tests/`, `assets/`.
   **Never touch** `.github/`, `.claude/`, `tools/`, `docs/` unless the issue explicitly says so.
4. Every gameplay feature gets at least one gdUnit4 test in `tests/<name>_test.gd`.
5. Verify locally before pushing — all must pass:
   - `./tools/test.sh` (same command CI runs)
   - `gdformat --check scripts tests` and `gdlint scripts tests` (if installed locally)
6. Commit with conventional messages (`feat:` `fix:` `chore:` `docs:` `test:`).
   Push the branch, open **one PR** with `Closes #<issue#>`, fill the PR template.
   Open it **ready for review, never as a draft** — the review bot ignores drafts.
   After pushing, check the working tree back out to `main` (the checkout is shared).
7. **Never push to `main`. Never merge.** Merging happens after CI, both reviews,
   and the human playtest checklist.
8. Review feedback arrives as PR comments — fix on the same branch and push;
   every new commit re-runs all gates.

## Code rules

- Typed GDScript (`:=`, typed params and returns); snake_case files/dirs; PascalCase node names
- Input only via actions defined in `project.godot` — never hardcoded keys
- Movement/physics in `_physics_process`
- Static geometry: `StaticBody3D` + `MeshInstance3D` + `CollisionShape3D` — no CSG nodes in committed scenes
- Formatting: tabs, two blank lines between top-level definitions (`gdformat` conventions)

## Scene-file pitfalls (learned the hard way — PR #2)

- Prefer authoring `.tscn` in the Godot editor. If writing one by hand: typed node
  exports (e.g. `@export var target: Node3D`) resolve **only** if the node header has
  `node_paths=PackedStringArray("target")`.
- After any editor session, diff `.tscn` files node-by-node before committing —
  accidental viewport gizmo drags produce stray `transform =` lines.
- Commit the `.uid` and `.import` files Godot generates.

## Testing patterns (CI-safe)

- Scene boots: `scene_runner("res://...")` + `simulate_frames(N)` + assert not null
- Input-driven behavior: press actions via the `Input` singleton (`Input.action_press`),
  not synthesized InputEvents (those don't propagate headless)
- Time-dependent logic: **never** assert on frame counts across many frames — CI frame
  pacing differs wildly from local. Call the logic directly with a fixed delta instead
  (see `test_camera_follow_converges_on_target` in `tests/camera_test.gd`)
- Headless run crashes writing `user://`? Prefix: `HOME="$TMPDIR/gdhome" ./tools/test.sh`

## Your local config

Your workspace config lives in `.codex/` — it is machine-local and gitignored.
Permission or approval settings are **never repo work**: no branches, no commits,
no PRs for them, and never bundle project-file edits with config changes.

## Environment

- macOS, Godot 4.7.1 via the `godot` CLI shim (`tools/setup.sh` installs everything)
- Git LFS handles binary assets; `blender/` holds `.blend` sources (never imported) —
  export `.glb` to `assets/models/`
