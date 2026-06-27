import type { MetadataRoute } from "next";

const routes = ["", "/faq", "/privacy", "/terms", "/support", "/waitlist"];

export default function sitemap(): MetadataRoute.Sitemap {
  return routes.map((route) => ({
    url: `https://rezumate.app${route}`,
    lastModified: new Date("2026-05-30"),
    changeFrequency: route === "" ? "weekly" : "monthly",
    priority: route === "" ? 1 : 0.6
  }));
}
