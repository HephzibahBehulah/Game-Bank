# Formula Sprint playthrough check

1. Run the hub and confirm Formula Sprint is launchable; select each of the five circuits.
2. Start a race and verify both split-screen views, 8 cars, lap counter, speed, tyre and fuel telemetry.
3. Drive with two keyboards, then connect two gamepads and check left-stick steering, RT throttle, LT brake, Start pause, and X pit input.
4. Queue a pit stop away from the start line. Confirm the request waits for the pit zone, then enters the wheel-gun timing sequence.
5. Complete four lug timings. Confirm clean hits, misses, service-time penalty, tyre reset, and refuel.
6. Finish all 10 laps. Confirm all eight finishers are ranked and podium status reflects a player in the top three.
7. Exit and relaunch; verify career totals and best finish persist.

## Automated checks

```powershell
godot --headless --path couch-suite --script res://tests/test_formula_sprint.gd
```

The automated checks cover all five circuit geometries, 10-lap completion, two human slots and six AI rivals, timed pit-stop service and resource restoration, gamepad start/pause events, race results, and local career save. Analog controls require a physical controller for hardware confirmation.
