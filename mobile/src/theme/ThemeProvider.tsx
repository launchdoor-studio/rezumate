import AsyncStorage from "@react-native-async-storage/async-storage";
import { createContext, PropsWithChildren, useContext, useEffect, useMemo, useState } from "react";

import type { AppColors, ThemeName } from "./colors";

const palettes: Record<ThemeName, AppColors> = {
  light: {
    ink: "#F7F2FF",
    surface: "#FFFFFF",
    panel: "#FEFCFF",
    panel2: "#F3ECFF",
    panel3: "#E9DEFF",
    line: "#E3DCF3",
    lineSoft: "#EEE8FA",
    text: "#20172F",
    muted: "#7B7288",
    subtle: "#A7A0B2",
    blue: "#7C3AED",
    cyan: "#8B5CF6",
    green: "#20A978",
    amber: "#D28716",
    red: "#D45757",
    violet: "#6D28D9",
    white: "#FFFFFF",
    tab: "#FFFFFF",
    input: "#FAF8FF",
    tintSoft: "#F0E9FF",
    violetSoft: "#EDE5FF"
  },
  dark: {
    ink: "#100B18",
    surface: "#1A1324",
    panel: "#21182E",
    panel2: "#2A203A",
    panel3: "#372A4D",
    line: "#46365F",
    lineSoft: "#322640",
    text: "#F3F7F2",
    muted: "#B8ADCA",
    subtle: "#82758F",
    blue: "#8B5CF6",
    cyan: "#A78BFA",
    green: "#69C18D",
    amber: "#E3B654",
    red: "#EF7878",
    violet: "#A894EA",
    white: "#FFFFFF",
    tab: "#1A1324",
    input: "#20182B",
    tintSoft: "#2F2443",
    violetSoft: "#352650"
  }
};

type ThemeContextValue = {
  colors: AppColors;
  themeName: ThemeName;
  setThemeName: (theme: ThemeName) => void;
};

const storageKey = "rezumate.theme.v2";
const ThemeContext = createContext<ThemeContextValue | null>(null);

export function ThemeProvider({ children }: PropsWithChildren) {
  const [themeName, setThemeNameState] = useState<ThemeName>("light");

  useEffect(() => {
    AsyncStorage.getItem(storageKey).then((stored) => {
      if (stored === "light" || stored === "dark") {
        setThemeNameState(stored);
      }
    });
  }, []);

  const value = useMemo<ThemeContextValue>(() => ({
    colors: palettes[themeName],
    themeName,
    setThemeName: (nextTheme) => {
      setThemeNameState(nextTheme);
      AsyncStorage.setItem(storageKey, nextTheme).catch(() => undefined);
    }
  }), [themeName]);

  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}

export function useTheme() {
  const value = useContext(ThemeContext);
  if (!value) {
    throw new Error("useTheme must be used within ThemeProvider");
  }
  return value;
}
