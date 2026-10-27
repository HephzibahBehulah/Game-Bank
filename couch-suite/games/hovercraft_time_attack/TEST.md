# HOVERCRAFT TIME ATTACK — TEST GUIDE

Run the Godot 4.7 acceptance check from the repository root:
`Godot_v4.7.2-stable_win64_console.exe --headless --path couch-suite --script res://tests/test_hovercraft_time_attack.gd`

## Full race
1. Start the project hub and choose Racing → Hovercraft Time Attack.
2. Verify the course briefing identifies thrust, chop, wind and locked stages.
3. Start with A/Cross. Confirm thrust accelerates without a steering input.
4. Steer early through the amber gate target; verify clean-gate count and score.
5. Avoid each red buoy. Verify a direct collision lowers hull and speed.
6. Use boost and confirm its meter drains, then recharges when released.
7. Pause/resume with Start/Options; complete or wreck and verify distinct result states.
8. Finish the first course, check course 2 unlock, restart the app and verify career save recovery.

Automated checks complete a clean line on all eight authored courses, exercise boost and hull failure, simulate gamepad start/pause, and test unlock, persistence and hub registration. A physical controller is needed for hardware certification.

