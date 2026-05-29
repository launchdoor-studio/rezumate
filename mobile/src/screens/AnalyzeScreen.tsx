import type { NativeStackNavigationProp } from "@react-navigation/native-stack";
import { useNavigation } from "@react-navigation/native";
import { Ionicons } from "@expo/vector-icons";
import * as DocumentPicker from "expo-document-picker";
import { useState } from "react";
import { Alert, KeyboardAvoidingView, Platform, Pressable, ScrollView, StyleSheet, Text, TextInput, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";

import { analyzeResume, uploadResume } from "../lib/api";
import { Button } from "../components/Button";
import { useAnalysisStore } from "../store/analysisStore";
import { useAuthStore } from "../store/authStore";
import type { AppColors } from "../theme/colors";
import { useTheme } from "../theme/ThemeProvider";
import type { RootStackParamList } from "../types/navigation";

export function AnalyzeScreen() {
  const { colors, themeName } = useTheme();
  const styles = createStyles(colors, themeName === "dark");
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const token = useAuthStore((state) => state.token);
  const upload = useAnalysisStore((state) => state.upload);
  const jobDescription = useAnalysisStore((state) => state.jobDescription);
  const setUpload = useAnalysisStore((state) => state.setUpload);
  const setJobDescription = useAnalysisStore((state) => state.setJobDescription);
  const setResult = useAnalysisStore((state) => state.setResult);
  const reset = useAnalysisStore((state) => state.reset);
  const [isUploading, setUploading] = useState(false);
  const [isAnalyzing, setAnalyzing] = useState(false);

  async function pickDocument() {
    const picked = await DocumentPicker.getDocumentAsync({
      type: [
        "application/pdf",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      ],
      copyToCacheDirectory: true,
      multiple: false
    });

    if (picked.canceled) return;
    const asset = picked.assets[0];
    if (!asset || !token) return;

    setUploading(true);
    try {
      const response = await uploadResume(
        {
          uri: asset.uri,
          name: asset.name,
          mimeType: asset.mimeType
        },
        token
      );
      setUpload(response);
    } catch (error) {
      Alert.alert("Upload failed", error instanceof Error ? error.message : "Could not upload resume");
    } finally {
      setUploading(false);
    }
  }

  async function runAnalysis() {
    if (!token || !upload) return;
    if (!jobDescription.trim()) {
      Alert.alert("Job description required", "Paste the job description before analyzing.");
      return;
    }

    setAnalyzing(true);
    try {
      const response = await analyzeResume({
        resumeId: upload.resume_id,
        resumeText: upload.extracted_text,
        jobDescription,
        token
      });
      setResult(response);
      navigation.navigate("Results", { result: response });
    } catch (error) {
      Alert.alert("Analysis failed", error instanceof Error ? error.message : "Could not analyze resume");
    } finally {
      setAnalyzing(false);
    }
  }

  return (
    <KeyboardAvoidingView behavior={Platform.OS === "ios" ? "padding" : undefined} style={styles.flex}>
      <SafeAreaView style={styles.flex} edges={["top"]}>
        <ScrollView contentContainerStyle={styles.container} keyboardShouldPersistTaps="handled">
          <View style={styles.topBar}>
            <View style={styles.searchPill}>
              <Ionicons name="search" size={16} color={colors.muted} />
              <Text allowFontScaling={false} style={styles.searchText}>Search shortlisted profile...</Text>
            </View>
            <View style={styles.bell}>
              <Ionicons name="notifications-outline" size={18} color={colors.blue} />
              <View style={styles.dot} />
            </View>
          </View>

          <View style={styles.hero}>
            <View style={styles.heroIcon}>
              <Ionicons name="cloud-upload" size={22} color={colors.white} />
            </View>
            <Text allowFontScaling={false} style={styles.heroTitle}>Upload Resume</Text>
            <Text allowFontScaling={false} style={styles.heroCopy}>Upload a PDF or DOCX. The AI parser extracts experience, skills, education, and more.</Text>
            <Pressable onPress={pickDocument} disabled={isUploading} style={({ pressed }) => [styles.uploadPill, pressed && styles.pressed]}>
              <View style={styles.fileRow}>
                <Ionicons name={upload ? "checkmark-circle" : "document-attach-outline"} size={20} color={upload ? colors.green : colors.blue} />
                <View style={styles.fileCopy}>
                  <Text allowFontScaling={false} style={styles.fileName} numberOfLines={1}>{upload ? upload.filename : "Choose resume file"}</Text>
                  <Text allowFontScaling={false} style={styles.meta}>{upload ? `${upload.character_count.toLocaleString()} characters extracted` : "PDF or DOCX resume"}</Text>
                </View>
                <Ionicons name="chevron-forward" size={18} color={colors.muted} />
              </View>
            </Pressable>
          </View>

          {upload ? (
            <View style={styles.profileCard}>
              <View style={styles.profileHeader}>
                <View>
                  <Text allowFontScaling={false} style={styles.profileName}>{upload.filename}</Text>
                  <Text allowFontScaling={false} style={styles.profileRole}>Parsed resume</Text>
                </View>
                <View style={styles.matchBadge}>
                  <Text allowFontScaling={false} style={styles.matchText}>Ready</Text>
                </View>
              </View>
              <View style={styles.statsRow}>
                <Stat value={upload.character_count.toLocaleString()} label="Characters" />
                <Stat value={upload.warnings.length.toString()} label="Warnings" />
                <Stat value="ATS" label="Mode" />
              </View>
              {upload.warnings.length ? (
                <View style={styles.warningList}>
                  {upload.warnings.map((warning) => (
                    <Text allowFontScaling={false} key={warning} style={styles.warning}>{warning}</Text>
                  ))}
                </View>
              ) : null}
              <View style={styles.row}>
                <Button label="Replace" icon="cloud-upload-outline" variant="secondary" size="sm" loading={isUploading} onPress={pickDocument} />
                <Button label="Reset" icon="refresh" variant="ghost" size="sm" onPress={reset} />
              </View>
            </View>
          ) : null}

          <View style={styles.formCard}>
            <View style={styles.sectionHeader}>
              <View style={[styles.iconBadge, styles.violetBadge]}>
                <Ionicons name="briefcase-outline" size={19} color={colors.violet} />
              </View>
              <View style={styles.sectionCopy}>
                <Text allowFontScaling={false} style={styles.title}>Target role</Text>
                <Text allowFontScaling={false} style={styles.copy}>Paste the job description for matching.</Text>
              </View>
            </View>
            <TextInput
              value={jobDescription}
              onChangeText={setJobDescription}
              multiline
              textAlignVertical="top"
              placeholder="Paste the role description here..."
              placeholderTextColor={colors.muted}
              allowFontScaling={false}
              style={styles.textarea}
            />
          </View>

          <View style={styles.actionCard}>
            <View style={styles.actionCopy}>
              <Text allowFontScaling={false} style={styles.actionTitle}>Instant CV parsing</Text>
              <Text allowFontScaling={false} style={styles.copy}>
                {!upload ? "Upload a resume to continue." : !jobDescription.trim() ? "Paste the job description to continue." : "Analysis usually takes a few seconds."}
              </Text>
            </View>
            <Button
              label="Analyze Resume"
              icon="sparkles-outline"
              loading={isAnalyzing}
              disabled={!upload || !jobDescription.trim()}
              onPress={runAnalysis}
              fullWidth
            />
          </View>
        </ScrollView>
      </SafeAreaView>
    </KeyboardAvoidingView>
  );
}

const createStyles = (colors: AppColors, isDark = false) => StyleSheet.create({
  flex: { flex: 1 },
  container: {
    padding: 18,
    gap: 18,
    paddingBottom: 112
  },
  topBar: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
    paddingTop: 4
  },
  searchPill: {
    flex: 1,
    minHeight: 44,
    borderRadius: 999,
    backgroundColor: colors.surface,
    borderColor: colors.lineSoft,
    borderWidth: 1,
    paddingHorizontal: 14,
    flexDirection: "row",
    alignItems: "center",
    gap: 8
  },
  searchText: {
    color: colors.subtle,
    fontSize: 13,
    fontWeight: "600"
  },
  bell: {
    width: 44,
    height: 44,
    borderRadius: 22,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: colors.surface,
    borderColor: colors.lineSoft,
    borderWidth: 1
  },
  dot: {
    position: "absolute",
    top: 10,
    right: 11,
    width: 7,
    height: 7,
    borderRadius: 4,
    backgroundColor: colors.blue
  },
  hero: {
    backgroundColor: isDark ? colors.panel2 : colors.text,
    borderColor: isDark ? colors.lineSoft : colors.text,
    borderWidth: 1,
    borderRadius: 26,
    padding: 22,
    alignItems: "center",
    gap: 11
  },
  heroIcon: {
    width: 38,
    height: 38,
    borderRadius: 19,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: colors.blue
  },
  heroTitle: {
    color: colors.white,
    fontSize: 16,
    fontWeight: "900"
  },
  heroCopy: {
    color: isDark ? colors.muted : "#D8D2E1",
    fontSize: 12,
    lineHeight: 17,
    textAlign: "center"
  },
  uploadPill: {
    alignSelf: "stretch",
    minHeight: 58,
    borderRadius: 18,
    backgroundColor: colors.surface,
    paddingHorizontal: 14,
    justifyContent: "center",
    marginTop: 4
  },
  sectionHeader: {
    flexDirection: "row",
    gap: 12,
    alignItems: "center"
  },
  iconBadge: {
    width: 48,
    height: 48,
    borderRadius: 15,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: colors.tintSoft,
    borderColor: colors.line,
    borderWidth: 1
  },
  violetBadge: {
    backgroundColor: colors.violetSoft,
    borderColor: colors.line
  },
  sectionCopy: {
    flex: 1,
    gap: 3
  },
  title: {
    color: colors.text,
    fontSize: 20,
    fontWeight: "900"
  },
  copy: {
    color: colors.muted,
    fontSize: 13,
    lineHeight: 19
  },
  row: {
    flexDirection: "row",
    gap: 10,
    flexWrap: "wrap"
  },
  profileCard: {
    backgroundColor: colors.surface,
    borderRadius: 22,
    borderColor: colors.lineSoft,
    borderWidth: 1,
    padding: 16,
    gap: 14
  },
  profileHeader: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12
  },
  profileName: {
    color: colors.text,
    fontSize: 16,
    fontWeight: "900",
    maxWidth: 210
  },
  profileRole: {
    color: colors.muted,
    fontSize: 12,
    fontWeight: "700",
    marginTop: 3
  },
  matchBadge: {
    marginLeft: "auto",
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 6,
    backgroundColor: colors.violetSoft
  },
  matchText: {
    color: colors.blue,
    fontSize: 11,
    fontWeight: "900"
  },
  statsRow: {
    flexDirection: "row",
    borderTopColor: colors.lineSoft,
    borderTopWidth: 1,
    paddingTop: 12
  },
  stat: {
    flex: 1,
    alignItems: "center",
    gap: 2
  },
  statValue: {
    color: colors.text,
    fontSize: 15,
    fontWeight: "900"
  },
  statLabel: {
    color: colors.muted,
    fontSize: 11,
    fontWeight: "700"
  },
  pressed: {
    opacity: 0.78
  },
  warningList: {
    gap: 6
  },
  fileRow: {
    flexDirection: "row",
    gap: 10,
    alignItems: "center"
  },
  fileCopy: {
    flex: 1,
    gap: 3
  },
  fileName: {
    color: colors.text,
    fontWeight: "900"
  },
  meta: {
    color: colors.muted,
    fontSize: 13
  },
  warning: {
    color: colors.amber,
    fontSize: 13,
    fontWeight: "700"
  },
  textarea: {
    minHeight: 190,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: colors.line,
    color: colors.text,
    backgroundColor: colors.input,
    padding: 16,
    fontSize: 15,
    lineHeight: 21
  },
  actionCard: {
    backgroundColor: colors.surface,
    borderColor: colors.lineSoft,
    borderWidth: 1,
    borderRadius: 22,
    padding: 16,
    gap: 12,
  },
  formCard: {
    backgroundColor: colors.surface,
    borderColor: colors.lineSoft,
    borderWidth: 1,
    borderRadius: 26,
    padding: 18,
    gap: 16
  },
  actionCopy: {
    gap: 3
  },
  actionTitle: {
    color: colors.text,
    fontSize: 16,
    fontWeight: "900"
  }
});

function Stat({ value, label }: { value: string; label: string }) {
  const { colors, themeName } = useTheme();
  const styles = createStyles(colors, themeName === "dark");

  return (
    <View style={styles.stat}>
      <Text allowFontScaling={false} style={styles.statValue} numberOfLines={1}>{value}</Text>
      <Text allowFontScaling={false} style={styles.statLabel}>{label}</Text>
    </View>
  );
}
