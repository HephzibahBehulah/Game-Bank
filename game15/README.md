# TACTICS GRID

A browser turn-based tactics game on an 8×8 board. The player commands three units against three opponents. Each side activates every surviving unit once per round. Units move up to two squares or attack a visible opponent within three squares; each hit removes one of three health points. Amber cover blocks movement and line of sight.

The opponent is an active local heuristic, not a fixed script: it evaluates legal attacks, target health, distance, exposure to return fire, and nearby cover after every player phase. It requires no API key and works offline.

## Run

Open `index.html` in a modern browser, or serve the repository root with `python -m http.server 8000` and open `/game15/`.

## Controls and objective

Start the mission. Select a ready squad member, then click a highlighted square to move or a highlighted hostile to attack. Each player activation allows one move or one attack. Eliminate the hostile squad to win; if all three of your units are eliminated, the match ends in defeat. Restart begins a new encounter.

## Test

From this folder run `node --test test.js`. The suite checks legal movement, activation rules, cover/line-of-sight, AI decisions, and a complete round transition.

## Scope

This is a fictional tactical board game, not military training, a real-time shooter, or a console game. There are no external assets.
