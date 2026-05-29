import { Ionicons } from "@expo/vector-icons";
import { ActivityIndicator, Pressable, StyleSheet, Text, View } from "react-native";

import type { AppColors } from "../theme/colors";
import { useTheme } from "../theme/ThemeProvider";

type Props = {
  label: string;
  onPress: () => void;
  disabled?: boolean;
  loading?: boolean;
  variant?: "primary" | "secondary" | "danger" | "ghost";
  icon?: keyof typeof Ionicons.glyphMap;
  size?: "sm" | "md";
  fullWidth?: boolean;
};

export function Button({ label, onPress, disabled, loading, variant = "primary", icon, size = "md", fullWidth }: Props) {
  const { colors } = useTheme();
  const styles = createStyles(colors);
  const isDisabled = disabled || loading;
  const isSecondary = variant === "secondary" || variant === "ghost";
  const contentColor = isDisabled ? colors.subtle : isSecondary ? colors.text : colors.white;
  const variantStyle = variant === "primary"
    ? styles.primary
    : variant === "secondary"
      ? styles.secondary
      : variant === "danger"
        ? styles.danger
        : styles.ghost;

  return (
    <Pressable
      onPress={onPress}
      disabled={isDisabled}
      style={({ pressed }) => [
        fullWidth && styles.fullWidth,
        pressed && !isDisabled && styles.pressed
      ]}
    >
      <View
        style={[
          styles.base,
          styles[size],
          variantStyle,
          {
            backgroundColor: isDisabled ? colors.lineSoft : variant === "primary" ? colors.blue : variant === "secondary" ? colors.violetSoft : variant === "danger" ? colors.red : "transparent",
            borderColor: isDisabled ? colors.lineSoft : variant === "primary" ? colors.blue : variant === "secondary" ? colors.violetSoft : variant === "danger" ? colors.red : colors.line
          },
          isDisabled && styles.disabled
        ]}
      >
        {loading ? (
          <ActivityIndicator color={contentColor} />
        ) : (
          <View style={styles.content}>
            {icon ? <Ionicons name={icon} size={size === "sm" ? 15 : 17} color={contentColor} /> : null}
            <Text allowFontScaling={false} style={[styles.label, { color: contentColor }]} numberOfLines={1}>{label}</Text>
          </View>
        )}
      </View>
    </Pressable>
  );
}

const createStyles = (colors: AppColors) => StyleSheet.create({
  base: {
    borderRadius: 999,
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 18,
    borderWidth: 1
  },
  content: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 8
  },
  md: {
    minHeight: 48
  },
  sm: {
    minHeight: 38,
    paddingHorizontal: 12
  },
  fullWidth: {
    alignSelf: "stretch"
  },
  primary: {
    backgroundColor: colors.blue,
    borderColor: colors.blue
  },
  secondary: {
    backgroundColor: colors.violetSoft,
    borderColor: colors.violetSoft
  },
  danger: {
    backgroundColor: colors.red,
    borderColor: colors.red
  },
  ghost: {
    backgroundColor: "transparent",
    borderColor: colors.line
  },
  disabled: {
    backgroundColor: colors.lineSoft,
    borderColor: colors.lineSoft
  },
  pressed: {
    transform: [{ scale: 0.99 }]
  },
  label: {
    fontWeight: "800",
    fontSize: 14
  }
});
