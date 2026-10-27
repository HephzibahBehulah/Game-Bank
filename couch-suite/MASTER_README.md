# Hephzibah Behulah Couch Game Bank — Godot Edition

This is a separate Godot 4 local-multiplayer project in the Game-Bank repository. The existing browser games remain in the repository root; this Godot project lives in `couch-suite/`.

## Requirements and launch

- Godot 4.7 or newer.
- Open `couch-suite/project.godot` and run the project (F6/F5 in the editor).
- Use the hub category filters to browse the 100-game roadmap. A game becomes launchable only when its implementation and playable test are complete. Kart Grand Prix, Rally Stage Time Trial, Formula Sprint, Truck Trial, Motorcycle Hill Climb, Soapbox Derby, Hovercraft Time Attack, Stock Car Oval, and Monster Truck Arena are the nine completed suite entries; the remaining games stay visibly locked until their implementations and playable checks are complete.

## Controllers

Connect controllers before entering a game. Gamepad bindings use standard Xbox / PlayStation layouts: left stick or D-pad for direction, bottom face button (A / Cross) to confirm and accelerate where appropriate, right face button (B / Circle) for secondary action or braking, left face button (X / Square) for drift/action, LB / L1 and triggers for modifiers, and Start / Options for pause. Keyboard fallback and each game's exact mapping are in that game's README.

## Tests and game status

Each completed game ships with `README.md` and `TEST.md`. Automated mechanics checks run headlessly where practical; hardware-specific controller behavior must be confirmed with a real pad. `../GAMES_STATUS.md` is the project-wide tracker and is updated when a game passes its acceptance checks. `../DECISIONS.md` records scope and implementation decisions.

## Project boundaries

This Godot suite is not the existing GitHub Pages web hub and does not claim a PlayStation 5 or PlayStation 6 build. Those consoles require official platform access, SDKs, and certification. Online AI competitions, real-world licensed football rosters and imagery, accounts, and an admin service require separate provider, licensing, identity, and hosted-backend work. They must not be represented as included unless implemented and verified.



