import Link from "next/link";

export default function PrivacyPage() {
  return (
    <main className="shell legal">
      <Link href="/">← Rezumate</Link>
      <h1>Privacy Policy</h1>
      <p>Last updated: May 29, 2026</p>
      <p>
        Rezumate helps users analyze and improve resumes against job descriptions. The app processes resume
        files, extracted resume text, job descriptions, analysis results, account identifiers, and usage events
        needed to provide the service.
      </p>
      <p>
        Uploaded files are used for parsing and analysis. Rezumate is designed to avoid unnecessary long-term raw
        file storage. Extracted text, job descriptions, generated analysis, and exported variants may be stored so
        users can view history and continue their workflow.
      </p>
      <p>
        Rezumate uses Sign in with Apple for account access. Apple may provide an account identifier and, on first
        authorization, an email address. We use this information to create and secure your account.
      </p>
      <p>
        To request deletion or support, contact support@rezumate.app.
      </p>
    </main>
  );
}
