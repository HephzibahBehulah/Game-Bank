# DRONE RACING — TEST GUIDE

Run with Godot 4.7.2:
Godot_v4.7.2-stable_win64_console.exe --headless --path couch-suite --script res://tests/test_drone_racing.gd

## Full race
1. Launch the hub and choose Racing → Drone Racing.
2. Start with A/Cross. Use one or two controllers, or the keyboard layouts on the briefing screen.
3. Fly through the cyan gates in the numbered order. An out-of-order pass does not advance your route.
4. Monitor battery; save RB/Shift boost for straights, and avoid the red wind-hazard markers.
5. Complete three laps; compare lap, gate and score standings and the winner.
6. Win to unlock the next of five circuits, then relaunch and confirm career progress persists.

Automated checks fly every ordered gate for three laps on all five courses, confirm gate scoring, battery use, gamepad start/pause, save progression and hub registration. Controller hardware is needed to verify physical-stick calibration.

