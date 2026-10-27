# PENALTY PRO

A complete ten-round penalty shootout. You take five kicks, then control the goalkeeper for five rounds. The keeper increases its probability of diving toward directions you have used; the AI striker shifts toward directions you defend less often. Probability bars show both tendencies live.

## Run
Open index.html, or serve the repository root with python -m http.server 8000 and open /game17/.

## Play
Select Start Shootout. Pick a direction for each of your first five penalties, then choose a dive direction for each of the last five AI penalties. Score, feed, and tendency bars update after each kick. Round ten displays the final result. New match resets the game.

## Test
Run node --test test.js. Checks adaptive tendencies, the complete match, score finish, and invalid actions.

## Scope
Players and cup are fictional. This is a probability-based sports game, not a licensed football simulation.
