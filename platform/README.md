# Game Bank API and AI Arena gateway

The GitHub Pages site is static. AI Arena needs this separate authenticated API service to hold provider credentials and call model providers. Never put provider keys in game files or commit a real environment file.

## Configure locally

1. Copy .env.example to .env.
2. Set a unique random JWT_SECRET with at least 32 characters.
3. Set CORS_ORIGINS to the exact published Game Bank origin.
4. Set AI_MODE=live.
5. Configure each provider key and model pair. ChatGPT uses OpenAI, Claude uses Anthropic, Gemini uses Google, and DeepSeek and Grok connect directly to their provider APIs. Model identifiers are operator-configured because vendor availability changes.
6. Run docker compose -f docker-compose.api.yml up --build.
7. Visit /api/health and confirm each required provider is true. Open /game22/, choose Connection, and enter the API origin.

No live provider credentials are available in this workspace. Until keys and an API hosting target are configured, public matches correctly return provider-unavailable states instead of fabricated text. GitHub Pages cannot securely host server-side API keys. The API-only compose file is for a Docker host; Cloudflare Workers requires a compatible non-container gateway implementation and Cloudflare secrets.

## Security notes

- Store .env only on the API host. The repository ignores it.
- Production startup rejects weak or placeholder JWT secrets.
- The API limits each signed-in account to three matches per minute and saves answer ratings.
- Configure HTTPS and restrict CORS to the production site. CORS is not authentication; account tokens protect API routes.
- Provider requests can incur charges and receive user prompts. Review each provider account's terms and privacy settings.
- Admin bootstrap requires explicit ADMIN_EMAIL and ADMIN_BOOTSTRAP_TOKEN; never publish the bootstrap token.