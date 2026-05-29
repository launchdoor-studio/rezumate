import { Ionicons } from "@expo/vector-icons";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";

import { Button } from "../components/Button";
import { useAuthStore } from "../store/authStore";
import type { AppColors, ThemeName } from "../theme/colors";
import { useTheme } from "../theme/ThemeProvider";

export function ProfileScreen() {
  const { colors, themeName, setThemeName } = useTheme();
  const styles = createStyles(colors, themeName === "dark");
  const email = useAuthStore((state) => state.email);
  const signOut = useAuthStore((state) => state.signOut);

  return (
    <SafeAreaView style={styles.safe} edges={["top"]}>
      <ScrollView contentContainerStyle={styles.container}>
        <View style={styles.headerCard}>
          <View style={styles.avatar}>
            <Ionicons name="person" size={26} color={colors.white} />
          </View>
          <View style={styles.profileCopy}>
            <Text allowFontScaling={false} style={styles.name} numberOfLines={1}>{email || "Rezumate User"}</Text>
            <Text allowFontScaling={false} style={styles.planPill}>Free plan</Text>
          </View>
          <View style={styles.settingsBubble}>
            <Ionicons name="settings-outline" size={20} color={colors.blue} />
          </View>
        </View>

        <View style={styles.statsCard}>
          <Limit label="Analyses" value="3/day" />
          <Limit label="Rewrites" value="3/day" />
          <Limit label="Exports" value="PDF" />
        </View>

        <View style={styles.sectionCard}>
          <View style={styles.sectionHeader}>
            <View style={styles.sectionIcon}>
              <Ionicons name="color-palette-outline" size={19} color={colors.blue} />
            </View>
            <View>
              <Text allowFontScaling={false} style={styles.title}>Appearance</Text>
              <Text allowFontScaling={false} style={styles.muted}>Choose how Rezumate looks.</Text>
            </View>
          </View>
          <View style={styles.segmented}>
            <ThemeOption label="Light" value="light" active={themeName === "light"} onPress={setThemeName} />
            <ThemeOption label="Dark" value="dark" active={themeName === "dark"} onPress={setThemeName} />
          </View>
        </View>

        <View style={styles.proCard}>
          <View style={styles.proBadge}>
            <Ionicons name="sparkles" size={20} color={colors.white} />
          </View>
          <Text allowFontScaling={false} style={styles.proTitle}>Rezumate Pro</Text>
          <Text allowFontScaling={false} style={styles.proCopy}>Higher limits, saved variants, ATS-safe PDF exports, and deeper rewrite suggestions.</Text>
          <Button label="Upgrade Coming Soon" icon="lock-closed-outline" variant="secondary" onPress={() => undefined} disabled fullWidth />
        </View>

        <Button label="Sign Out" icon="log-out-outline" variant="danger" onPress={signOut} fullWidth />
      </ScrollView>
    </SafeAreaView>
  );
}

function ThemeOption({ label, value, active, onPress }: { label: string; value: ThemeName; active: boolean; onPress: (value: ThemeName) => void }) {
  const { colors, themeName } = useTheme();
  const styles = createStyles(colors, themeName === "dark");
  return (
    <Pressable onPress={() => onPress(value)} style={[styles.segment, active && styles.segmentActive]}>
      <Text allowFontScaling={false} style={[styles.segmentLabel, active && styles.segmentLabelActive]}>{label}</Text>
    </Pressable>
  );
}

function Limit({ label, value }: { label: string; value: string }) {
  const { colors, themeName } = useTheme();
  const styles = createStyles(colors, themeName === "dark");
  return (
    <View style={styles.limit}>
      <Text style={styles.limitValue}>{value}</Text>
      <Text style={styles.limitLabel}>{label}</Text>
    </View>
  );
}

const createStyles = (colors: AppColors, isDark = false) => StyleSheet.create({
  safe: {
    flex: 1
  },
  container: {
    padding: 18,
    gap: 18,
    paddingBottom: 112
  },
  headerCard: {
    backgroundColor: isDark ? colors.panel2 : colors.text,
    borderColor: isDark ? colors.lineSoft : colors.text,
    borderWidth: 1,
    borderRadius: 30,
    padding: 20,
    flexDirection: "row",
    alignItems: "center",
    gap: 14
  },
  avatar: {
    width: 62,
    height: 62,
    borderRadius: 22,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: colors.blue,
    borderColor: colors.line,
    borderWidth: 1
  },
  profileCopy: {
    flex: 1,
    gap: 8
  },
  name: {
    color: colors.white,
    fontSize: 18,
    fontWeight: "900"
  },
  planPill: {
    alignSelf: "flex-start",
    color: colors.white,
    backgroundColor: colors.blue,
    borderRadius: 999,
    overflow: "hidden",
    paddingHorizontal: 10,
    paddingVertical: 5,
    fontSize: 11,
    fontWeight: "900"
  },
  settingsBubble: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: colors.surface,
    alignItems: "center",
    justifyContent: "center"
  },
  title: {
    color: colors.text,
    fontSize: 18,
    fontWeight: "900"
  },
  muted: {
    color: colors.muted,
    lineHeight: 21
  },
  sectionCard: {
    backgroundColor: colors.surface,
    borderColor: colors.lineSoft,
    borderWidth: 1,
    borderRadius: 24,
    padding: 16,
    gap: 14
  },
  sectionHeader: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12
  },
  sectionIcon: {
    width: 46,
    height: 46,
    borderRadius: 16,
    backgroundColor: colors.violetSoft,
    alignItems: "center",
    justifyContent: "center"
  },
  sectionLabel: {
    color: colors.muted,
    fontSize: 12,
    fontWeight: "900",
    textTransform: "uppercase"
  },
  segmented: {
    flexDirection: "row",
    backgroundColor: colors.panel2,
    borderRadius: 999,
    padding: 4,
    borderColor: colors.lineSoft,
    borderWidth: 1
  },
  segment: {
    flex: 1,
    minHeight: 40,
    borderRadius: 999,
    alignItems: "center",
    justifyContent: "center"
  },
  segmentActive: {
    backgroundColor: colors.surface,
    borderColor: colors.lineSoft,
    borderWidth: 1
  },
  segmentLabel: {
    color: colors.muted,
    fontSize: 13,
    fontWeight: "800"
  },
  segmentLabelActive: {
    color: colors.text
  },
  statsCard: {
    flexDirection: "row",
    gap: 12,
    backgroundColor: colors.surface,
    borderColor: colors.lineSoft,
    borderWidth: 1,
    borderRadius: 28,
    padding: 14
  },
  limit: {
    flex: 1,
    backgroundColor: isDark ? colors.panel3 : colors.panel2,
    borderRadius: 20,
    paddingVertical: 14,
    paddingHorizontal: 8,
    alignItems: "center"
  },
  limitValue: {
    color: colors.text,
    fontSize: 20,
    fontWeight: "900"
  },
  limitLabel: {
    color: colors.muted,
    fontSize: 12,
    fontWeight: "800"
  },
  proCard: {
    backgroundColor: colors.surface,
    borderColor: colors.lineSoft,
    borderWidth: 1,
    borderRadius: 30,
    padding: 22,
    alignItems: "center",
    gap: 12
  },
  proBadge: {
    width: 50,
    height: 50,
    borderRadius: 18,
    backgroundColor: colors.blue,
    alignItems: "center",
    justifyContent: "center"
  },
  proTitle: {
    color: colors.text,
    fontSize: 20,
    fontWeight: "900"
  },
  proCopy: {
    color: colors.muted,
    fontSize: 13,
    lineHeight: 19,
    textAlign: "center"
  }
});
