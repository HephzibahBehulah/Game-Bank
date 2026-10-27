# Hephzibah Behulah Game Bank

A growing library of individual browser games. GitHub Pages publishes the catalog and every released game page.

## Current catalog titles

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
11. WORLD FOOTBALL — interactive 2D club/international match
12. CORTEX PRIME — sequences, matrices, hidden-rule reasoning
13. SYNAPSE SPRINT — working-memory sequence challenge
14. BILLIONAIRE CHALLENGE — 15-question quiz ladder with lifelines
15. TACTICS GRID — turn-based 8×8 squad tactics against a legal-move heuristic AI
16. APEX STRATEGY — 10-lap race manager with tyre, fuel, aggression, pit, weather and incident strategy
17. PENALTY PRO — 10-round adaptive penalty shootout; keeper and striker tendencies update from player direction choices
18. DEBATE ARENA — three-round debate with authored replay responses and a transparent scoring rubric
19. CASEFILE — three deterministic mysteries with suspect interviews and a ten-question accusation limit
20. MARKET DUEL — 30-day fictional stock-market game versus an observable moving-average AI
21. AI ARENA — sends a prompt concurrently to ChatGPT, Gemini, DeepSeek, Claude, Grok and Ollama; authenticated players compare live answers and save ratings through a protected API
22. LAST SIGNAL — top-down survival battle with nine tactical bots, field supplies, solid cover, and a closing safe zone

## Progression

Current titles have per-game 10,000-stage progression saved in the browser. The requested **100,000 individual titles are not complete**; a stage counter does not count as a separate game. Titles are added as individually designed and tested games, not template relabels.

## Football scope and rights

WORLD FOOTBALL currently provides a 2D arcade match and official team-name selections for LaLiga 2026/27, the UEFA Champions League 2026/27 league phase, UEFA Nations League 2026/27 League A, and FIFA World Cup 2026. It does **not** yet contain verified real-player rosters or licensed player likenesses; the requested Ronaldo/Messi/Okocha/Pogba/Osimhen and Chelsea/Bayern/Manchester United player matches remain in progress. The screenshots supplied were search-result pages containing stock-photo previews and watermarks, not licensed image files, so they are not embedded in the game. Player photos, club crests, kits, and console/store release need appropriate rights and platform approvals. The project is not an official licensed football game.

## IQ and quiz games

CORTEX PRIME generates deterministic sequence, matrix and rule-decoding challenges. SYNAPSE SPRINT tests digit recall with growing length and shorter display intervals. BILLIONAIRE CHALLENGE provides original calculations, logic and curated fact questions, three per-run lifelines, safety-net prize tiers and local best-score storage. It is an independent quiz game and is not affiliated with a television quiz brand.

## AI competition

AI ARENA is catalog item 21 (game22/). Its page supports account sign-in, concurrent provider matches, per-answer ratings, history, and optional speech-to-text. It never presents replay fixtures as real model output. The API is separate from GitHub Pages and must be deployed with AI_MODE=live, production JWT and CORS settings, provider keys and active model identifiers. Each cloud competitor uses its own server-side provider API; Ollama requires a configured reachable endpoint. Without that configured API, the page reports that live play is unavailable.
## Controls and launchers

WORLD FOOTBALL uses WASD/arrows, P to pass, Space to shoot, on-screen touch arrows and mouse selection. GOAL LINE is a penalty shootout; APEX CIRCUIT is an arcade racer. Run `install-launchers.ps1` on Windows to create shortcuts for all released browser games and Godot launchers for completed couch-suite games in `Desktop/Game Bank Launchers` when the local Godot runtime is available. TACTICS GRID uses an adaptive local heuristic opponent and needs no network or API key. APEX STRATEGY simulates six fictional drivers for ten laps; strategy calls change lap times, pit time, fuel, tyre wear, and event risk. PENALTY PRO resolves five shots and five saves with visible, adaptive directional probabilities. DEBATE ARENA runs offline with authored response fixtures and a rule-based scoring rubric; it does not claim a live language model. CASEFILE runs locally with three consistent authored mysteries and no live LLM claim. MARKET DUEL uses fictional prices and a local crossover strategy; it is not connected to securities markets.

## Build and publish

The project is plain HTML/CSS/JavaScript. Open `index.html` for the catalog. GitHub Pages publishes `main` from the repository root. Verify the Actions build/deploy and cache-busted public pages after each main-branch update.

## Console and account roadmap

User accounts, cloud-synced progress, admin controls, multiplayer, secure AI provider deployment, native iOS/Android/Windows packages and PS5/PS6-native games have not been delivered. Native console releases require platform-holder developer access, approved tooling, licensing and certification; a browser game is not a native PlayStation title.

