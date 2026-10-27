# Kart Grand Prix playthrough check

1. Run the project and confirm the hub lists Kart Grand Prix as launchable.
2. Launch it, select either player with Tab / gamepad Back, change both kart choices, and change difficulty.
3. Start the cup. Confirm the two-player split view, 8 racers, track name, lap counter, and continuous AI movement.
4. Accelerate, steer, brake, drift for at least 0.65 seconds, release to earn a boost, and use the item button.
5. Pause and resume using Start (or Escape / Enter). Confirm the race does not progress while paused.
6. Finish a race and verify all eight racers appear in correct finishing order with race points.
7. Continue through all four races; verify distinct circuit names, cumulative standings, and a named cup champion.
8. Return to the hub and launch the game again.

## Automated checks

Run the test script with the Godot executable from the project folder:

```powershell
godot --headless --path couch-suite --script res://tests/test_kart_grand_prix.gd
```

The automated check simulates full finishes on all eight tracks and validates the eight-racer points table and four-race cup flow. A real physical controller must still be connected for the manual controller-input steps.
