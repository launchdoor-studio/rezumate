# Rezumate — Improved Product & Implementation Plan

## 1. Product North Star

**Rezumate helps job seekers turn one generic resume into a role-specific, ATS-friendly resume in minutes.**

The core idea stays intentionally narrow:

1. Upload a resume.
2. Paste a job description.
3. Get a clear ATS-style analysis.
4. Improve weak resume content with AI-assisted suggestions.
5. Export or reuse a stronger, tailored resume.

The app should feel fast, focused, and practical. It should not become a full resume builder, job board, recruiter tool, or generic chatbot.

## 2. Current Product Positioning

The existing repo is already a lightweight FastAPI web app with:

- FastAPI routes for score, compare, rank, and chat workflows.
- Jinja2 templates and static CSS for the frontend.
- `pdfplumber` for PDF text extraction.
- Groq/LangChain structured AI responses.
- SQLite/Turso-compatible persistence through SQLAlchemy.
- Vercel-oriented deployment.

The immediate plan should improve this product into a polished web MVP first. A React Native app can remain a later distribution layer after the core workflow, scoring quality, and retention loop are proven.

## 3. Core Principles

- **AI-assisted, not AI-replacing:** AI may rewrite, explain, and suggest, but should not invent jobs, metrics, tools, or credentials.
- **Deterministic scoring where possible:** Keyword matching, section detection, measurable impact checks, and formatting checks should be rule-based and repeatable.
- **Structured AI output only:** LLM responses should be validated through Pydantic schemas before the UI renders them.
- **Low operating cost:** Use Groq/free-tier-friendly models carefully, cache repeated work, and avoid unnecessary calls.
- **Actionable feedback:** Every issue should explain what is wrong and what the user can do next.
- **ATS-safe output:** Exported resumes should prioritize parseability over visual decoration.

## 4. MVP Workflow

### Primary Flow: Score and Improve

1. User uploads a PDF resume.
2. User pastes a job description.
3. Backend extracts resume text and validates input quality.
4. Backend computes deterministic signals:
   - required keyword coverage
   - missing skills
   - weak bullet detection
   - measurable impact detection
   - section completeness
   - possible formatting risks
5. AI produces structured analysis and plain-language improvement advice.
6. UI renders:
   - match score
   - fit level
   - matched and missing skills
   - strengths
   - prioritized improvement suggestions
   - resume text preview
7. User can ask follow-up questions in chat using the same resume and JD context.

### Secondary Flows

- **Compare:** Compare two resumes against one JD and explain the stronger fit.
- **Rank:** Rank multiple resumes against one JD.
- **Chat:** Ask contextual questions about how to improve the uploaded resume.

These should support the core value proposition, not distract from it.

## 5. Recommended Architecture

### Frontend

Current direction:

- Jinja2 templates
- Vanilla JavaScript
- CSS in `app/static/css/styles.css`

Near-term frontend improvements:

- Keep the server-rendered app for MVP speed.
- Make the score page the flagship experience.
- Use structured result data to render real UI sections instead of long AI text.
- Add loading, error, empty, and partial-success states.
- Keep the interface dense, calm, and mobile-friendly.

Later, if traction is validated:

- Add a React Native/Expo client that consumes the same FastAPI API.
- Avoid rebuilding the backend until the workflow is stable.

### Backend

Current direction:

- FastAPI
- SQLAlchemy
- SQLite locally, Turso in production
- Groq via LangChain
- Pydantic schemas for structured results

Backend improvements:

- Split deterministic analysis into a dedicated service.
- Keep AI prompting in `ai_service.py`.
- Keep parsing in `pdf_service.py`, with explicit extraction quality reporting.
- Add durable analysis records with enough metadata to power history and caching.
- Add consistent API error responses for invalid files, empty extraction, model failures, and timeout cases.

### Storage

For the MVP and beyond:
- **No File Storage:** To maximize user privacy and minimize infrastructure costs, raw uploaded PDFs/DOCXs are processed in memory and immediately discarded.
- **Data Persistence:** Only the extracted raw text, job description text, structured analysis JSON, and tailored variants are stored in the PostgreSQL database.
- **Exporting:** Tailored resumes are generated as PDFs on the fly and streamed directly to the user without being saved to cloud storage.

## 6. Data Model

### Existing Table: `analyses`

Keep and expand:

- `id`
- `job_description`
- `resume_text`
- `result_json`
- `match_score`
- `created_at`

Recommended additions:

- `filename`
- `resume_hash`
- `job_description_hash`
- `extraction_status`
- `extraction_warnings`
- `deterministic_signals`
- `model_name`
- `latency_ms`
- `user_id` nullable for pre-auth MVP compatibility

### Future Tables

Add only when needed:

- `users`: authentication and plan tier.
- `resume_variants`: saved tailored versions.
- `chat_messages`: persisted contextual chat.
- `exports`: generated resume files and metadata.
- `usage_events`: rate limits and monetization enforcement.

## 7. API Plan

### Keep Existing Endpoints

- `POST /api/score`
- `POST /api/compare`
- `POST /api/rank`
- `POST /api/chat`

### Improve `POST /api/score`

Request:

- `resume`: PDF for MVP; DOCX/TXT can be added after parser support exists.
- `job_description`: required text.

Response:

- `analysis_id`
- `filename`
- `resume_text`
- `deterministic_signals`
- `result`
- `warnings`

Important behavior:

- Reject unsupported file types before reading the full upload.
- Return a clear error when extraction yields too little usable text.
- Save failed extraction metadata where useful for debugging.
- Never let an LLM failure erase deterministic analysis if deterministic analysis succeeded.

### Add Later

- `GET /api/analyses/{id}`
- `GET /api/history`
- `POST /api/rewrite-bullet`
- `POST /api/export`

## 8. AI Strategy

### Model Use

Use AI for:

- summarizing candidate fit
- generating targeted improvement suggestions
- rewriting bullets on user request
- answering contextual chat questions

Avoid AI for:

- basic keyword matching
- score calculation as the only source of truth
- file parsing
- usage limits
- fabricated metrics or unverifiable claims

### Prompting Rules

All resume-improvement prompts should enforce:

- preserve factual experience
- do not invent employers, degrees, tools, numbers, or achievements
- prefer concise bullet points
- use action verbs
- include metrics only if supplied or explicitly framed as placeholders
- explain missing keywords without telling users to keyword-stuff

### Caching

Cache or reuse results by:

- resume text hash
- job description hash
- prompt version
- model name

This reduces repeated model calls and makes the product cheaper to run.

## 9. Deterministic ATS Engine

Create a service, for example `app/services/ats_service.py`, that returns structured signals:

- extracted JD keywords
- matched keywords
- missing keywords
- partial matches
- bullet count
- weak bullet count
- bullets without measurable impact
- section presence
- likely formatting warnings
- estimated resume length

Scoring should be explainable:

- keyword coverage
- role requirement coverage
- impact quality
- structure/readability
- formatting risk

The exact score formula can evolve, but it must be deterministic, unit-tested, and versioned.

## 10. Resume Parsing Plan

### MVP

- Support PDF reliably with `pdfplumber`.
- Return extraction warnings for low text density, strange ordering, or empty pages.
- Normalize whitespace and preserve enough line breaks for section detection.

### Next

- Add DOCX support with `python-docx`.
- Add TXT support.
- Add parser fixtures for common resume layouts.

### Defer

- OCR for scanned resumes.
- Complex visual template reconstruction.
- Full resume editor based on parsed layout.

## 11. UI/UX Improvements

### Score Page

Make this the best page in the app:

- Clear upload + JD form.
- Strong loading state while parsing/analyzing.
- Score summary with fit level.
- Missing skills section.
- Matched skills with evidence.
- Prioritized improvements.
- Resume text preview.
- Contextual chat entry point after analysis.

### Compare and Rank Pages

Keep them useful but secondary:

- Show scores and clear winner/ranking.
- Explain differentiators.
- Avoid overwhelming charts.

### Chat Page

Chat should be contextual and bounded:

- Use the current resume and JD.
- Encourage specific improvement questions.
- Keep answers actionable and concise.

## 12. Monetization Plan

Do not monetize before the core score-and-improve flow feels trustworthy.

Free tier:

- limited analyses per day
- limited chat messages
- limited bullet rewrites

Pro tier:

- higher limits
- saved history
- resume variants
- export to ATS-safe PDF
- better models or deeper analysis

Implementation later:

- `usage_events` table
- simple rate-limit middleware
- Stripe or Lemon Squeezy checkout
- plan-aware API limits

## 13. Phased Execution

### Phase 1: Stabilize Current MVP

- Fix file support mismatch: either truly support DOC/DOCX/TXT or only advertise PDF.
- Add better validation for empty/low-quality extraction.
- Add deterministic ATS service.
- Merge deterministic signals with existing structured AI result.
- Improve error handling in all API routes.
- Add focused unit tests for parsing and scoring.

Acceptance criteria:

- Same resume + JD returns the same deterministic signals every time.
- Empty or unsupported resumes return useful errors.
- Score page works end-to-end locally without manual database setup.

### Phase 2: Make Results Actionable

- Redesign score results around structured sections.
- Add weak bullet detection.
- Add one-click rewrite endpoint for individual bullets.
- Add prompt constraints against fabrication.
- Store prompt version and model name with each analysis.

Acceptance criteria:

- A user can identify the top 3 resume changes in under 30 seconds after analysis.
- Bullet rewrites preserve the user’s original facts.
- The UI handles model failures gracefully.

### Phase 3: History and Retention

- Add analysis history.
- Add `GET /api/analyses/{id}`.
- Let users reopen past analyses.
- Add optional names/titles for analyses.
- Add basic deletion.

Acceptance criteria:

- Refreshing the page does not lose the latest analysis.
- A user can compare their recent scores over time.

### Phase 4: Tailored Resume Variants and Export

- Add resume variants.
- Let users accept/reject suggested bullet rewrites.
- Generate ATS-safe PDF export from structured content.
- Add export preview and validation.

Acceptance criteria:

- User can create a tailored variant from an existing analysis.
- Exported PDF is text-selectable and parseable.
- Export does not introduce tables, images, or layout that harms ATS parsing.

### Phase 5: Accounts and Monetization

- Add authentication.
- Add plan tier and usage limits.
- Add payment provider.
- Add Pro-only history depth, variants, and exports.

Acceptance criteria:

- Anonymous/local flow still works where intended.
- Paid limits are enforced server-side.
- Users never lose saved analyses after login.

## 14. Testing Strategy

### Unit Tests

- PDF text normalization.
- JD keyword extraction.
- deterministic score calculation.
- weak bullet detection.
- measurable impact detection.
- Pydantic schema validation.

### Integration Tests

- `POST /api/score` success path.
- unsupported file path.
- empty extraction path.
- AI failure fallback behavior.
- database save behavior.

### Manual QA Fixtures

Maintain sample resumes for:

- single-column resume
- two-column resume
- dense technical resume
- student resume
- resume with projects only
- low-quality/scanned PDF

## 15. Key Risks and Mitigations

- **LLM scores feel inconsistent:** make deterministic scoring the source of truth and use AI for explanation.
- **PDF parsing fails on real resumes:** collect fixtures, return extraction warnings, and add DOCX/TXT support.
- **Users distrust generic advice:** make suggestions quote or reference resume/JD evidence.
- **Costs grow too early:** cache by content hash and reserve AI rewrites for explicit user actions.
- **Product becomes too broad:** keep score-and-improve as the flagship workflow until retention is proven.

## 16. Definition of a Strong MVP

The MVP is ready to share when:

- Uploading a PDF and pasting a JD produces a useful result in under 60 seconds.
- The score is explainable and repeatable.
- Missing skills and weak bullets are clearly identified.
- AI suggestions are specific and do not fabricate experience.
- The UI works well on mobile and desktop.
- Past analysis data persists in local SQLite/Turso.
- The app can be deployed to Vercel with documented environment variables.
