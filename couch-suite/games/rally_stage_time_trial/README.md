# Rally Stage Time Trial

A solo point-to-point rally campaign with 10 individually routed stages, pace notes, target-time qualifications, locked-route progression, and locally saved career times. No opponent is included, matching the game brief; the challenge is the course, pace-note reading, and target clock.

## Run

1. Install Godot 4.7 or newer.
2. Open `couch-suite/project.godot` and run the project.
3. Choose an unlocked route with Left / Right, then press A / Enter.
4. Finish the route at or below its displayed target to unlock the next stage.

## Controls

| Action | Keyboard | Gamepad |
|---|---|---|
| Accelerate | W | RT |
| Brake | S | LT |
| Steer | A / D | Left stick |
| Handbrake | Space | B / Circle |
| Start / continue / retry | Enter | A / Cross |
| Select route | Left / Right | D-pad |
| Pause / resume | Escape / Enter | Start / A |

The stage screen reports the current co-driver instruction (for example, “LEFT 3 TIGHTENS”), elapsed and target time, speed, road position, and route progress. Each bend carries momentum toward the outside edge, so steering input is needed to hold the racing line through corners. Steering too far outside the road costs speed. A handbrake increases lateral response and braking.

## Career progress

The game records unlocked stages and best times in `user://rally_stage_progress.json`. The save is local to the current installation.
