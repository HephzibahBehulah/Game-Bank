# MARKET DUEL

A 30-day portfolio competition. Player and opponent start with $10,000. Trade five fictional stocks whose prices follow a seeded random walk plus news shocks. The opponent uses a visible three-day/six-day moving-average crossover strategy. Portfolio marks, holdings and AI order log update as days advance.

## Run
Open index.html or serve the repository root with python -m http.server 8000 and visit /game20/.

## Play
Open Market, select a fictional company and whole-share quantity, then buy or sell. Your cash and share ownership are checked before orders execute. Advance each day to update prices and let the opponent trade. The thirtieth close compares portfolio values and declares the winner.

## Test
Run node --test test.js. Tests cover starting capital, share accounting, blocked orders, seeded reproducibility, AI trading, and the 30-day finish.

## Scope
All companies and prices are fictional simulation data. This is not financial advice, a live market feed, or real-money trading.
