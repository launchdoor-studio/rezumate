import { create } from "zustand";

import type { AnalyzeResponse, UploadResponse } from "../types/api";

type AnalysisState = {
  upload: UploadResponse | null;
  jobDescription: string;
  result: AnalyzeResponse | null;
  acceptedRewrites: Record<string, string>;
  setUpload: (upload: UploadResponse | null) => void;
  setJobDescription: (jobDescription: string) => void;
  setResult: (result: AnalyzeResponse | null) => void;
  acceptRewrite: (original: string, rewritten: string) => void;
  reset: () => void;
};

export const useAnalysisStore = create<AnalysisState>((set) => ({
  upload: null,
  jobDescription: "",
  result: null,
  acceptedRewrites: {},
  setUpload: (upload) => set({ upload }),
  setJobDescription: (jobDescription) => set({ jobDescription }),
  setResult: (result) => set({ result }),
  acceptRewrite: (original, rewritten) =>
    set((state) => ({ acceptedRewrites: { ...state.acceptedRewrites, [original]: rewritten } })),
  reset: () => set({ upload: null, jobDescription: "", result: null, acceptedRewrites: {} })
}));
