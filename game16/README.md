# APEX STRATEGY

A ten-lap race-engineering strategy game. Manage three HB Racing drivers against three fictional rival drivers. Before each lap choose a tyre compound, fuel target, and aggression level for each teammate. The simulation accounts for driver skill/consistency, tyre grip and wear, fuel mass/consumption, pit-lane time, weather, safety cars, incidents, and repair stops. Lap times and the classification are calculated from the race state; there are no fixed winners.

## Run

Open `index.html` in a modern browser, or serve the repository root with `python -m http.server 8000` and open `/game16/`.

## Controls and objective

Set all three team strategies, then select Start Race / Run Lap. A tyre change or adding fuel after lap one costs 18 seconds. Higher aggression improves pace but raises the risk of incidents. Complete ten laps. HB Racing wins if one of its drivers is first; otherwise the leading fictional rival wins. Choose New Race to begin another seeded race.

## Test

Run `node --test test.js` in this folder. Tests cover setup effects, pit costs, deterministic weather/events, score ordering, and the complete ten-lap finish.

## Content and scope

Teams, drivers, circuit and race outcomes are fictional. This is a strategy simulation, not real-world motorsport data or a licensed racing title. No external art or data is used.
