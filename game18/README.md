# DEBATE ARENA

Three-round argument game. Choose a topic, write a position, and compare it with a curated topic-specific replay counterargument. A transparent rule-based rubric estimates logic, evidence and rhetoric. Best of three rounds wins.

## Run
Open index.html, or serve the repository root with python -m http.server 8000 and visit /game18/.

## Play
Start the debate, select one of five topics and write at least 20 characters. Submit to see structured scores and the opponent response. Complete three rounds for the final result. New Debate or Play Again resets the match.

## Test
Run node --test test.js. Checks cover topic fixtures, rubric shape and range, round scoring, complete best-of-three, and invalid input.

## Scope
Runs offline with authored replay arguments and a rule-based rubric. It does not claim live LLM responses, expert adjudication, or fact-checking.
