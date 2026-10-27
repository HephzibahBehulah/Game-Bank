# Rally Stage Time Trial playthrough check

1. Open the Godot project and confirm the hub lists Rally Stage Time Trial as launchable.
2. Enter stage selection and inspect all 10 named routes. Only the first route should be unlocked for a fresh save.
3. Choose Route 1; start and drive with both keyboard and a connected controller.
4. Verify throttle, brake, steer, handbrake, timer, road boundaries, co-driver notes, and progress bar.
5. Beat the target. Confirm the result reports the time and unlocks exactly the next route.
6. Continue through all 10 point-to-point routes and reach the finisher screen.
7. Quit and relaunch. Confirm unlocked stage and best times persist.
8. Deliberately miss a target on an unlocked route; confirm it remains unlocked and can be retried.

## Automated checks

```powershell
godot --headless --path couch-suite --script res://tests/test_rally_stage_time_trial.gd
```

The automated test simulates all 10 routes at full throttle, checks qualification targets and progression, runs the scene through the finisher state, and checks the local save. A real controller must be connected to perform the hardware-input steps above.
