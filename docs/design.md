# Kitchen Survival — design

## Pitch

You are a cockroach in a kitchen at night. Eat crumbs, stay out of the light, don't get squished.

## Pillars

1. **Light is danger, shadow is safety** — the whole game readable at a glance
2. **Small bug, huge world** — furniture is terrain; the floor is a landscape
3. **Short and silly** — dying is funny, restarting is instant

## Core loop

Scout from a hiding spot → sneak to a crumb → eat it → a light event happens (fridge opens, ceiling lamp flicks on, flashlight sweeps) → scatter to shadow → repeat, getting bolder and fatter.

## Mechanics roadmap (one issue each, in order)

1. **Isometric camera** — orthographic, fixed angle, follows the roach
2. **Kitchen graybox** — floor, counters, fridge, table legs as blockout shapes
3. **Light cones as danger** — standing in light fills a detection meter
4. **Crumbs + score** — pickups, a counter, maybe the roach visibly fattens
5. **The Slipper** — fail state when detection maxes out
6. **Real roach model** — Blender-authored glTF replaces the box placeholder
7. **Sound** — scuttling, fridge hum, the dreaded footsteps
8. **Menu + restart loop** — title screen, death screen, play again

## Non-goals (for now)

Multiplayer, save games, mobile builds, procedural levels.
