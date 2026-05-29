import * as FileSystem from "expo-file-system/legacy";
import * as Sharing from "expo-sharing";

import { API_BASE_URL } from "./config";
import type {
  AnalyzeResponse,
  HistoryResponse,
  RewriteBulletResponse,
  UploadResponse,
  VariantDetail
} from "../types/api";

type UploadAsset = {
  uri: string;
  name: string;
  mimeType?: string;
};

async function parseResponse<T>(response: Response): Promise<T> {
  if (!response.ok) {
    let detail = "Request failed";
    try {
      const payload = await response.json();
      detail = payload.detail || detail;
    } catch {
      detail = `${detail} (${response.status})`;
    }
    throw new Error(detail);
  }

  return response.json() as Promise<T>;
}

function authHeaders(token: string) {
  return {
    Authorization: `Bearer ${token}`
  };
}

export async function uploadResume(file: UploadAsset, token: string): Promise<UploadResponse> {
  const form = new FormData();
  form.append("resume_file", {
    uri: file.uri,
    name: file.name,
    type: file.mimeType || guessMimeType(file.name)
  } as unknown as Blob);

  const response = await fetch(`${API_BASE_URL}/api/upload`, {
    method: "POST",
    headers: authHeaders(token),
    body: form
  });

  return parseResponse<UploadResponse>(response);
}

export async function analyzeResume(input: {
  resumeId: string;
  resumeText: string;
  jobDescription: string;
  token: string;
}): Promise<AnalyzeResponse> {
  const response = await fetch(`${API_BASE_URL}/api/analyze`, {
    method: "POST",
    headers: {
      ...authHeaders(input.token),
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      resume_id: input.resumeId,
      resume_text: input.resumeText,
      job_description: input.jobDescription
    })
  });

  return parseResponse<AnalyzeResponse>(response);
}

export async function rewriteBullet(input: {
  bullet: string;
  focusKeywords?: string[];
  token: string;
}): Promise<RewriteBulletResponse> {
  const response = await fetch(`${API_BASE_URL}/api/rewrite-bullet`, {
    method: "POST",
    headers: {
      ...authHeaders(input.token),
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      original_bullet: input.bullet,
      focus_keywords: input.focusKeywords || []
    })
  });

  return parseResponse<RewriteBulletResponse>(response);
}

export async function getHistory(token: string): Promise<HistoryResponse> {
  const response = await fetch(`${API_BASE_URL}/api/history`, {
    headers: authHeaders(token)
  });

  return parseResponse<HistoryResponse>(response);
}

export async function getVariant(variantId: string, token: string): Promise<VariantDetail> {
  const response = await fetch(`${API_BASE_URL}/api/variants/${variantId}`, {
    headers: authHeaders(token)
  });
  const payload = await parseResponse<{ success: boolean; variant: VariantDetail }>(response);

  return payload.variant;
}

export async function exportVariant(variantId: string, token: string) {
  const response = await fetch(`${API_BASE_URL}/api/export`, {
    method: "POST",
    headers: {
      ...authHeaders(token),
      "Content-Type": "application/json"
    },
    body: JSON.stringify({ variant_id: variantId })
  });

  if (!response.ok) {
    await parseResponse(response);
  }

  const blob = await response.blob();
  const reader = new FileReader();
  const base64 = await new Promise<string>((resolve, reject) => {
    reader.onerror = () => reject(new Error("Could not read exported PDF"));
    reader.onload = () => {
      const result = String(reader.result || "");
      resolve(result.split(",")[1] || "");
    };
    reader.readAsDataURL(blob);
  });

  const fileUri = `${FileSystem.cacheDirectory}rezumate-export-${variantId}.pdf`;
  await FileSystem.writeAsStringAsync(fileUri, base64, { encoding: FileSystem.EncodingType.Base64 });

  if (await Sharing.isAvailableAsync()) {
    await Sharing.shareAsync(fileUri, { mimeType: "application/pdf", dialogTitle: "Share resume PDF" });
  }

  return fileUri;
}

function guessMimeType(name: string) {
  if (name.toLowerCase().endsWith(".docx")) {
    return "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
  }
  return "application/pdf";
}
