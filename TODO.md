# Rezumate TODO

This checklist is derived from `plan.md`. It is intended to be the working project backlog, while preserving the app's core idea: upload a resume, paste a job description, get ATS-style analysis, improve the resume, and export or reuse a stronger tailored version.

## Product Guardrails

- [ ] Keep the core workflow narrow: upload resume -> paste JD -> analyze -> improve -> export/reuse.
- [ ] Keep Rezumate focused on resume optimization, not a full resume builder.
- [ ] Do not turn the product into a job board, recruiter SaaS, social network, or generic chatbot.
- [ ] Keep the experience fast, focused, practical, calm, and mobile-friendly.
- [ ] Treat the existing FastAPI web app as the immediate MVP target.
- [ ] Defer React Native/Expo until the core workflow, scoring quality, and retention loop are proven.
- [ ] Keep compare, rank, and chat secondary to the score-and-improve flow.

## Current Stack To Preserve

- [ ] Keep FastAPI as the backend framework.
- [ ] Keep Jinja2 templates for the near-term frontend.
- [ ] Keep vanilla JavaScript for near-term interactivity.
- [ ] Keep shared CSS in `app/static/css/styles.css`.
- [x] Keep `pdfplumber` as the primary PDF extraction tool.
- [ ] Keep Groq/LangChain for AI model calls.
- [ ] Keep Pydantic schemas for structured AI outputs.
- [ ] Keep SQLAlchemy for persistence.
- [ ] Keep local SQLite fallback.
- [ ] Keep Turso-compatible production persistence.
- [ ] Keep Vercel-oriented deployment.

## Core Principles

- [ ] Ensure AI improves, explains, rewrites, and suggests without fabricating experience.
- [ ] Prevent AI from inventing jobs, metrics, tools, credentials, employers, degrees, or achievements.
- [ ] Move keyword matching, section detection, measurable impact checks, and formatting checks into deterministic logic where possible.
- [ ] Validate LLM responses through Pydantic schemas before rendering them.
- [ ] Keep model usage low-cost and deliberate.
- [ ] Cache or reuse repeated AI work where possible.
- [ ] Make every issue actionable: explain what is wrong and what the user should do next.
- [ ] Ensure exported resumes prioritize ATS parseability over visual decoration.

## Phase 1: Stabilize Current MVP

### File Support And Parsing

- [x] Decide MVP file support honestly: PDF-only now, or true PDF/DOCX/TXT support.
- [x] If staying PDF-only, update API validation and UI copy to advertise only PDF.
- [ ] If supporting DOCX, add `python-docx` extraction.
- [ ] If supporting TXT, add plain text extraction.
- [x] Reject unsupported file types before reading the full upload.
- [x] Add validation for empty extracted text.
- [x] Add validation for low-quality extraction.
- [x] Return clear user-facing errors for unsupported files.
- [x] Return clear user-facing errors for empty or unusable extraction.
- [x] Add extraction warnings for low text density.
- [ ] Add extraction warnings for strange text ordering.
- [x] Add extraction warnings for empty PDF pages.
- [x] Normalize extracted whitespace.
- [x] Preserve enough line breaks for section detection.
- [x] Keep raw uploaded files out of storage unless a user-facing reason exists.

### Deterministic ATS Service

- [x] Create `app/services/ats_service.py`.
- [x] Return structured deterministic signals from the ATS service.
- [x] Extract JD keywords deterministically.
- [x] Identify matched keywords.
- [x] Identify missing keywords.
- [x] Identify partial keyword matches.
- [x] Count resume bullets.
- [x] Count weak bullets.
- [x] Detect bullets without measurable impact.
- [x] Detect section presence.
- [x] Detect likely formatting warnings.
- [x] Estimate resume length.
- [x] Calculate keyword coverage.
- [x] Calculate role requirement coverage.
- [x] Calculate impact quality.
- [x] Calculate structure/readability quality.
- [x] Calculate formatting risk.
- [x] Create an explainable deterministic scoring formula.
- [x] Version the deterministic score formula.
- [x] Ensure same resume + JD returns identical deterministic signals every time.

### API Stabilization

- [x] Keep `POST /api/score`.
- [x] Keep `POST /api/compare`.
- [x] Keep `POST /api/rank`.
- [x] Keep `POST /api/chat`.
- [x] Improve `POST /api/score` request validation.
- [x] Require `job_description` text.
- [x] Return `analysis_id` from score analysis.
- [x] Return `filename` from score analysis.
- [x] Return `resume_text` from score analysis.
- [x] Return `deterministic_signals` from score analysis.
- [x] Return structured `result` from score analysis.
- [x] Return `warnings` from score analysis.
- [x] Merge deterministic signals with the existing structured AI result.
- [x] Add consistent API error responses for invalid files.
- [x] Add consistent API error responses for empty extraction.
- [x] Add consistent API error responses for model failures.
- [ ] Add consistent API error responses for timeout cases.
- [x] Preserve deterministic analysis output when the LLM fails.
- [ ] Save failed extraction metadata where useful for debugging.

### Persistence

- [x] Keep storing extracted resume text.
- [x] Keep storing job description text.
- [x] Keep storing structured result JSON.
- [x] Keep storing match score.
- [x] Keep storing timestamps.
- [x] Expand `analyses` with `filename`.
- [x] Expand `analyses` with `resume_hash`.
- [x] Expand `analyses` with `job_description_hash`.
- [x] Expand `analyses` with `extraction_status`.
- [x] Expand `analyses` with `extraction_warnings`.
- [x] Expand `analyses` with `deterministic_signals`.
- [x] Expand `analyses` with `model_name`.
- [x] Expand `analyses` with `latency_ms`.
- [x] Expand `analyses` with nullable `user_id` for pre-auth compatibility.
- [x] Ensure score page works locally without manual database setup.

### Phase 1 Tests

- [x] Add unit tests for PDF text normalization.
- [x] Add unit tests for JD keyword extraction.
- [x] Add unit tests for deterministic score calculation.
- [x] Add unit tests for weak bullet detection.
- [x] Add unit tests for measurable impact detection.
- [x] Add unit tests for Pydantic schema validation.
- [x] Add integration test for `POST /api/score` success path.
- [x] Add integration test for unsupported file path.
- [x] Add integration test for empty extraction path.
- [x] Add integration test for AI failure fallback behavior.
- [x] Add integration test for database save behavior.

### Phase 1 Acceptance Criteria

- [x] Same resume + JD returns the same deterministic signals every time.
- [x] Empty resumes return useful errors.
- [x] Unsupported resumes return useful errors.
- [x] Score page works end-to-end locally without manual database setup.

## Phase 2: Make Results Actionable

### Score Page UI

- [ ] Make the score page the flagship experience.
- [x] Provide a clear resume upload control.
- [x] Provide a clear job description input.
- [x] Add a strong loading state while parsing and analyzing.
- [ ] Add polished error states.
- [ ] Add empty states.
- [ ] Add partial-success states.
- [x] Render structured result data instead of long AI text blocks.
- [x] Render score summary.
- [x] Render fit level.
- [x] Render missing skills.
- [x] Render matched skills.
- [x] Render evidence for matched skills.
- [x] Render strengths.
- [x] Render prioritized improvement suggestions.
- [x] Render resume text preview.
- [x] Add contextual chat entry point after analysis.
- [ ] Keep the interface dense, calm, and mobile-friendly.

### Bullet Improvements

- [x] Add weak bullet detection to the displayed analysis.
- [ ] Add `POST /api/rewrite-bullet`.
- [ ] Add one-click rewrite UI for individual weak bullets.
- [ ] Require rewrites to preserve original facts.
- [ ] Require concise rewritten bullets.
- [ ] Require action verbs in rewritten bullets.
- [ ] Include metrics only when supplied.
- [ ] If metrics are not supplied, frame metric suggestions as placeholders.
- [ ] Do not tell users to keyword-stuff.
- [ ] Store prompt version with each analysis or rewrite.
- [ ] Store model name with each analysis or rewrite.
- [ ] Handle model failures gracefully in the UI.

### AI Prompting Rules

- [ ] Use AI for summarizing candidate fit.
- [ ] Use AI for targeted improvement suggestions.
- [ ] Use AI for rewriting bullets only on user request.
- [ ] Use AI for contextual chat answers.
- [ ] Do not use AI as the only source for basic keyword matching.
- [ ] Do not use AI as the only source for score calculation.
- [ ] Do not use AI for file parsing.
- [ ] Do not use AI for usage limits.
- [ ] Do not allow fabricated metrics or unverifiable claims.

### Caching

- [x] Generate resume text hash.
- [x] Generate job description hash.
- [x] Track prompt version.
- [x] Track model name.
- [ ] Reuse cached results by resume text hash + JD hash + prompt version + model name.
- [ ] Avoid unnecessary repeated model calls.

### Phase 2 Acceptance Criteria

- [ ] A user can identify the top 3 resume changes in under 30 seconds after analysis.
- [ ] Bullet rewrites preserve the user's original facts.
- [x] The UI handles model failures gracefully.

## Phase 3: History And Retention

- [ ] Add `GET /api/analyses/{id}`.
- [ ] Add `GET /api/history`.
- [ ] Add analysis history UI.
- [ ] Let users reopen past analyses.
- [ ] Add optional names or titles for analyses.
- [ ] Add basic analysis deletion.
- [ ] Ensure refreshing the page does not lose the latest analysis.
- [ ] Let users compare recent scores over time.

### Future History Tables

- [ ] Add `users` table when authentication is needed.
- [ ] Add `chat_messages` table when persisted contextual chat is needed.
- [ ] Add `usage_events` table when rate limits or monetization are needed.

### Phase 3 Acceptance Criteria

- [ ] Refreshing the page does not lose the latest analysis.
- [ ] A user can compare recent scores over time.

## Phase 4: Tailored Resume Variants And Export

### Resume Variants

- [ ] Add `resume_variants` table.
- [ ] Create backend support for saved tailored versions.
- [ ] Let users create a tailored variant from an existing analysis.
- [ ] Let users accept suggested bullet rewrites.
- [ ] Let users reject suggested bullet rewrites.
- [ ] Let users reuse a stronger tailored resume.

### Export

- [ ] Add `POST /api/export`.
- [ ] Add `exports` table when generated file metadata is needed.
- [ ] Generate ATS-safe PDF export from structured content.
- [ ] Add export preview.
- [ ] Validate exported PDF parseability.
- [ ] Ensure exported PDFs are text-selectable.
- [ ] Avoid tables that harm ATS parsing.
- [ ] Avoid images that harm ATS parsing.
- [ ] Avoid decorative layouts that harm ATS parsing.
- [ ] Add object storage for exported PDFs only when needed.
- [ ] Add object storage for raw resumes only when there is a clear user-facing reason.

### Phase 4 Acceptance Criteria

- [ ] User can create a tailored variant from an existing analysis.
- [ ] Exported PDF is text-selectable and parseable.
- [ ] Export does not introduce tables, images, or layout that harms ATS parsing.

## Phase 5: Accounts And Monetization

### Authentication

- [ ] Add authentication.
- [ ] Add `users` table with authentication identity.
- [ ] Add plan tier to users.
- [ ] Add user accounts before long-term raw resume file storage.
- [ ] Ensure anonymous/local flow still works where intended.
- [ ] Ensure users do not lose saved analyses after login.

### Usage Limits

- [ ] Add `usage_events` table.
- [ ] Add server-side usage limit middleware.
- [ ] Limit free analyses per day.
- [ ] Limit free chat messages.
- [ ] Limit free bullet rewrites.
- [ ] Enforce higher Pro limits.
- [ ] Enforce plan-aware API limits server-side.

### Payments

- [ ] Add payment provider.
- [ ] Choose Stripe or Lemon Squeezy.
- [ ] Add checkout flow.
- [ ] Gate saved history depth for Pro.
- [ ] Gate resume variants for Pro if needed.
- [ ] Gate exports to ATS-safe PDF for Pro if needed.
- [ ] Gate better models or deeper analysis for Pro if needed.

### Phase 5 Acceptance Criteria

- [ ] Anonymous/local flow still works where intended.
- [ ] Paid limits are enforced server-side.
- [ ] Users never lose saved analyses after login.

## Secondary Flows

### Compare

- [ ] Keep compare as a secondary workflow.
- [ ] Compare two resumes against one JD.
- [ ] Explain which resume is the stronger fit.
- [ ] Show both scores.
- [ ] Show a clear winner or tie.
- [ ] Explain key differentiators.
- [ ] Avoid overwhelming charts.

### Rank

- [ ] Keep rank as a secondary workflow.
- [ ] Rank multiple resumes against one JD.
- [ ] Show each resume score.
- [ ] Show ranking order.
- [ ] Explain differentiators.
- [ ] Avoid overwhelming charts.

### Chat

- [ ] Keep chat contextual and bounded.
- [ ] Use the current resume and JD as chat context.
- [ ] Encourage specific improvement questions.
- [ ] Keep answers actionable.
- [ ] Keep answers concise.
- [ ] Prevent chat from becoming a generic AI assistant.

## Parser Roadmap

### MVP Parser

- [x] Support PDF reliably with `pdfplumber`.
- [x] Return extraction warnings for low text density.
- [ ] Return extraction warnings for strange ordering.
- [x] Return extraction warnings for empty pages.
- [x] Normalize whitespace.
- [x] Preserve line breaks for section detection.

### Next Parser Support

- [ ] Add DOCX support with `python-docx`.
- [ ] Add TXT support.
- [ ] Add parser fixtures for common resume layouts.

### Deferred Parser Work

- [ ] Defer OCR for scanned resumes.
- [ ] Defer complex visual template reconstruction.
- [ ] Defer full resume editor based on parsed layout.

## Manual QA Fixtures

- [ ] Add sample single-column resume.
- [ ] Add sample two-column resume.
- [ ] Add sample dense technical resume.
- [ ] Add sample student resume.
- [ ] Add sample project-only resume.
- [ ] Add sample low-quality or scanned PDF.
- [ ] Use fixtures to verify parser degradation behavior.

## Risks And Mitigations

- [ ] Mitigate inconsistent LLM scores by making deterministic scoring the source of truth.
- [ ] Use AI primarily for explanation, guidance, and rewriting.
- [ ] Mitigate PDF parsing failures by collecting fixtures.
- [ ] Mitigate PDF parsing failures by returning extraction warnings.
- [ ] Mitigate PDF parsing failures by adding DOCX/TXT support.
- [ ] Mitigate generic advice by referencing resume/JD evidence in suggestions.
- [ ] Mitigate cost growth by caching content-hash results.
- [ ] Mitigate cost growth by reserving AI rewrites for explicit user actions.
- [ ] Mitigate product sprawl by keeping score-and-improve as the flagship workflow until retention is proven.

## Deployment And Documentation

- [ ] Document required environment variables.
- [ ] Document local SQLite behavior.
- [ ] Document Turso production setup.
- [ ] Document Groq API key setup.
- [ ] Confirm Vercel deployment works.
- [ ] Confirm deployed app can initialize persistence correctly.
- [ ] Confirm the app can be shared as a working MVP.

## Strong MVP Definition

- [ ] Uploading a PDF and pasting a JD produces a useful result in under 60 seconds.
- [ ] The score is explainable.
- [ ] The score is repeatable.
- [ ] Missing skills are clearly identified.
- [ ] Weak bullets are clearly identified.
- [ ] AI suggestions are specific.
- [ ] AI suggestions do not fabricate experience.
- [ ] UI works well on mobile.
- [ ] UI works well on desktop.
- [ ] Past analysis data persists in local SQLite.
- [ ] Past analysis data persists in Turso.
- [ ] App can be deployed to Vercel with documented environment variables.

## Later Distribution Layer

- [ ] Revisit React Native/Expo only after the web MVP proves the workflow.
- [ ] If building mobile later, consume the same FastAPI API.
- [ ] Avoid rebuilding the backend until the workflow is stable.
