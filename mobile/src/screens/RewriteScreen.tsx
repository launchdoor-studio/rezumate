import type { NativeStackNavigationProp } from "@react-navigation/native-stack";
import type { RouteProp } from "@react-navigation/native";
import { useNavigation, useRoute } from "@react-navigation/native";
import { Ionicons } from "@expo/vector-icons";
import { useState } from "react";
import { Alert, ScrollView, StyleSheet, Text, View } from "react-native";

import { Button } from "../components/Button";
import { Card } from "../components/Card";
import { rewriteBullet } from "../lib/api";
import { useAnalysisStore } from "../store/analysisStore";
import { useAuthStore } from "../store/authStore";
import type { AppColors } from "../theme/colors";
import { useTheme } from "../theme/ThemeProvider";
import type { RootStackParamList } from "../types/navigation";

export function RewriteScreen() {
  const { colors } = useTheme();
  const styles = createStyles(colors);
  const route = useRoute<RouteProp<RootStackParamList, "Rewrite">>();
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const token = useAuthStore((state) => state.token);
  const acceptRewrite = useAnalysisStore((state) => state.acceptRewrite);
  const [suggestions, setSuggestions] = useState<string[]>([]);
  const [isLoading, setLoading] = useState(false);
  const bullet = route.params.bullet;

  async function loadSuggestions() {
    if (!token) return;
    setLoading(true);
    try {
      const response = await rewriteBullet({
        bullet,
        focusKeywords: route.params.missingKeywords,
        token
      });
      setSuggestions(response.rewritten_bullets);
    } catch (error) {
      Alert.alert("Rewrite failed", error instanceof Error ? error.message : "Could not rewrite bullet");
    } finally {
      setLoading(false);
    }
  }

  function accept(suggestion: string) {
    acceptRewrite(bullet, suggestion);
    navigation.goBack();
  }

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Card elevated>
        <View style={styles.headerRow}>
          <Ionicons name="create-outline" size={18} color={colors.cyan} />
          <Text style={styles.label}>Original</Text>
        </View>
        <Text style={styles.original}>{bullet}</Text>
        <Button label="Generate Suggestions" icon="sparkles-outline" loading={isLoading} onPress={loadSuggestions} />
      </Card>

      {suggestions.map((suggestion, index) => (
        <Card key={suggestion}>
          <Text style={styles.optionLabel}>Option {index + 1}</Text>
          <Text style={styles.suggestion}>{suggestion}</Text>
          <Button label="Accept Rewrite" icon="checkmark-outline" onPress={() => accept(suggestion)} />
        </Card>
      ))}

      {!suggestions.length && !isLoading ? (
        <View style={styles.empty}>
          <Text style={styles.muted}>Generate rewrites to see three role-aware suggestions.</Text>
        </View>
      ) : null}
    </ScrollView>
  );
}

const createStyles = (colors: AppColors) => StyleSheet.create({
  container: {
    padding: 16,
    gap: 16
  },
  headerRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8
  },
  label: {
    color: colors.text,
    textTransform: "uppercase",
    fontSize: 12,
    fontWeight: "900"
  },
  optionLabel: {
    color: colors.cyan,
    textTransform: "uppercase",
    fontSize: 11,
    fontWeight: "900"
  },
  original: {
    color: colors.text,
    fontSize: 15,
    lineHeight: 22,
    fontWeight: "700"
  },
  suggestion: {
    color: colors.text,
    fontSize: 15,
    lineHeight: 22,
    fontWeight: "700"
  },
  empty: {
    padding: 12
  },
  muted: {
    color: colors.muted,
    lineHeight: 21
  }
});
