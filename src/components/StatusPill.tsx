import { memo } from 'react';
import { StyleSheet, Text, View } from 'react-native';

interface StatusPillProps {
  label: string;
  status: 'connected' | 'disconnected' | 'scanning';
}

const COLORS = {
  connected: '#22c55e',
  disconnected: '#ef4444',
  scanning: '#fb923c',
};

export const StatusPill = memo<StatusPillProps>(({ label, status }) => (
  <View style={[styles.container, { backgroundColor: `${COLORS[status]}20`, borderColor: COLORS[status] }]}>
    <View style={[styles.dot, { backgroundColor: COLORS[status] }]} />
    <Text style={styles.label}>{label}</Text>
  </View>
));

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 999,
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderWidth: 1,
    gap: 8,
  },
  dot: {
    width: 10,
    height: 10,
    borderRadius: 999,
  },
  label: {
    color: '#0f172a',
    fontWeight: '600',
    letterSpacing: 0.5,
  },
});
