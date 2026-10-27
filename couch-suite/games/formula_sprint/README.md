# Formula Sprint

A local two-player split-screen championship across five authored circuits. Every race is 10 laps. Eight cars compete: the two players and six rule-driven AI rivals. Tyres lose grip and fuel is consumed with distance, so pit strategy matters. Race results include the full order, player podium outcome, service count, and remaining resources.

## Run

Open `couch-suite/project.godot`, select Formula Sprint from the hub, choose a circuit with Left / Right, and press A / Enter.

## Controls

| Action | Player 1 | Player 2 | Gamepad |
|---|---|---|---|
| Steer | A / D | Left / Right | Left stick |
| Throttle | W | Up | RT |
| Brake | S | Down | LT |
| Queue pit stop / wheel gun | F | . | X / Square |
| Start / confirm | Enter | Enter | A / Cross |
| Pause / resume | Escape / Enter | Escape / Enter | Start / A |

Request a stop at any point; it queues until the pit lane at the start/finish line. The car stops for a four-lug wheel-gun timing challenge. Press the pit key when the white moving marker crosses each green target. Missed lugs add service time. A completed service restores fuel and tyre condition. Players should monitor tyre and fuel status during the 10-lap race.

The six AI cars use a fixed driving policy, manage their racing line, and enter the pit automatically when fuel falls below 48% or tyre wear passes 48%. They service fuel and tyres while the player completes the wheel-gun minigame.

## Career save

Formula Sprint stores completed race count, player podium finishes, best player finishing position, and selected circuit in `user://formula_sprint_progress.json`.
