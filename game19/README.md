# CASEFILE

A browser deduction game with three authored mysteries. Inspect each briefing, interview suspects, track a 10-question limit and accuse the culprit. Suspects answer from consistent, scenario-specific facts only when asked about relevant categories.

## Run
Open index.html or serve the repository root with python -m http.server 8000 and visit /game19/.

## Play
Start the case. Choose a suspect and ask a specific question about time, location, motive, keys or access, or evidence. Vague questions return no case detail. Use the evidence to accuse a suspect; the solution and the complete fact record appear on the end screen. New Case advances to another scenario.

## Test
Run node --test test.js. Tests cover all three single-culprit scenarios, relevant and irrelevant questions, the 10-question limit, and accusation outcomes.

## Scope
All dialogue and case facts are authored locally and deterministic. The suspect simulation does not call a live LLM. The mysteries and characters are fictional.
