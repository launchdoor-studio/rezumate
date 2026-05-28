# Rezumate — Current Project Status & TODO

*Architecture Decision Update:* To maximize user privacy and minimize infrastructure costs, **raw uploaded PDFs/DOCXs and exported PDFs are processed entirely in memory and immediately discarded.** We only persist structured JSON data and text in the PostgreSQL database. Therefore, cloud object storage (like AWS S3 or Supabase Storage) is completely excluded from the MVP.

---

## 1. Backend Status (FastAPI + PostgreSQL) - **COMPLETED**

The API layer is fully robust, deterministic, and ready for frontend integration.

- [x] Migrate to strict API-only structure (removed Jinja2/HTML templates).
- [x] Initialize PostgreSQL database models using UUIDs and JSONB (`Users`, `Resumes`, `JobDescriptions`, `ResumeVariants`).
- [x] Implement deterministic ATS scoring service (`app/services/ats_service.py`).
- [x] Refactor AI rewrite service to output strict JSON schemas and reduce LLM overhead.
- [x] Build `POST /api/upload` endpoint with `PyMuPDF` (PDF) and `python-docx` (DOCX) memory-only parsing.
- [x] Build `POST /api/analyze` endpoint to generate ATS scores and persist analysis history.
- [x] Build `POST /api/rewrite-bullet` endpoint for targeted AI bullet improvements.
- [x] Build `GET /api/history` and `GET /api/variants/{id}` endpoints for retrieving saved tailoring sessions.
- [x] Build `POST /api/export` endpoint using `reportlab` to generate ATS-safe PDFs purely from database JSON.
- [x] Stub out `auth_service.py` to enforce daily usage limits.
- [x] Write and pass automated unit tests for parsing degradation and ATS score determinism.

**Remaining Backend Minor Tasks:**
- [ ] *Integration Tests:* Write `TestClient` tests simulating the full upload -> analyze -> export flow.
- [ ] *Auth Wiring:* Replace the dummy user UUID in `auth_service.py` with actual JWT validation once the React Native frontend implements Supabase Auth login.

---

## 2. Frontend Status (React Native + Expo) - **NOT STARTED**

The entire mobile application needs to be scaffolded and wired up to the FastAPI backend.

- [ ] **Scaffolding:** Initialize Expo project with NativeWind (Tailwind), React Navigation, and Zustand.
- [ ] **Auth Flow:** Implement Supabase Auth (Email/Password or OAuth) screens (Login, Signup).
- [ ] **Core Upload Flow (Analyze Tab):**
  - [ ] UI for Document Picker to select PDF/DOCX from the phone.
  - [ ] UI text area to paste the Job Description.
  - [ ] Connect to `POST /api/upload` and `POST /api/analyze`.
  - [ ] Render the loading skeleton.
- [ ] **Analysis Results UI:**
  - [ ] Build the circular progress ATS score card.
  - [ ] Build the matched/missing skills grid.
  - [ ] Build the "Weak Bullets" warning cards.
- [ ] **AI Rewrite UI:**
  - [ ] Implement a bottom sheet or modal to show a weak bullet.
  - [ ] Connect to `POST /api/rewrite-bullet` and display the 3 AI suggestions.
  - [ ] Add "Accept" logic to update the local variant state.
- [ ] **History & Variants (Resumes Tab):**
  - [ ] Connect to `GET /api/history` to list past tailored resumes.
  - [ ] Build swipe-to-delete or management UI.
- [ ] **Export Flow:**
  - [ ] Connect to `POST /api/export` and trigger the native iOS/Android file share/save dialog.
- [ ] **Profile & Monetization (Profile Tab):**
  - [ ] Show remaining daily free limits.
  - [ ] Build a static Paywall screen outlining the Pro tier benefits.

---

## 3. DevOps & Deployment - **NOT STARTED**

- [ ] Deploy PostgreSQL database (e.g., Supabase DB or Neon).
- [ ] Deploy FastAPI backend (e.g., Render, Railway, or DigitalOcean).
- [ ] Securely configure production environment variables (Groq API keys, DB connection strings).
- [ ] Build and submit the Expo app to TestFlight / Google Play internal testing.
