import { StyleSheet, Text, View } from "react-native";

import type { AppColors } from "../theme/colors";
import { useTheme } from "../theme/ThemeProvider";

type Props = {
  label: string;
  tone?: "green" | "amber" | "red" | "blue";
};

export function Chip({ label, tone = "blue" }: Props) {
  const { colors } = useTheme();
  const styles = createStyles(colors);
  return (
    <View style={[styles.chip, styles[tone]]}>
      <Text allowFontScaling={false} style={styles.label}>{label}</Text>
    </View>
  );
}

const createStyles = (colors: AppColors) => StyleSheet.create({
  chip: {
    borderRadius: 999,
    borderWidth: 1,
    paddingHorizontal: 10,
    paddingVertical: 5
  },
  blue: { borderColor: colors.blue, backgroundColor: colors.tintSoft },
  green: { borderColor: colors.green, backgroundColor: colors.panel2 },
  amber: { borderColor: colors.amber, backgroundColor: colors.panel2 },
  red: { borderColor: colors.red, backgroundColor: colors.panel2 },
  label: {
    color: colors.text,
    fontSize: 11,
    fontWeight: "800"
  }
});
