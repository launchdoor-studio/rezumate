import { StyleSheet, Text, View } from "react-native";

import type { AppColors } from "../theme/colors";
import { useTheme } from "../theme/ThemeProvider";

type Props = {
  score: number;
};

export function ScoreRing({ score }: Props) {
  const { colors } = useTheme();
  const styles = createStyles(colors);
  const clamped = Math.max(0, Math.min(100, score));

  return (
    <View style={styles.wrap}>
      <View style={[styles.ring, { borderColor: scoreColor(clamped, colors) }]}>
        <Text allowFontScaling={false} style={styles.score}>{clamped}</Text>
        <Text allowFontScaling={false} style={styles.caption}>ATS</Text>
      </View>
    </View>
  );
}

function scoreColor(score: number, colors: AppColors) {
  if (score >= 80) return colors.green;
  if (score >= 60) return colors.amber;
  return colors.red;
}

const createStyles = (colors: AppColors) => StyleSheet.create({
  wrap: {
    alignItems: "center"
  },
  ring: {
    width: 104,
    height: 104,
    borderRadius: 52,
    borderWidth: 7,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: colors.panel3
  },
  score: {
    color: colors.text,
    fontSize: 30,
    fontWeight: "900"
  },
  caption: {
    color: colors.muted,
    fontSize: 12,
    fontWeight: "800"
  }
});
