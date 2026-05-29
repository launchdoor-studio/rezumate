import type { NavigatorScreenParams } from "@react-navigation/native";

import type { AnalyzeResponse } from "./api";

export type TabParamList = {
  Analyze: undefined;
  Resumes: undefined;
  Profile: undefined;
};

export type RootStackParamList = {
  Auth: undefined;
  Main: NavigatorScreenParams<TabParamList> | undefined;
  Results: { result?: AnalyzeResponse } | undefined;
  Rewrite: { bullet: string; missingKeywords?: string[] };
};
