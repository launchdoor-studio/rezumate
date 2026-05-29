import { useState } from "react";
import { Ionicons } from "@expo/vector-icons";
import { KeyboardAvoidingView, Platform, StyleSheet, Text, TextInput, View } from "react-native";

import { Button } from "../components/Button";
import { Card } from "../components/Card";
import { hasSupabaseConfig } from "../lib/supabase";
import { useAuthStore } from "../store/authStore";
import type { AppColors } from "../theme/colors";
import { useTheme } from "../theme/ThemeProvider";

export function AuthScreen() {
  const { colors } = useTheme();
  const styles = createStyles(colors);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const signIn = useAuthStore((state) => state.signIn);
  const signUp = useAuthStore((state) => state.signUp);
  const useDevSession = useAuthStore((state) => state.useDevSession);
  const isLoading = useAuthStore((state) => state.isLoading);
  const error = useAuthStore((state) => state.error);

  return (
    <KeyboardAvoidingView behavior={Platform.OS === "ios" ? "padding" : undefined} style={styles.container}>
      <View style={styles.header}>
        <View style={styles.mark}>
          <Ionicons name="sparkles" size={22} color={colors.white} />
        </View>
        <Text style={styles.logo}>Rezumate</Text>
        <Text style={styles.subtitle}>Tailor a resume to a role in minutes.</Text>
      </View>

      <Card elevated>
        <Text style={styles.cardTitle}>{hasSupabaseConfig ? "Sign in" : "Developer session"}</Text>
        <TextInput
          autoCapitalize="none"
          keyboardType="email-address"
          placeholder="Email"
          placeholderTextColor={colors.muted}
          value={email}
          onChangeText={setEmail}
          style={styles.input}
        />
        <TextInput
          placeholder="Password"
          placeholderTextColor={colors.muted}
          value={password}
          onChangeText={setPassword}
          secureTextEntry
          style={styles.input}
        />
        {error ? <Text style={styles.error}>{error}</Text> : null}
        <Button label="Sign In" icon="log-in-outline" loading={isLoading} onPress={() => signIn(email, password)} fullWidth />
        <Button label="Create Account" icon="person-add-outline" variant="secondary" loading={isLoading} onPress={() => signUp(email, password)} fullWidth />
        <Button label="Continue with Dev Token" icon="terminal-outline" onPress={useDevSession} fullWidth />
      </Card>
    </KeyboardAvoidingView>
  );
}

const createStyles = (colors: AppColors) => StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: "center",
    backgroundColor: colors.ink,
    padding: 20,
    gap: 28
  },
  header: {
    gap: 8
  },
  mark: {
    width: 46,
    height: 46,
    borderRadius: 14,
    backgroundColor: colors.blue,
    alignItems: "center",
    justifyContent: "center",
    borderColor: colors.line,
    borderWidth: 1
  },
  logo: {
    color: colors.text,
    fontSize: 40,
    fontWeight: "900"
  },
  subtitle: {
    color: colors.muted,
    fontSize: 17,
    lineHeight: 24
  },
  cardTitle: {
    color: colors.text,
    fontSize: 18,
    fontWeight: "900"
  },
  input: {
    minHeight: 48,
    borderRadius: 18,
    borderWidth: 1,
    borderColor: colors.line,
    color: colors.text,
    backgroundColor: colors.input,
    paddingHorizontal: 14,
    fontSize: 15
  },
  error: {
    color: colors.red,
    fontWeight: "700"
  }
});
