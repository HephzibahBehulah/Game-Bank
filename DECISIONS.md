# Project decisions

## 2026-10-27 — Keep the existing web catalog and couch suite separate

The published Game Bank is a static GitHub Pages site. The new 100-game couch suite requires Godot 4, gamepad input, and local multiplayer. Replacing the existing hub would risk breaking the shipped browser games and still would not make every proposed game playable. The Godot project will therefore live in `couch-suite/` as a separate project in this repository. Its web export can be linked from the existing hub after game content is complete and verified.

## 2026-10-27 — Use the stable Godot release for validation

Godot 4.7.2 stable was downloaded from the official Godot download page and verified headlessly. The portable runtime is kept under `.local-tools/`, ignored by Git, and is not part of the product deliverable.

## 2026-10-27 — Do not expose unfinished games as playable

Track all requested titles in `GAMES_STATUS.md`. Only register a game as launchable in the hub after its scene, gamepad controls, end state, and playthrough checks pass. The backlog may list unfinished titles, but the catalog must not pretend they are playable.

## 2026-10-27 — Save progress locally first

For the couch suite, persist cup points, best times, unlocked content, and settings in a local save file. Cloud accounts and cross-device sync remain separate pending platform work.

## 2026-10-27 — Truck Trial crane stages

The brief says the crane arm appears on two stages without naming them. Use courses 4 and 8 for the crane challenges. The remaining six courses focus on heavy-vehicle obstacle handling and safe rollover limits.
