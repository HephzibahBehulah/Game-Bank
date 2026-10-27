# LAST SIGNAL

A top-down, ten-contestant battle-royale survival game. You fight nine locally simulated competitors, collect ammunition and med-kits, use fixed cover, and stay inside a shrinking safe zone. Each bot follows one of three explicit policies: aggressive hunter, loot-seeking scavenger, or distance-keeping survivor. All match outcomes are simulated locally; no live players or licensed characters are implied.

## Run
Open `index.html` through a static web server (for example, `python -m http.server 8000`) and visit `/game21/`. ES modules require HTTP(S); opening the file directly may be blocked by the browser.

## Controls
- WASD or arrow keys: move.
- Mouse: aim; click the arena to fire.
- Space or Enter: fire continuously while held.
- Gamepad: left stick to move, A or RT to fire, Start to begin.

Collect gold ammo boxes and green med-kits by walking over them. The red dashed ring is the safe boundary. The match ends when one contestant remains or the final storm closes.

## Progress
Kills and match results are shown for the current match. This standalone game does not claim cloud account or cross-device save support.
