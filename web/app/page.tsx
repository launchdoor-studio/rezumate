import Link from "next/link";

import { FaqList } from "./components/FaqList";
import { featuredFaqItems } from "./components/faq-data";
import { SiteChrome } from "./components/SiteChrome";

const features = [
  ["ATS match score", "Calculate a role-specific match score using our fast, deterministic local scanner."],
  ["Missing keywords", "Extract the exact languages, frameworks, and terms the job description expects but your resume lacks."],
  ["Llama 3.2 on-device", "Rewrite weak bullets natively on your iPhone using a local quantized model optimized for the Neural Engine."],
  ["100% private", "Your name, phone number, email, and career history never leave your device. No cloud databases, no trackers."],
  ["Offline-first", "Tailor your resume, re-score, and optimize bullets completely offline with no latency or server lag."],
  ["Clean PDF export", "Compile and share structured, ATS-safe PDF documents directly from your device's local sandbox."]
];

export default function Home() {
  return (
    <SiteChrome>
      <main>
        <section className="shell hero">
          <div>
            <div className="eyebrow">100% On-Device AI Resume Optimization</div>
            <h1>Tailor your resume. 100% privately.</h1>
            <p className="lead">
              Your resume contains your phone number, email, address, and entire career history. 
              Rezumate runs Llama 3.2 1B locally on your iPhone's Neural Engine to optimize bullets, 
              calculate ATS match scores, and export files—without ever uploading your data to a server.
            </p>
            <div className="actions">
              <Link className="button" href="/waitlist">Join Waitlist</Link>
              <Link className="button secondary" href="/privacy">Privacy Policy</Link>
            </div>
          </div>

          <div className="phone-wrap">
            <div className="phone" aria-label="Rezumate app preview">
              <div className="phone-island" aria-hidden="true" />
              <div className="screen">
                <div className="app-header">
                  <div className="app-header-left">
                    <img src="/rezumate-logo.svg" alt="" className="app-logo" />
                    <div>
                      <strong>Rezumate</strong>
                      <span>On-Device AI</span>
                    </div>
                  </div>
                  <span className="app-badge">Pro</span>
                </div>

                <div className="score-card">
                  <div className="score-label">ATS match score</div>
                  <div className="score-row">
                    <strong>84</strong>
                    <em>/100</em>
                  </div>
                  <div className="progress-track" aria-hidden="true">
                    <div className="progress-fill" style={{ width: "84%" }} />
                  </div>
                </div>

                <div className="section-label">Missing keywords</div>
                <div className="chips">
                  <span className="chip">Kubernetes</span>
                  <span className="chip">Terraform</span>
                  <span className="chip">CI/CD</span>
                </div>

                <div className="stack">
                  <div className="mini-card">
                    Weak bullet
                    <span>Local Llama 3.2 rewrites sentences instantly offline.</span>
                  </div>
                </div>

                <div className="phone-home-indicator" aria-hidden="true" />
              </div>
            </div>
          </div>
        </section>

        <section id="features" className="band">
          <div className="shell">
            <h2>Fully native and designed for maximum privacy</h2>
            <div className="grid">
              {features.map(([title, copy], index) => (
                <article className="card" key={title}>
                  <span className="card-index">{String(index + 1).padStart(2, "0")}</span>
                  <h3>{title}</h3>
                  <p>{copy}</p>
                </article>
              ))}
            </div>
          </div>
        </section>

        <section id="faq" className="band faq-band">
          <div className="shell">
            <p className="eyebrow">FAQ</p>
            <h2>Questions before you join</h2>
            <p className="lead faq-lead">
              Rezumate is built for one workflow: upload, tailor, improve, and export — without
              compromising your data privacy, showing ads, or harvesting your CV.
            </p>
            <FaqList items={featuredFaqItems} idPrefix="home-faq" />
            <div className="faq-more">
              <Link className="button secondary" href="/faq">View all questions</Link>
            </div>
          </div>
        </section>
      </main>
    </SiteChrome>
  );
}
