import { Ionicons } from "@expo/vector-icons";
import { createBottomTabNavigator } from "@react-navigation/bottom-tabs";

import { AnalyzeScreen } from "../screens/AnalyzeScreen";
import { ProfileScreen } from "../screens/ProfileScreen";
import { ResumesScreen } from "../screens/ResumesScreen";
import { useTheme } from "../theme/ThemeProvider";
import type { TabParamList } from "../types/navigation";

const Tab = createBottomTabNavigator<TabParamList>();

export function Tabs() {
  const { colors } = useTheme();

  return (
    <Tab.Navigator
      screenOptions={({ route }) => ({
        headerShown: false,
        headerStyle: { backgroundColor: colors.ink },
        headerTintColor: colors.text,
        headerTitleStyle: { fontWeight: "900" },
        tabBarStyle: {
          backgroundColor: colors.tab,
          borderTopColor: colors.lineSoft,
          borderWidth: 1,
          height: 82,
          paddingBottom: 15,
          paddingTop: 8,
          marginHorizontal: 16,
          marginBottom: 12,
          borderRadius: 28,
          position: "absolute"
        },
        tabBarActiveTintColor: colors.blue,
        tabBarInactiveTintColor: colors.muted,
        tabBarAllowFontScaling: false,
        tabBarLabelStyle: { fontWeight: "800", fontSize: 11 },
        tabBarIcon: ({ color, size }) => {
          const name = route.name === "Analyze" ? "scan" : route.name === "Resumes" ? "documents" : "person-circle";
          return <Ionicons name={name} size={size} color={color} />;
        }
      })}
    >
      <Tab.Screen name="Analyze" component={AnalyzeScreen} options={{ title: "Analyze" }} />
      <Tab.Screen name="Resumes" component={ResumesScreen} options={{ title: "Resumes" }} />
      <Tab.Screen name="Profile" component={ProfileScreen} options={{ title: "Profile" }} />
    </Tab.Navigator>
  );
}
