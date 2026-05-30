import Link from "next/link";

export default function WaitlistPage() {
  return (
    <main className="shell legal">
      <Link href="/">← Rezumate</Link>
      <h1>Join the Rezumate Waitlist</h1>
      <p>
        The native iOS app is being prepared for release. Until the App Store link is live, send a note to
        support@rezumate.app with the subject "Waitlist".
      </p>
    </main>
  );
}
