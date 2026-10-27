# STOCK CAR OVAL — TEST GUIDE

Run from the repository root with Godot 4.7.2:
Godot_v4.7.2-stable_win64_console.exe --headless --path couch-suite --script res://tests/test_stock_car_oval.gd

## Full race
1. Launch the Godot hub and select Racing → Stock Car Oval.
2. Review the circuit banking, grip and length, then start with A/Cross.
3. Player 1 uses W/A/D/S; Player 2 uses arrows. Connect two controllers for simultaneous local play.
4. Follow six laps while watching running order, lap count and tire temperature.
5. Draft behind a rival on straights. Brake into turns if tires overheat; close contact damages cars.
6. Finish and inspect winner, six-car classification and best-lap time.
7. Confirm a player win unlocks the next of five circuits and persists after restart.

Automated checks drive a full six-lap race on all five circuits, validate the six-car results and lap timer, exercise gamepad start/pause, progression save and hub registration. Physical hardware is needed to validate controller calibration.

