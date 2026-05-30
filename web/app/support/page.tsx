import Link from "next/link";

export default function SupportPage() {
  return (
    <main className="shell legal">
      <Link href="/">← Rezumate</Link>
      <h1>Support</h1>
      <p>
        Need help with Rezumate, account access, resume analysis, exports, or data deletion? Email
        support@rezumate.app.
      </p>
      <h2>Common Topics</h2>
      <ul>
        <li>Use a text-based PDF or DOCX when uploads fail.</li>
        <li>Paste a complete job description for better keyword matching.</li>
        <li>Review AI rewrites carefully and keep your resume factual.</li>
      </ul>
    </main>
  );
}
