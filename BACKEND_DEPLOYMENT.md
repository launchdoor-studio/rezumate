# Backend Deployment

The backend is structured for Vercel Functions or a conventional Python host. Production startup fails closed when required security configuration is missing.

## Required External Configuration

Provision these outside the repository:

- Hosted PostgreSQL database.
- Groq API key.
- Apple Developer App ID and Sign in with Apple capability.
- Vercel project and `api.rezumate.app` DNS record.

Set these environment variables in the production environment:

```text
APP_ENV=production
DATABASE_URL=postgresql://...
GROQ_API_KEY=...
SESSION_SECRET=<at least 32 random bytes>
APPLE_BUNDLE_ID=com.rezumate.app
ALLOW_DEV_APPLE_AUTH=false
MAX_UPLOAD_BYTES=4000000
MAX_RESUME_CHARACTERS=100000
MAX_JOB_DESCRIPTION_CHARACTERS=30000
FREE_ANALYSES_PER_DAY=3
FREE_REWRITES_PER_DAY=3
```

Generate a session secret locally:

```bash
openssl rand -hex 32
```

## Database Migration

Run migrations against the production database before routing traffic:

```bash
DATABASE_URL="postgresql://..." uv run alembic upgrade head
```

Do not run `Base.metadata.create_all()` in production. Production startup expects migrations to have already been applied.

## Vercel

Create a Vercel project with the repository root as its root directory. Add the production environment variables, deploy, then connect `api.rezumate.app`.

The root `index.py` exports the FastAPI application through Vercel's detected FastAPI entrypoint. The root `vercel.json` excludes unrelated app/web/test files and allows up to 60 seconds for Groq refinement requests.

Analysis behavior is serverless-safe:

1. `POST /api/analyze` persists and returns a deterministic baseline quickly.
2. `GET /api/analysis/{variant_id}` performs pending Groq refinement inside the request.
3. The completed or failed result is persisted before the response returns.

No work depends on execution continuing after a serverless response.

## Release Checks

Run before deploying:

```bash
uv run pytest
DATABASE_URL=sqlite:////private/tmp/rezumate-migration-check.sqlite uv run alembic upgrade head
DATABASE_URL=sqlite:////private/tmp/rezumate-migration-check.sqlite uv run alembic check
```

After deploying:

```bash
curl https://api.rezumate.app/api/health
curl https://api.rezumate.app/api/ready
```

Expected responses:

```json
{"status":"ok"}
{"status":"ready"}
```

## Security Notes

- Development tokens are rejected whenever `APP_ENV=production`.
- Production requires a non-SQLite database, Groq key, session secret, and Apple bundle ID.
- Resume uploads are limited below Vercel's request-body limit.
- Account deletion removes the user and all owned resumes, job descriptions, and variants.
- AI provider failures return generic client errors while detailed exceptions remain in server logs.
