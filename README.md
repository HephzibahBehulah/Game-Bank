# Hephzibah Behulah Game Bank

A growing library of individual browser games. GitHub Pages publishes the catalog and each game's page.

## Currently playable games

1. NEON PULSE — RGB LED light design
2. CIRCUIT RUSH — wire-path puzzle
3. OHM HUNTER — electrical engineering quiz
4. VOLT DODGE — arcade obstacle dodger
5. RESISTOR MATCH — component memory
6. CAPACITOR CHARGE — timing challenge
7. BINARY FLASH — binary decoding
8. FUSE BOX — electrical logic puzzle
9. GOAL LINE — football penalty shootout
10. APEX CIRCUIT — arcade traffic-dodging race
11. WORLD FOOTBALL — keyboard/touch 2D football match and season ladder

## Football game data

WORLD FOOTBALL includes selectable LaLiga EA Sports 2026/27 clubs, UEFA Champions League 2026/27 league-phase clubs, UEFA Nations League 2026/27 League A nations, and the 48 FIFA World Cup 2026 qualified teams. These names and competition groups are based on official competition pages and can change with eligibility and licensing. The game is an independent educational arcade simulation, not an official licensed product; it does not include licensed club badges, official player rosters, live fixtures, or real-world results.

## Controls and progress

WORLD FOOTBALL: move the highlighted player with WASD or arrows, pass with P, shoot with Space. Click a teammate or press 1–9 to change player. Win the 90-second match to clear the current stage. Use the touch arrow controls on mobile.

GOAL LINE: select one of nine target zones and score at least three of five penalties.
APEX CIRCUIT: steer with arrows/A-D or touch controls and avoid traffic through the finish.

Each current game uses a 10,000-stage progression counter. This is not 10,000 distinct game titles. Progress is stored locally in the browser and is not synced between devices or users.

## Desktop launchers

Run `install-launchers.ps1` on Windows to create one named Internet Shortcut per current game in `Desktop/Game Bank Launchers`. The script now lists all 11 released games.

## Run and publish

The project uses plain HTML/CSS/JavaScript. Open `index.html` for the catalog. GitHub Pages publishes the `main` branch from the repository root; a push to `main` triggers the build and deployment. Inspect the successful Actions deployment and verify the cache-busted public page after each release.

## Not yet delivered

The library currently has **11 titles**, not 100,000. New titles must be individually designed and tested; multiplying seeds or relabeling templates does not create distinct games. The requested real-time AI competition is not connected to ChatGPT, Gemini, Grok, DeepSeek, Claude, or Ollama yet. Secure provider APIs require a private gateway and provider credentials; never place API keys in browser code. User accounts, shared cloud progress, an admin dashboard, native mobile/store builds, and native PS5/PS6 titles are not implemented. Console release needs platform-holder access and approval.

## Competition sources

- [LALIGA clubs 2026/27](https://www.laliga.com/en-US/laliga-easports/clubs)
- [UEFA Champions League teams 2026/27](https://www.uefa.com/uefachampionsleague/news/02a8-2171a88881a0-c70193b972c6-1000--meet-the-2026-27-champions-league-league-phase-teams/)
- [UEFA Nations League 2026/27](https://www.uefa.com/uefanationsleague/news/0298-1d6ef1acfaef-b54fcf1da859-1000--2026-27-uefa-nations-league-all-you-need-to-know/)
- [FIFA World Cup 2026 qualified teams](https://www.fifa.com/en/tournaments/mens/worldcup/canadamexicousa2026/articles/world-cup-2026-who-has-qualified)
