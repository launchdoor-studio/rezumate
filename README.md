<div align="center">

<img src="web/public/rezumate-logo.png" alt="Rezumate logo" width="96" height="96">

# Rezumate

**Native iOS resume optimization powered by a FastAPI analysis backend.**

</div>

Rezumate helps job seekers upload a resume, paste a job description, get ATS-focused feedback, rewrite weak bullets, and export an ATS-safe PDF.

## Repo Layout

- `ios/` - native SwiftUI iOS app for App Store release.
- `app/` + `main.py` - FastAPI backend for auth, upload parsing, ATS scoring, rewrites, history, and export.
- `web/` - Next.js marketing website with privacy, terms, support, and waitlist pages.

## Backend

```bash
uv sync
uv run dev
```

The API runs at `http://127.0.0.1:8000`.

Important environment variables:

- `APP_ENV` - use `production` for deployed environments.
- `DATABASE_URL` - hosted PostgreSQL URL in production. Local development falls back to `rezumate.db`.
- `GROQ_API_KEY` - enables AI analysis refinement and bullet rewrites.
- `SESSION_SECRET` - signs Rezumate app session tokens.
- `APPLE_BUNDLE_ID` - validates Sign in with Apple token audience in production.
- `ALLOW_DEV_APPLE_AUTH` - set to `true` only for local `dev-apple-token:*` auth.

Create local tables or apply production migrations:

```bash
uv run alembic upgrade head
```

Key endpoints:

- `GET /api/health`
- `GET /api/ready`
- `POST /api/auth/apple`
- `GET /api/me`
- `POST /api/upload`
- `POST /api/analyze`
- `GET /api/analysis/{variant_id}`
- `POST /api/rewrite-bullet`
- `POST /api/accept-rewrite`
- `GET /api/history`
- `GET /api/variants/{variant_id}`
- `POST /api/export`
- `DELETE /api/account`

See [BACKEND_DEPLOYMENT.md](BACKEND_DEPLOYMENT.md) for production and Vercel deployment.

## Native iOS App

Open the Xcode project:

```bash
open ios/RezumateNative.xcodeproj
```

The Debug build points at `http://127.0.0.1:8000` through `REZUMATE_API_BASE_URL`. The app includes:

- Sign in with Apple plus a Debug-only local dev session.
- PDF/DOCX document picker upload.
- Job description analysis.
- Result screen with ATS score, keywords, weak bullets, rewrites, and PDF export/share.
- History and variant detail views.

Before App Store release, set the production bundle identifier/team, configure Sign in with Apple in the Apple Developer portal, and update the Release API URL.

## Marketing Website

```bash
cd web
npm install
npm run dev
```

The website includes the landing page, privacy policy, terms, support, and waitlist pages. It is intended to deploy separately from the API, for example on Vercel.

## Tests

```bash
uv run pytest
```

The backend tests cover upload, analyze, rewrite, history, variant detail, export, health checks, and the Apple auth session exchange.
