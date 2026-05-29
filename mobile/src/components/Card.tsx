import { PropsWithChildren } from "react";
import { StyleProp, StyleSheet, View, ViewStyle } from "react-native";

import type { AppColors } from "../theme/colors";
import { useTheme } from "../theme/ThemeProvider";

type Props = PropsWithChildren<{
  elevated?: boolean;
  style?: StyleProp<ViewStyle>;
}>;

export function Card({ children, elevated, style }: Props) {
  const { colors } = useTheme();
  const styles = createStyles(colors);
  return <View style={[styles.card, elevated && styles.elevated, style]}>{children}</View>;
}

const createStyles = (colors: AppColors) => StyleSheet.create({
  card: {
    backgroundColor: colors.panel,
    borderColor: colors.lineSoft,
    borderWidth: 1,
    borderRadius: 18,
    padding: 14,
    gap: 12
  },
  elevated: {
    backgroundColor: colors.panel2,
    borderColor: colors.line
  }
});
