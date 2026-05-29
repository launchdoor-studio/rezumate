import type { NativeStackNavigationProp } from "@react-navigation/native-stack";
import { useNavigation, useRoute } from "@react-navigation/native";
import type { RouteProp } from "@react-navigation/native";
import { Ionicons } from "@expo/vector-icons";
import { Alert, ScrollView, StyleSheet, Text, View } from "react-native";

import { Button } from "../components/Button";
import { Card } from "../components/Card";
import { Chip } from "../components/Chip";
import { ScoreRing } from "../components/ScoreRing";
import { exportVariant } from "../lib/api";
import { useAnalysisStore } from "../store/analysisStore";
import { useAuthStore } from "../store/authStore";
import type { AppColors } from "../theme/colors";
import { useTheme } from "../theme/ThemeProvider";
import type { RootStackParamList } from "../types/navigation";

export function ResultsScreen() {
  const { colors } = useTheme();
  const styles = createStyles(colors);
  const route = useRoute<RouteProp<RootStackParamList, "Results">>();
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const storedResult = useAnalysisStore((state) => state.result);
  const acceptedRewrites = useAnalysisStore((state) => state.acceptedRewrites);
  const token = useAuthStore((state) => state.token);
  const result = route.params?.result || storedResult;

  if (!result) {
    return (
      <View style={styles.empty}>
        <Text style={styles.title}>No analysis yet</Text>
        <Text style={styles.muted}>Upload a resume and run an analysis first.</Text>
      </View>
    );
  }

  async function shareExport() {
    if (!token || !result) return;
    try {
      await exportVariant(result.variant_id, token);
    } catch (error) {
      Alert.alert("Export failed", error instanceof Error ? error.message : "Could not export PDF");
    }
  }

  const weakBullets = [...result.weak_bullets, ...result.bullets_without_measurable_impact]
    .filter((item, index, all) => all.indexOf(item) === index);

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Card elevated>
        <View style={styles.scoreRow}>
          <ScoreRing score={result.score} />
          <View style={styles.scoreCopy}>
            <Text style={styles.kicker}>Analysis complete</Text>
            <Text style={styles.title}>Role Match</Text>
            <Text style={styles.muted}>Keyword fit, measurable impact, structure, and formatting risk.</Text>
          </View>
        </View>
      </Card>

      <Card>
        <SectionTitle icon="analytics-outline" label="Component Scores" />
        <View style={styles.grid}>
          {Object.entries(result.component_scores).map(([key, value]) => (
            <View key={key} style={styles.metric}>
              <Text style={styles.metricValue}>{value}</Text>
              <Text style={styles.metricLabel}>{formatKey(key)}</Text>
            </View>
          ))}
        </View>
      </Card>

      <Card>
        <SectionTitle icon="checkmark-done-outline" label="Matched Skills" />
        <View style={styles.chips}>
          {result.matched_keywords.length ? (
            result.matched_keywords.map((skill) => <Chip key={skill} label={skill} tone="green" />)
          ) : (
            <Text style={styles.muted}>No strong keyword matches found.</Text>
          )}
        </View>
      </Card>

      <Card>
        <SectionTitle icon="add-circle-outline" label="Missing Skills" />
        <View style={styles.chips}>
          {result.missing_keywords.length ? (
            result.missing_keywords.map((skill) => <Chip key={skill} label={skill} tone="red" />)
          ) : (
            <Text style={styles.muted}>No missing role keywords detected.</Text>
          )}
        </View>
      </Card>

      <Card>
        <SectionTitle icon="create-outline" label="Weak Bullets" />
        {weakBullets.length ? (
          weakBullets.map((bullet) => (
            <View key={bullet} style={styles.bulletCard}>
              <Text style={styles.bullet}>{acceptedRewrites[bullet] || bullet}</Text>
              {acceptedRewrites[bullet] ? <Text style={styles.accepted}>Rewrite accepted locally</Text> : null}
              <Button
                label="Rewrite"
                icon="sparkles-outline"
                variant="secondary"
                size="sm"
                onPress={() => navigation.navigate("Rewrite", { bullet, missingKeywords: result.missing_keywords })}
              />
            </View>
          ))
        ) : (
          <Text style={styles.muted}>No weak bullets detected.</Text>
        )}
      </Card>

      {result.formatting_warnings.length ? (
        <Card>
          <SectionTitle icon="warning-outline" label="Formatting Warnings" />
          {result.formatting_warnings.map((warning) => (
            <Text key={warning} style={styles.warning}>{warning}</Text>
          ))}
        </Card>
      ) : null}

      <Button label="Export ATS-safe PDF" icon="download-outline" onPress={shareExport} />
    </ScrollView>
  );
}

function SectionTitle({ icon, label }: { icon: keyof typeof Ionicons.glyphMap; label: string }) {
  const { colors } = useTheme();
  const styles = createStyles(colors);
  return (
    <View style={styles.sectionHeader}>
      <Ionicons name={icon} size={17} color={colors.cyan} />
      <Text style={styles.sectionTitle}>{label}</Text>
    </View>
  );
}

function formatKey(key: string) {
  return key.replace(/_/g, " ").replace(/\b\w/g, (match) => match.toUpperCase());
}

const createStyles = (colors: AppColors) => StyleSheet.create({
  container: {
    padding: 16,
    gap: 16,
    paddingBottom: 32
  },
  empty: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    padding: 24
  },
  scoreRow: {
    flexDirection: "row",
    gap: 16,
    alignItems: "center"
  },
  scoreCopy: {
    flex: 1,
    gap: 8
  },
  title: {
    color: colors.text,
    fontSize: 23,
    fontWeight: "900"
  },
  kicker: {
    color: colors.cyan,
    fontSize: 11,
    fontWeight: "900",
    textTransform: "uppercase"
  },
  sectionHeader: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8
  },
  sectionTitle: {
    color: colors.text,
    fontSize: 16,
    fontWeight: "900"
  },
  muted: {
    color: colors.muted,
    fontSize: 13,
    lineHeight: 19
  },
  chips: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 8
  },
  grid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 10
  },
  metric: {
    width: "47%",
    backgroundColor: colors.panel2,
    borderColor: colors.line,
    borderWidth: 1,
    borderRadius: 8,
    padding: 12
  },
  metricValue: {
    color: colors.text,
    fontSize: 22,
    fontWeight: "900"
  },
  metricLabel: {
    color: colors.muted,
    fontSize: 12,
    fontWeight: "800",
    marginTop: 4
  },
  bulletCard: {
    gap: 10,
    borderColor: colors.line,
    borderWidth: 1,
    borderRadius: 8,
    padding: 12,
    backgroundColor: colors.panel2
  },
  bullet: {
    color: colors.text,
    fontSize: 14,
    lineHeight: 20,
    fontWeight: "700"
  },
  accepted: {
    color: colors.green,
    fontWeight: "800",
    fontSize: 12
  },
  warning: {
    color: colors.amber,
    fontWeight: "700",
    lineHeight: 21
  }
});
