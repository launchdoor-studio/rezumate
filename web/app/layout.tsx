import type { Metadata } from "next";
import type { ReactNode } from "react";
import "./globals.css";

export const metadata: Metadata = {
  title: "Rezumate - AI resume optimization for iPhone",
  description: "Upload a resume, paste a job description, and get focused ATS feedback in minutes.",
  metadataBase: new URL("https://rezumate.app")
};

export default function RootLayout({ children }: Readonly<{ children: ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
