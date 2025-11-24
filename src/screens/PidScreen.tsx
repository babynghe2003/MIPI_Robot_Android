import { useEffect, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { DEFAULT_PID, PID_LIMITS } from '../constants/ble';
import { PidInputCard } from '../components/PidInputCard';
import { useBleController } from '../hooks/useBleController';
import type { PidGains } from '../types/control';

interface ActionButtonProps {
  label: string;
  onPress: () => void;
  disabled?: boolean;
}

const ActionButton = ({ label, onPress, disabled }: ActionButtonProps) => (
  <Pressable
    style={[styles.actionButton, disabled && styles.actionButtonDisabled]}
    onPress={onPress}
    disabled={disabled}
  >
    <Text style={styles.actionButtonLabel}>{label}</Text>
  </Pressable>
);

export const PidScreen = () => {
  const { pid, connectedDevice, sendPidValues, refreshPid } = useBleController();
  const [draft, setDraft] = useState<PidGains>(pid ?? DEFAULT_PID);

  useEffect(() => {
    setDraft(pid ?? DEFAULT_PID);
  }, [pid]);

  const updateDraft = (key: keyof PidGains, value: number) => {
    setDraft(prev => ({ ...prev, [key]: value }));
  };

  return (
    <SafeAreaView style={styles.safe}>
      <ScrollView contentContainerStyle={styles.screen}>
        <View style={styles.card}>
          <Text style={styles.title}>PID parameters</Text>
          <Text style={styles.body}>
            Đồng bộ trực tiếp với hàm điều khiển trong pid_control.py. Điều chỉnh nhẹ nhàng và bấm "Gửi" để áp dụng ngay.
          </Text>
          <View style={styles.pidGrid}>
            <PidInputCard
              label="Kp"
              value={draft.kp}
              min={PID_LIMITS.kp.min}
              max={PID_LIMITS.kp.max}
              step={0.5}
              onChange={value => updateDraft('kp', value)}
            />
            <PidInputCard
              label="Ki"
              value={draft.ki}
              min={PID_LIMITS.ki.min}
              max={PID_LIMITS.ki.max}
              step={0.05}
              onChange={value => updateDraft('ki', value)}
            />
            <PidInputCard
              label="Kd"
              value={draft.kd}
              min={PID_LIMITS.kd.min}
              max={PID_LIMITS.kd.max}
              step={0.05}
              onChange={value => updateDraft('kd', value)}
            />
          </View>
          <View style={styles.actionsRow}>
            <ActionButton
              label="Đọc giá trị từ robot"
              onPress={refreshPid}
              disabled={!connectedDevice}
            />
            <ActionButton
              label="Gửi lên robot"
              onPress={() => sendPidValues(draft)}
              disabled={!connectedDevice}
            />
          </View>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: '#e2e8f0',
  },
  screen: {
    padding: 16,
  },
  card: {
    backgroundColor: '#ffffff',
    borderRadius: 24,
    padding: 20,
    gap: 24,
    shadowColor: '#000',
    shadowOpacity: 0.05,
    shadowOffset: { width: 0, height: 8 },
    shadowRadius: 16,
    elevation: 4,
  },
  title: {
    fontSize: 22,
    fontWeight: '700',
    color: '#0f172a',
  },
  body: {
    fontSize: 14,
    color: '#475569',
    lineHeight: 20,
  },
  pidGrid: {
    flexDirection: 'column',
    gap: 16,
  },
  actionsRow: {
    flexDirection: 'row',
    gap: 12,
    flexWrap: 'wrap',
  },
  actionButton: {
    flex: 1,
    backgroundColor: '#0f172a',
    borderRadius: 16,
    paddingVertical: 14,
    alignItems: 'center',
  },
  actionButtonDisabled: {
    backgroundColor: '#94a3b8',
  },
  actionButtonLabel: {
    color: '#f8fafc',
    fontWeight: '700',
    letterSpacing: 0.6,
    textTransform: 'uppercase',
  },
});
