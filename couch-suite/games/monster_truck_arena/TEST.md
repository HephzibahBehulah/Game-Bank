# MONSTER TRUCK ARENA — TEST GUIDE

Run with Godot 4.7.2:
Godot_v4.7.2-stable_win64_console.exe --headless --path couch-suite --script res://tests/test_monster_truck_arena.gd

## Full round
1. Launch the hub, choose Racing → Monster Truck Arena, and review stadium surface and targets.
2. Start using A/Cross. Connect two pads or use W/A/D/S for player one and arrows for player two.
3. Accelerate into named breakable targets. Watch their health, your score and damage change.
4. Use boost to line up a fast impact. Hit the ramp at speed to earn airtime points.
5. Avoid the arena boundary and rival trucks; heavy contact adds damage.
6. Play for 90 seconds and compare the six-truck leaderboard and winner result.
7. Win to unlock the next stadium; restart and check that career progress remains.

Automated checks verify all five stadiums and six-truck fields, target destruction and scoring, stunt-ramp points, gamepad start/pause, result progression, save/reload and hub registration. Use physical pads to check stick calibration in a live session.

