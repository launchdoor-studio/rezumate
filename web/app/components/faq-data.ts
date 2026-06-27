export type FaqItem = {
  question: string;
  answer: string;
};

export type FaqSection = {
  title: string;
  items: FaqItem[];
};

export const faqSections: FaqSection[] = [
  {
    title: "Product",
    items: [
      {
        question: "What is Rezumate?",
        answer:
          "Rezumate is a mobile-first, 100% on-device AI resume optimization app. Upload a resume, paste a job description, and get instant ATS scoring, missing keywords, weak-bullet feedback, and optimized bullet rewrites — calculated entirely locally on your iPhone."
      },
      {
        question: "What problem does Rezumate solve?",
        answer:
          "Most applicants send one generic resume everywhere, do not know what ATS systems expect, and get rejected without useful feedback. Rezumate focuses on local optimization, tailoring, clarity, and speed — without template-heavy resume building, monthly cloud subscriptions, or privacy risks."
      },
      {
        question: "Who is Rezumate for?",
        answer:
          "Tech professionals, students, active job seekers, and developers who want to tailor resumes rapidly for different roles on the go, with absolute privacy guarantees. Because it runs locally, it is fast, responsive, and completely private."
      },
      {
        question: "How does the core workflow work?",
        answer:
          "Upload resume (PDF/DOCX) → paste job description → get instant ATS analysis → optimize weak bullets using local AI → export an ATS-safe PDF. The entire loop runs locally on your device with no internet connection required."
      },
      {
        question: "What makes Rezumate different from other AI resume tools?",
        answer:
          "Privacy and architecture. Standard resume tools upload your highly sensitive personal information (phone number, email, work history, addresses) to third-party cloud databases. Rezumate does not. It is built natively for iOS and processes everything in-memory and in local sandboxed storage."
      }
    ]
  },
  {
    title: "Analysis & Rewrites",
    items: [
      {
        question: "What file formats can I upload?",
        answer:
          "PDF and DOCX. Rezumate uses native iOS PDFKit and local ZIP/XML document parsers to extract skills, experience, and keywords directly on your device."
      },
      {
        question: "What does the ATS analysis include?",
        answer:
          "A role-specific ATS match score, keyword match against the job description, missing skills and tools, weak bullet detection, formatting warnings, and measurable-impact checks — calculated instantly via our native scoring engine."
      },
      {
        question: "How does the on-device AI work?",
        answer:
          "Rezumate runs a quantized Llama 3.2 1B Instruct model directly on Apple's Neural Engine. This model is fine-tuned to rewrite weak resume bullets into action-oriented, metrics-driven sentences containing target keywords."
      },
      {
        question: "Do I need to download a massive model?",
        answer:
          "The initial app bundle is under 50MB. When you first choose to optimize a bullet, the app downloads a highly compact, optimized ~650MB Llama 3.2 model in the background. While downloading, the app falls back to a high-quality rules-based local engine so you are never blocked."
      },
      {
        question: "Will Rezumate invent experience or metrics for me?",
        answer:
          "No. Rezumate follows an AI-assisted, not AI-replacing philosophy. The local model is prompted to improve phrasing and structure without fabricating employers, credentials, skills, or metrics. You remain in control of keeping your resume truthful."
      },
      {
        question: "Can I export my resume?",
        answer:
          "Yes. Rezumate exports ATS-safe PDFs with clean typography. Exports are compiled directly on-device using iOS layout renderers to ensure they are 100% selectable and easily parsed by applicant tracking systems."
      }
    ]
  },
  {
    title: "Plans & Pricing",
    items: [
      {
        question: "What is included on the Free plan?",
        answer:
          "The free plan is fully featured and runs locally on your device: unlimited text parsing, local ATS scoring, keyword matching, and PDF exports. There are no monthly token limits or credit counters."
      },
      {
        question: "What does Rezumate Pro unlock?",
        answer:
          "Rezumate Pro is a simple one-time purchase or small subscription that unlocks unlimited saved variants (history), custom export PDF layouts, and access to advanced local model parameters."
      },
      {
        question: "How does the pricing compare to cloud-based builders?",
        answer:
          "Since Rezumate runs on your device, we don't have to pay massive server bills to run LLM models for every user. We pass those savings directly to you with fair, sustainable pricing."
      }
    ]
  },
  {
    title: "Privacy & Security",
    items: [
      {
        question: "How is my resume data handled?",
        answer:
          "100% Private by design. Your resume text, job descriptions, scores, and rewritten variants are stored strictly on your device using encrypted sandboxed storage. We have no backend databases, no analytics trackers harvesting your CV, and your data never leaves your iPhone."
      },
      {
        question: "Do I need an account to use the app?",
        answer:
          "No. You can start using Rezumate immediately as a guest. If you want to sync variants across your personal Apple devices, you can optionally enable local iCloud synchronization, which uses your private Apple iCloud account."
      },
      {
        question: "Does Rezumate sell my data?",
        answer:
          "Never. We cannot sell your data because we do not collect it. We have zero access to your uploaded files, scores, or personal information."
      }
    ]
  }
];

export const featuredFaqQuestions = new Set([
  "What is Rezumate?",
  "How does the core workflow work?",
  "What makes Rezumate different from other AI resume tools?",
  "How does the on-device AI work?",
  "How is my resume data handled?",
  "Do I need an account to use the app?"
]);

export const featuredFaqItems: FaqItem[] = faqSections
  .flatMap((section) => section.items)
  .filter((item) => featuredFaqQuestions.has(item.question));
