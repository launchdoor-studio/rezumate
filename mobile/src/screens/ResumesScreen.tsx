import type { NativeStackNavigationProp } from "@react-navigation/native-stack";
import { useFocusEffect, useNavigation } from "@react-navigation/native";
import { Ionicons } from "@expo/vector-icons";
import { useCallback, useState } from "react";
import { Alert, FlatList, Pressable, RefreshControl, StyleSheet, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";

import { Button } from "../components/Button";
import { exportVariant, getHistory, getVariant } from "../lib/api";
import { useAuthStore } from "../store/authStore";
import type { AppColors } from "../theme/colors";
import { useTheme } from "../theme/ThemeProvider";
import type { VariantSummary } from "../types/api";
import type { RootStackParamList } from "../types/navigation";

export function ResumesScreen() {
  const { colors } = useTheme();
  const styles = createStyles(colors);
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const token = useAuthStore((state) => state.token);
  const [items, setItems] = useState<VariantSummary[]>([]);
  const [isLoading, setLoading] = useState(false);
  const [loadError, setLoadError] = useState<string | null>(null);

  const load = useCallback(async () => {
    if (!token) return;
    setLoading(true);
    try {
      const response = await getHistory(token);
      setItems(response.variants);
      setLoadError(null);
    } catch (error) {
      setLoadError(error instanceof Error ? error.message : "Try again later");
    } finally {
      setLoading(false);
    }
  }, [token]);

  useFocusEffect(useCallback(() => {
    load();
  }, [load]));

  async function openVariant(item: VariantSummary) {
    if (!token) return;
    try {
      const variant = await getVariant(item.id, token);
      const feedback = variant.analysis_feedback as Record<string, unknown>;
      navigation.navigate("Results", {
        result: {
          success: true,
          variant_id: item.id,
          score: Number(variant.ats_score || feedback.score || 0),
          matched_keywords: (feedback.matched_keywords as string[]) || [],
          missing_keywords: (feedback.missing_keywords as string[]) || [],
          weak_bullets: (feedback.weak_bullets as string[]) || [],
          bullets_without_measurable_impact: (feedback.bullets_without_measurable_impact as string[]) || [],
          formatting_warnings: (feedback.formatting_warnings as string[]) || [],
          component_scores: (feedback.component_scores as Record<string, number>) || {}
        }
      });
    } catch (error) {
      Alert.alert("Could not open variant", error instanceof Error ? error.message : "Try again later");
    }
  }

  async function share(item: VariantSummary) {
    if (!token) return;
    try {
      await exportVariant(item.id, token);
    } catch (error) {
      Alert.alert("Export failed", error instanceof Error ? error.message : "Could not export PDF");
    }
  }

  return (
    <SafeAreaView style={styles.safe} edges={["top"]}>
      <FlatList
        data={items}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.container}
        refreshControl={<RefreshControl refreshing={isLoading} onRefresh={load} tintColor={colors.blue} />}
        ListHeaderComponent={
          <View style={styles.headerWrap}>
            <View style={styles.topBar}>
              <View>
                <Text allowFontScaling={false} style={styles.kicker}>Shortlisted</Text>
                <Text allowFontScaling={false} style={styles.screenTitle}>Resume variants</Text>
              </View>
              <View style={styles.countBubble}>
                <Text allowFontScaling={false} style={styles.countText}>{items.length}</Text>
              </View>
            </View>
            <View style={styles.searchPill}>
              <Ionicons name="search" size={16} color={colors.muted} />
              <Text allowFontScaling={false} style={styles.searchText}>Search saved resumes...</Text>
            </View>
          </View>
        }
        ListEmptyComponent={
          <View style={styles.emptyCard}>
            <View style={styles.emptyIcon}>
              <Ionicons name={loadError ? "cloud-offline-outline" : "document-text-outline"} size={28} color={colors.blue} />
            </View>
            <Text allowFontScaling={false} style={styles.emptyTitle}>{loadError ? "Could not load history" : "No resumes shortlisted yet"}</Text>
            <Text allowFontScaling={false} style={styles.muted}>{loadError || "Run an analysis and your tailored variants will appear here."}</Text>
            {loadError ? <Button label="Try Again" icon="refresh" onPress={load} /> : null}
          </View>
        }
        renderItem={({ item }) => (
          <Pressable onPress={() => openVariant(item)} style={({ pressed }) => [styles.variantCard, pressed && styles.pressed]}>
            <View style={styles.row}>
              <View style={styles.docIcon}>
                <Ionicons name="document-text" size={22} color={colors.blue} />
              </View>
              <View style={styles.itemCopy}>
                <Text allowFontScaling={false} style={styles.title} numberOfLines={1}>{item.variant_name}</Text>
                <Text allowFontScaling={false} style={styles.muted}>{formatDate(item.created_at)}</Text>
              </View>
              <View style={styles.matchBadge}>
                <Text allowFontScaling={false} style={styles.matchText}>{item.ats_score ?? "--"}%</Text>
                <Text allowFontScaling={false} style={styles.matchLabel}>Matched</Text>
              </View>
            </View>
            <View style={styles.actionRow}>
              <Button label="Open" icon="scan-outline" variant="secondary" size="sm" onPress={() => openVariant(item)} />
              <Button label="Export" icon="download-outline" size="sm" onPress={() => share(item)} />
            </View>
          </Pressable>
        )}
      />
    </SafeAreaView>
  );
}

function formatDate(value: string) {
  return new Date(value).toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" });
}

const createStyles = (colors: AppColors) => StyleSheet.create({
  safe: {
    flex: 1
  },
  container: {
    padding: 18,
    gap: 18,
    paddingBottom: 112
  },
  headerWrap: {
    gap: 14,
    marginBottom: 2
  },
  topBar: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between"
  },
  kicker: {
    color: colors.blue,
    fontSize: 12,
    fontWeight: "900",
    textTransform: "uppercase"
  },
  screenTitle: {
    color: colors.text,
    fontSize: 30,
    fontWeight: "900"
  },
  countBubble: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: colors.surface,
    borderColor: colors.lineSoft,
    borderWidth: 1,
    alignItems: "center",
    justifyContent: "center"
  },
  countText: {
    color: colors.blue,
    fontSize: 17,
    fontWeight: "900"
  },
  searchPill: {
    minHeight: 50,
    borderRadius: 999,
    backgroundColor: colors.surface,
    borderColor: colors.lineSoft,
    borderWidth: 1,
    paddingHorizontal: 15,
    flexDirection: "row",
    alignItems: "center",
    gap: 8
  },
  searchText: {
    color: colors.subtle,
    fontSize: 13,
    fontWeight: "700"
  },
  variantCard: {
    backgroundColor: colors.surface,
    borderColor: colors.lineSoft,
    borderWidth: 1,
    borderRadius: 28,
    padding: 16,
    gap: 16
  },
  pressed: {
    opacity: 0.82
  },
  row: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12
  },
  docIcon: {
    width: 48,
    height: 48,
    borderRadius: 16,
    backgroundColor: colors.violetSoft,
    alignItems: "center",
    justifyContent: "center"
  },
  itemCopy: {
    flex: 1,
    gap: 4
  },
  title: {
    color: colors.text,
    fontSize: 16,
    fontWeight: "900"
  },
  muted: {
    color: colors.muted,
    fontSize: 13,
    lineHeight: 19
  },
  matchBadge: {
    minWidth: 76,
    borderRadius: 16,
    backgroundColor: colors.violetSoft,
    paddingVertical: 8,
    paddingHorizontal: 10,
    alignItems: "center"
  },
  matchText: {
    color: colors.blue,
    fontSize: 15,
    fontWeight: "900"
  },
  matchLabel: {
    color: colors.muted,
    fontSize: 10,
    fontWeight: "800"
  },
  actionRow: {
    flexDirection: "row",
    gap: 10
  },
  emptyCard: {
    minHeight: 260,
    backgroundColor: colors.surface,
    borderColor: colors.lineSoft,
    borderWidth: 1,
    borderRadius: 32,
    padding: 26,
    alignItems: "center",
    justifyContent: "center",
    gap: 12
  },
  emptyIcon: {
    width: 72,
    height: 72,
    borderRadius: 24,
    backgroundColor: colors.violetSoft,
    alignItems: "center",
    justifyContent: "center"
  },
  emptyTitle: {
    color: colors.text,
    fontSize: 18,
    fontWeight: "900",
    textAlign: "center"
  }
});
