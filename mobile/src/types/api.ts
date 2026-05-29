export type UploadResponse = {
  success: boolean;
  filename: string;
  resume_id: string;
  extracted_text: string;
  warnings: string[];
  character_count: number;
};

export type AnalyzeResponse = {
  success: boolean;
  variant_id: string;
  score: number;
  matched_keywords: string[];
  missing_keywords: string[];
  weak_bullets: string[];
  bullets_without_measurable_impact: string[];
  formatting_warnings: string[];
  component_scores: Record<string, number>;
};

export type RewriteBulletResponse = {
  success: boolean;
  original_bullet: string;
  rewritten_bullets: string[];
  ai_model_name: string;
};

export type VariantSummary = {
  id: string;
  resume_id: string;
  variant_name: string;
  ats_score: number | null;
  created_at: string;
  updated_at: string;
};

export type HistoryResponse = {
  success: boolean;
  variants: VariantSummary[];
};

export type VariantDetail = {
  id: string;
  resume_id: string;
  variant_name: string;
  tailored_content: { raw_text?: string };
  ats_score: number | null;
  analysis_feedback: AnalyzeResponse | Record<string, unknown>;
  created_at: string;
};
