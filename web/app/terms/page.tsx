import Link from "next/link";

export default function TermsPage() {
  return (
    <main className="shell legal">
      <Link href="/">← Rezumate</Link>
      <h1>Terms of Service</h1>
      <p>Last updated: May 29, 2026</p>
      <p>
        Rezumate provides resume analysis and AI-assisted editing suggestions. The service is informational and
        does not guarantee interviews, job offers, ATS outcomes, or hiring decisions.
      </p>
      <p>
        Users are responsible for ensuring resumes remain accurate and truthful. Rezumate suggestions should not be
        used to invent employers, credentials, skills, metrics, or experience.
      </p>
      <p>
        The service may enforce usage limits, rate limits, or access restrictions to protect reliability and cost.
        For support, contact support@rezumate.app.
      </p>
    </main>
  );
}
