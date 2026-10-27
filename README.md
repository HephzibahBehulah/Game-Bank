# Hephzibah Behulah Game Bank

A growing, branded library of individual browser games. Every released game has its own page and launcher entry; the home page is the game catalog.

## Games currently playable

1. NEON PULSE — RGB LED light design
2. CIRCUIT RUSH — wire-path puzzle
3. OHM HUNTER — electrical engineering quiz
4. VOLT DODGE — arcade obstacle dodger
5. RESISTOR MATCH — component memory game
6. CAPACITOR CHARGE — timing challenge
7. BINARY FLASH — binary decoding
8. FUSE BOX — electrical logic puzzle
9. GOAL LINE — football penalty shootout
10. APEX CIRCUIT — top-down traffic-dodging time trial

## Play and progression

Open the catalog and select a game. The current games have 10,000 numbered, increasingly difficult levels per title. Level progress is stored locally in that browser, so it does not yet sync between devices or accounts. Numbered levels are game stages, not 10,000 distinct game titles.

**GOAL LINE:** choose one of nine goal zones and take five penalty kicks. Score at least three goals to unlock the next level. The keeper's position changes each kick and difficulty is seeded from the current level.

**APEX CIRCUIT:** start a race and use left/right arrows, A/D, or the on-screen steering buttons to change lanes. Avoid traffic and reach the finish. A collision lets you retry the same level.

## Desktop launchers

On Windows, run `install-launchers.ps1`. It creates one named Internet Shortcut per catalog game in the Desktop folder `Game Bank Launchers`. A browser page cannot create desktop files without this explicit local action. The script currently lists all 10 games.

## Run and publish

The games use standalone HTML, CSS, and JavaScript. Open `index.html` in a modern browser for local play. GitHub Pages publishes the `main` branch from the repository root; a main-branch push triggers publication. Check the Actions deployment and verify the live site before announcing a release.

## Roadmap and limits

The current release contains **10 individual game titles**, not 10,000. A large library will be added in tested batches; repeating level seeds or renaming templates does not count as distinct games. Shared accounts, cloud saves, admin controls, trusted score verification, six-provider AI competition, downloadable native apps, and PlayStation releases are not implemented. AI-provider responses require authorized provider APIs and protected server-side credentials. PS5/PS6 publishing requires platform-holder development access and approval; browser games are not native console titles.
