import { Buffer } from 'buffer';
import { useMemo } from 'react';
import { StatusBar, StyleSheet, useColorScheme } from 'react-native';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { BleControllerProvider } from './src/hooks/useBleController';
import { RootNavigator } from './src/navigation/RootNavigator';

const globalForBuffer = globalThis as typeof globalThis & { Buffer?: typeof Buffer };

if (!globalForBuffer.Buffer) {
  globalForBuffer.Buffer = Buffer;
}

function App() {
  const isDarkMode = useColorScheme() === 'dark';
  const barStyle = useMemo(() => (isDarkMode ? 'light-content' : 'dark-content'), [isDarkMode]);

  return (
    <GestureHandlerRootView style={styles.root}>
      <SafeAreaProvider>
        <BleControllerProvider>
          <StatusBar barStyle={barStyle} backgroundColor="transparent" translucent />
          <RootNavigator />
        </BleControllerProvider>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}

export default App;

const styles = StyleSheet.create({
  root: {
    flex: 1,
  },
});
