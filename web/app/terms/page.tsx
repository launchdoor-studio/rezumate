import Link from "next/link";

export default function TermsPage() {
  return (
    <main className="shell legal">
      <Link href="/">← Rezumate</Link>
      <h1>Terms of Service</h1>
      <p>Last updated: May 30, 2026</p>
      <p>
        Rezumate provides resume parsing, job-description matching, ATS-style scoring, PDF export, and AI-assisted
        editing suggestions. The service is informational and does not guarantee interviews, job offers, ATS
        outcomes, recruiter decisions, or hiring results.
      </p>
      <p>
        Users are responsible for ensuring resumes remain accurate and truthful. Rezumate suggestions should not be
        used to invent employers, credentials, skills, metrics, or experience.
      </p>
      <p>
        Users should only upload resumes and job descriptions they have the right to process. The service may
        enforce usage limits, rate limits, or access restrictions to protect reliability and operating cost.
      </p>
      <p>
        For support, account help, or data deletion requests, contact aftaab@aftaab.dev.
      </p>
    </main>
  );
}
