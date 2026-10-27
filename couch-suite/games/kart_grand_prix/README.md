# Kart Grand Prix

A complete local split-screen arcade racing cup for the Hephzibah Behulah Couch Game Bank. It includes eight authored circuits, eight handling profiles, six rule-based AI rivals, three difficulty tiers, drift-earned boosts, item boosts, three-lap races, race points, and a four-race cup.

## Run

1. Install Godot 4.7 or newer.
2. Open `couch-suite/project.godot` in Godot and run the project.
3. Select **Kart Grand Prix** from the hub and press A / Enter to begin.
4. Connect up to two controllers before starting. The first two connected pads control Player 1 and Player 2. Keyboard controls are available as fallback.

## Controls

| Action | Player 1 | Player 2 | Gamepad |
|---|---|---|---|
| Steer | A / D | Left / Right | Left stick |
| Accelerate | W | Up | RT or A |
| Brake | S | Down | LT or B |
| Drift | X | . | X |
| Use boost item | Q | / | LB |
| Choose kart | Left / Right | Left / Right | D-pad |
| Change selected player | Tab | — | Back / Select |
| Change AI difficulty | Up / Down | — | D-pad up / down |
| Start / confirm | Enter | Enter | A |
| Pause / resume | Escape / Enter | Escape / Enter | Start |

The race uses side-by-side shared-screen views. Each player can see all eight racers from their own half. A drift held for 0.65 seconds earns a boost charge when released. Finishing positions earn 15, 12, 10, 8, 6, 4, 2, and 1 cup points.

## Cup and scoring

The four-race cup rotates through four distinct authored tracks. A full race ends when the first racer completes three laps; all racers are ranked by distance travelled at that moment. Cup scoring is accumulated by racer identity, and ties are resolved by the lower racer slot. AI rivals target a difficulty-scaled speed, slow on alternating authored route segments, and adjust pace with a bounded catch-up factor based on the leading human racer.

## Save data

Kart Grand Prix saves completed cups, player cup wins, best cup points, difficulty, and track seed to `user://kart_grand_prix_progress.json`. The save is local to this installation; it does not claim online accounts or cloud sync.
