# LAST SIGNAL — TEST GUIDE

Run automated rules with `npm test` from this directory.

## Full browser playthrough
1. Open `/game21/` in a modern browser and confirm the drop screen, map, roster, cover, and HUD render.
2. Start by button and again with Enter; each start resets the timer and creates ten living contestants.
3. Move with WASD and arrows. Aim with mouse and fire by click, Space, and a gamepad A/RT binding.
4. Collect a visible ammo box and med-kit; confirm ammo or health changes and the pickup disappears.
5. Confirm bots move, fire, take cover-obstructed shots, get eliminated, and update the live roster/feed.
6. Stay within the shrinking safe zone; then deliberately leave it and confirm health decreases.
7. Finish a full match by surviving or being eliminated. Confirm result text, winner, elimination count, and Play Again.
8. Use New Drop and verify the opening screen returns without a page reload.

A hardware controller is required to certify physical gamepad behavior. Keyboard/mouse coverage does not substitute for that check.
