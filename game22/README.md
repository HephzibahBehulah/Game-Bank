# AI ARENA

The Arena sends one prompt concurrently to ChatGPT (OpenAI), Gemini (Google), DeepSeek, Claude (Anthropic), Grok (xAI), and a configured Ollama model through the Game Bank API. Players compare live answers and rate them in their signed-in account. Speech recognition is available when supported by the browser.

## Run
1. Open Game Bank and choose AI ARENA (game 22).
2. Select **Connection** and enter the HTTPS URL of the deployed Game Bank API.
3. Create an account or sign in.
4. Ask a factual or creative question, compare the returned answers, and rate them.

The page never requests provider keys. Configure keys as server secrets. Unavailable providers are reported, never replaced with invented output.

Prompts are sent to configured model providers. Do not include passwords or private information.

