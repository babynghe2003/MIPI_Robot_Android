import { memo } from 'react';
import { Pressable, StyleSheet, Text } from 'react-native';
import type { ControlCommand } from '../types/control';

interface ControlButtonProps {
  label: string;
  command: ControlCommand;
  onPressIn: (command: ControlCommand) => void;
  onPressOut: () => void;
  isActive?: boolean;
}

export const ControlButton = memo<ControlButtonProps>(({ label, command, onPressIn, onPressOut, isActive }) => (
  <Pressable
    onPressIn={() => onPressIn(command)}
    onPressOut={onPressOut}
    style={({ pressed }) => [styles.base, (pressed || isActive) && styles.active]}
  >
    <Text style={styles.label}>{label}</Text>
  </Pressable>
));

const styles = StyleSheet.create({
  base: {
    backgroundColor: '#1f2937',
    borderRadius: 18,
    paddingVertical: 16,
    paddingHorizontal: 24,
    alignItems: 'center',
    justifyContent: 'center',
    minWidth: 96,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.2,
    shadowRadius: 12,
    elevation: 6,
  },
  active: {
    backgroundColor: '#3b82f6',
    transform: [{ scale: 0.98 }],
  },
  label: {
    color: '#f8fafc',
    fontWeight: '600',
    fontSize: 16,
    letterSpacing: 0.8,
    textTransform: 'uppercase',
  },
});
