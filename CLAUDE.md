# Cockroach Game

Godot 4.4+, GDScript only (no C#). 3D rendering, gameplay locked to the XZ plane.

## Layout

- `scenes/<feature>/*.tscn` — one folder per feature; main scene is `scenes/main/main.tscn`
- `scripts/` — GDScript
- `assets/` — imported runtime assets (glTF in `models/`, plus `textures/`, `audio/`)
- `blender/` — `.blend` sources, never imported (`.gdignore`); export `.glb` to `assets/models/`

## Rules

- snake_case for files/dirs, PascalCase for node names
- Typed GDScript (`:=`, typed params/returns)
- Input via actions defined in `project.godot`, never hardcoded keys
- Movement/physics in `_physics_process`
- Code must pass `gdformat --check` and `gdlint` (scripts/, tests/)

## Workflow

- Every change: Issue → branch `feat/<issue#>-slug` → one PR (`Closes #N`) → squash merge
- Merge gates: CI green (Lint, Tests), Codex review resolved, playtest checklist in PR done
- Merging never releases. Release = Actions → Release workflow with a `vX.Y.Z` tag
- Never push to main directly

## Testing

- gdUnit4, suites in `tests/*_test.gd`; scene behavior via `scene_runner`
- Every gameplay feature gets at least one scene_runner test
- Headless run: `./addons/gdUnit4/runtest.sh -a tests`
