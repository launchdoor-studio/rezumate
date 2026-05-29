import "react-native-gesture-handler";

import { StatusBar } from "expo-status-bar";
import { NavigationContainer, DarkTheme, DefaultTheme } from "@react-navigation/native";
import { createNativeStackNavigator } from "@react-navigation/native-stack";
import { Text, TextInput } from "react-native";
import { SafeAreaProvider } from "react-native-safe-area-context";

import { AuthScreen } from "./src/screens/AuthScreen";
import { ResultsScreen } from "./src/screens/ResultsScreen";
import { RewriteScreen } from "./src/screens/RewriteScreen";
import { Tabs } from "./src/navigation/Tabs";
import { useAuthStore } from "./src/store/authStore";
import { RootStackParamList } from "./src/types/navigation";
import { ThemeProvider, useTheme } from "./src/theme/ThemeProvider";

const Stack = createNativeStackNavigator<RootStackParamList>();

(Text as unknown as { defaultProps: Record<string, unknown> }).defaultProps = {
  ...((Text as unknown as { defaultProps?: Record<string, unknown> }).defaultProps || {}),
  maxFontSizeMultiplier: 1.08
};

(TextInput as unknown as { defaultProps: Record<string, unknown> }).defaultProps = {
  ...((TextInput as unknown as { defaultProps?: Record<string, unknown> }).defaultProps || {}),
  maxFontSizeMultiplier: 1.08
};

export default function App() {
  return (
    <ThemeProvider>
      <AppShell />
    </ThemeProvider>
  );
}

function AppShell() {
  const token = useAuthStore((state) => state.token);
  const { colors, themeName } = useTheme();
  const baseTheme = themeName === "dark" ? DarkTheme : DefaultTheme;
  const navigationTheme = {
    ...baseTheme,
    colors: {
      ...baseTheme.colors,
      background: colors.ink,
      card: colors.panel,
      border: colors.line,
      primary: colors.blue,
      text: colors.text
    }
  };

  return (
    <SafeAreaProvider>
      <NavigationContainer theme={navigationTheme}>
        <StatusBar style={themeName === "dark" ? "light" : "dark"} />
        <Stack.Navigator
          screenOptions={{
            headerStyle: { backgroundColor: colors.ink },
            headerTintColor: colors.text,
            headerTitleStyle: { fontWeight: "800" },
            contentStyle: { backgroundColor: colors.ink }
          }}
        >
          {!token ? (
            <Stack.Screen name="Auth" component={AuthScreen} options={{ headerShown: false }} />
          ) : (
            <>
              <Stack.Screen name="Main" component={Tabs} options={{ headerShown: false }} />
              <Stack.Screen name="Results" component={ResultsScreen} options={{ title: "Analysis" }} />
              <Stack.Screen name="Rewrite" component={RewriteScreen} options={{ title: "Rewrite Bullet", presentation: "modal" }} />
            </>
          )}
        </Stack.Navigator>
      </NavigationContainer>
    </SafeAreaProvider>
  );
}
