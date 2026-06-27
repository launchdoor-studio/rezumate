import Link from "next/link";

import { SiteChrome } from "../components/SiteChrome";

export default function PrivacyPage() {
  return (
    <SiteChrome>
      <main className="shell legal">
        <Link href="/" className="legal-back">← Back</Link>
        <h1>Privacy Policy</h1>
        <p className="legal-meta">Last updated: June 27, 2026</p>
        <div className="legal-card">
          <p>
            <strong>Rezumate is built with a 100% on-device privacy model.</strong> Your resume contains sensitive personal information (such as your phone number, email address, physical address, and full work history). We believe this data should never leave your control.
          </p>
          <p>
            Unlike traditional resume builders or AI services, <strong>Rezumate does not upload your files, parsed resume text, or pasted job descriptions to any external server.</strong> All text parsing, keyword extraction, ATS scoring, and AI bullet optimization are processed entirely locally on your iPhone using Apple's Neural Engine.
          </p>
          <p>
            <strong>Local Data Storage:</strong> All information—including your resume history, scores, missing keywords, and tailored draft variants—is saved locally on your device in secure, encrypted sandboxed storage. We have no external backend databases, run no user tracking analytics, and have zero visibility into your career details.
          </p>
          <p>
            <strong>On-Device AI Models:</strong> Bullet point optimization runs using a quantized Llama 3.2 1B Instruct model directly on your device. The model file is downloaded on-demand from a public Hugging Face CDN link directly into your app's local documents folder. This model runs locally and offline.
          </p>
          <p>
            <strong>Accounts & Sign-Ins:</strong> No account signup is required. You can use the app immediately as a guest. Optional local iCloud sync utilizes your own private Apple iCloud account; we never have access to this data.
          </p>
          <p>
            If you have questions about the app's local operations, or need support, email aftaab@aftaab.dev.
          </p>
        </div>
      </main>
    </SiteChrome>
  );
}
