# SOAPBOX DERBY — TEST GUIDE

Run the full automated checks with Godot 4.7 from the project directory:
`Godot_v4.7.2-stable_win64_console.exe --headless --path couch-suite --script res://tests/test_soapbox_derby.gd`

## Full match
1. Launch the game from the hub's Racing category and verify only course 1 is initially unlocked.
2. Start with A/Cross. Confirm the gravity-powered cart moves without an accelerator control.
3. Steer toward each amber gate marker before reaching it; check the gate count and score increase.
4. Avoid each red hazard marker. Brake and steer away if the approach is fast or stability is low.
5. Finish the course. Verify time, score, gate count, medal, and next-course unlock.
6. Pause/resume with Start/Options and return to selection with B/Escape.
7. Relaunch and confirm saved career counts, unlocks, and best times remain.

Automated coverage simulates a full clean line on all eight routes, verifies every gate and hazard, checks a crash DNF, gamepad start/pause, hub integration, and save reload. A physical controller is needed to certify hardware analog behavior.
