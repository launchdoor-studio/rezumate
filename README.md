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
- `mobile/` - legacy Expo/React Native app kept temporarily until native iOS parity is fully verified.

## Backend

```bash
uv sync
uv run dev
```

The API runs at `http://127.0.0.1:8000`.

Important environment variables:

- `DATABASE_URL` - production database URL. Local development falls back to `rezumate.db`.
- `GROQ_API_KEY` - enables AI bullet rewrites.
- `SESSION_SECRET` - signs Rezumate app session tokens.
- `APPLE_BUNDLE_ID` - validates Sign in with Apple token audience in production.
- `ALLOW_DEV_APPLE_AUTH` - set to `true` only for local `dev-apple-token:*` auth.

Key endpoints:

- `GET /api/health`
- `POST /api/auth/apple`
- `POST /api/upload`
- `POST /api/analyze`
- `POST /api/rewrite-bullet`
- `GET /api/history`
- `GET /api/variants/{variant_id}`
- `POST /api/export`

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
