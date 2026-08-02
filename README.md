# Cockroach Game

3D Godot game, isometric-style view, gameplay locked to the ground plane. Assets authored in Blender, exported as glTF. A father-and-son project.

## First-time setup (both MacBooks)

```bash
./tools/setup.sh
```

Installs Godot + git-lfs via Homebrew, vendors the gdUnit4 addon, links a `godot` CLI shim. Safe to re-run.

## Run

Open `project.godot` in Godot and press ⌘B (Run Project), or:

```bash
godot --path .
```

Controls: WASD / arrow keys.

## Development workflow

1. **Issue** — spec with goal, acceptance criteria, invariants, risk, release type (template provided).
2. **Branch + PR** — `feat/<issue#>-slug`, one linked PR (`Closes #N`).
3. **Gates** — CI (lint + gdUnit4 tests), Codex review of the PR head, and the **playtest**: pull the branch on the other MacBook, ⌘B, play, record the verdict in the PR checklist.
4. **Squash-merge** when all gates are green and conversations resolved. Merging never releases.
5. **Release** — Actions → *Release* → enter `vX.Y.Z`. It builds the macOS app from `main`, smoke-tests the export headlessly, tags, and attaches the build to a GitHub Release.
6. **Rollback** — previous Releases stay downloadable; nothing to migrate.

## Testing

gdUnit4 suites live in `tests/`. Run them from the editor (GdUnit panel) or headless:

```bash
./tools/test.sh
```

## Structure

| Path | Purpose |
|---|---|
| `scenes/` | Godot scenes, one folder per feature |
| `scripts/` | GDScript |
| `tests/` | gdUnit4 test suites |
| `assets/` | Runtime assets: `models/` (glTF), `textures/`, `audio/` — all LFS-tracked |
| `blender/` | `.blend` sources (LFS), excluded from Godot import via `.gdignore` |
| `tools/` | Setup and repo-config scripts |

## Blender pipeline

Keep `.blend` sources in `blender/`, export `.glb` to `assets/models/`. Godot never imports the sources directly.
