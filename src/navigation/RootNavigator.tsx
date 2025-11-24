import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { DefaultTheme, NavigationContainer } from '@react-navigation/native';
import type { Theme } from '@react-navigation/native';
import type { ReactNode } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { ControlScreen } from '../screens/ControlScreen';
import { PidScreen } from '../screens/PidScreen';

const Tab = createBottomTabNavigator();

const navTheme: Theme = {
  ...DefaultTheme,
  colors: {
    ...DefaultTheme.colors,
    primary: '#3b82f6',
    background: '#f1f5f9',
    card: '#ffffff',
    text: '#0f172a',
    border: '#e2e8f0',
    notification: '#3b82f6',
  },
};

const TabBarLabel = ({ label, focused }: { label: string; focused: boolean }) => (
  <View style={styles.tabLabelContainer}>
    <Text style={[styles.tabLabel, focused && styles.tabLabelFocused]}>{label}</Text>
  </View>
);

type TabLabelProps = { focused: boolean; children: ReactNode };

const renderTabLabel = ({ focused, children }: TabLabelProps) => (
  <TabBarLabel label={children as string} focused={focused} />
);

export const RootNavigator = () => (
  <NavigationContainer theme={navTheme}>
    <Tab.Navigator
      screenOptions={{
        headerShown: false,
        tabBarStyle: styles.tabBar,
        tabBarLabel: renderTabLabel,
      }}
    >
      <Tab.Screen name="Điều khiển" component={ControlScreen} />
      <Tab.Screen name="PID Tuning" component={PidScreen} />
    </Tab.Navigator>
  </NavigationContainer>
);

const styles = StyleSheet.create({
  tabBar: {
    backgroundColor: '#ffffff',
    borderTopLeftRadius: 18,
    borderTopRightRadius: 18,
    height: 70,
    borderTopWidth: 0,
    elevation: 12,
    shadowColor: '#000',
    shadowOpacity: 0.08,
    shadowRadius: 12,
    paddingBottom: 10,
  },
  tabLabelContainer: {
    alignItems: 'center',
  },
  tabLabel: {
    fontWeight: '600',
    color: '#0f172a',
  },
  tabLabelFocused: {
    color: '#3b82f6',
  },
});
