import Link from "next/link";

export default function PrivacyPage() {
  return (
    <main className="shell legal">
      <Link href="/">← Rezumate</Link>
      <h1>Privacy Policy</h1>
      <p>Last updated: May 30, 2026</p>
      <p>
        Rezumate helps users analyze resumes against job descriptions and generate improvement suggestions. To
        provide the service, the app processes the resume file you choose to upload, extracted resume text, job
        descriptions you paste, analysis results, rewrite requests, export requests, account identifiers, and basic
        usage counters used for rate limits.
      </p>
      <p>
        The current app supports PDF and DOCX resume uploads. Uploaded files are read by the backend to extract
        text for analysis. The app stores extracted resume text, job descriptions, generated analysis feedback,
        tailored resume text, scores, and history records so users can return to prior analyses. The current backend
        does not save a permanent raw uploaded file URL for normal uploads.
      </p>
      <p>
        Rezumate uses Sign in with Apple for account access. Apple may provide an account identifier and, on first
        authorization, an email address. Rezumate uses this information to create or find your account and issue an
        app session token. Local developer sessions may be used only in development builds.
      </p>
      <p>
        AI-assisted rewrites and analysis may be processed by configured backend AI services. Resume suggestions
        should be reviewed by the user and kept truthful. Exported PDFs are generated from saved tailored text when
        requested.
      </p>
      <p>
        To request support, account help, or deletion of stored app data, email aftaab@aftaab.dev.
      </p>
    </main>
  );
}
