import Link from "next/link";

const features = [
  ["ATS score", "See a clear role-specific match score built from deterministic resume signals."],
  ["Missing keywords", "Find the tools, skills, and phrases the job description expects but your resume lacks."],
  ["Bullet rewrites", "Improve weak bullets without fabricating experience or inventing metrics."],
  ["PDF export", "Share an ATS-safe resume version when your tailored draft is ready."],
  ["Private by design", "Uploaded PDFs and DOCX files are parsed for analysis; history stores extracted text and results, not raw uploaded files."],
  ["Built for iPhone", "A focused native workflow for job seekers who want quick, useful feedback."]
];

export default function Home() {
  return (
    <>
      <header className="shell nav">
        <Link href="/" className="brand">
          <img src="/rezumate-logo.svg" alt="" className="brand-logo" />
          Rezumate
        </Link>
        <nav className="navlinks">
          <a href="#features">Features</a>
          <Link href="/privacy">Privacy</Link>
          <Link href="/support">Support</Link>
        </nav>
      </header>

      <main>
        <section className="shell hero">
          <div>
            <div className="eyebrow">Native iOS resume optimizer</div>
            <h1>Rezumate</h1>
            <p className="lead">
              Upload your resume, paste a job description, and get practical ATS feedback, missing keywords,
              weak bullets, and export-ready improvements in minutes.
            </p>
            <div className="actions">
              <Link className="button" href="/waitlist">Join Waitlist</Link>
              <Link className="button secondary" href="/privacy">Read Privacy Policy</Link>
            </div>
          </div>

          <div className="phone" aria-label="Rezumate app preview">
            <div className="screen">
              <div className="app-header">
                <img src="/rezumate-logo.svg" alt="" className="app-logo" />
                <div>
                  <strong>Rezumate</strong>
                  <span>Resume analysis</span>
                </div>
              </div>
              <div className="score">
                <div>
                  <strong>84</strong>
                  <span>ATS match score</span>
                </div>
              </div>
              <div className="stack">
                <div className="mini-card">
                  Missing keywords
                  <span>Kubernetes, Terraform, CI/CD</span>
                </div>
                <div className="mini-card">
                  Weak bullet
                  <span>Replace generic wording with impact-focused evidence.</span>
                </div>
                <div className="mini-card">
                  Export
                  <span>Prepare an ATS-safe PDF for this role.</span>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section id="features" className="band">
          <div className="shell">
            <h2>Focused on the resume workflow that matters.</h2>
            <div className="grid">
              {features.map(([title, copy]) => (
                <article className="card" key={title}>
                  <h3>{title}</h3>
                  <p>{copy}</p>
                </article>
              ))}
            </div>
          </div>
        </section>
      </main>

      <footer className="shell footer">
        <span>© {new Date().getFullYear()} Rezumate</span>
        <span>
          <Link href="/terms">Terms</Link> · <Link href="/privacy">Privacy</Link> · <Link href="/support">Support</Link>
        </span>
      </footer>
    </>
  );
}
