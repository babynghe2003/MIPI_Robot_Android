import { memo } from 'react';
import { Pressable, StyleSheet, Text, TextInput, View } from 'react-native';

interface PidInputCardProps {
  label: string;
  value: number;
  min: number;
  max: number;
  step?: number;
  onChange: (value: number) => void;
}

export const PidInputCard = memo<PidInputCardProps>(({ label, value, min, max, step = 0.1, onChange }) => {
  const handleStep = (direction: -1 | 1) => {
    const next = Math.min(Math.max(value + direction * step, min), max);
    onChange(Number(next.toFixed(3)));
  };

  return (
    <View style={styles.card}>
      <Text style={styles.label}>{label}</Text>
      <View style={styles.inputRow}>
        <Pressable style={styles.stepper} onPress={() => handleStep(-1)}>
          <Text style={styles.stepperText}>-</Text>
        </Pressable>
        <TextInput
          style={styles.input}
          keyboardType="numeric"
          value={String(value)}
          onChangeText={text => {
            const parsed = Number(text);
            if (!Number.isNaN(parsed)) {
              const clamped = Math.min(Math.max(parsed, min), max);
              onChange(clamped);
            }
          }}
        />
        <Pressable style={styles.stepper} onPress={() => handleStep(1)}>
          <Text style={styles.stepperText}>+</Text>
        </Pressable>
      </View>
      <Text style={styles.range}>{`${min} → ${max}`}</Text>
    </View>
  );
});

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#fff',
    borderRadius: 18,
    padding: 16,
    shadowColor: '#000',
    shadowOpacity: 0.08,
    shadowRadius: 12,
    shadowOffset: { width: 0, height: 6 },
    elevation: 4,
    gap: 12,
    flex: 1,
  },
  label: {
    fontSize: 16,
    fontWeight: '700',
    color: '#0f172a',
  },
  inputRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  input: {
    flex: 1,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: '#e2e8f0',
    paddingVertical: 10,
    paddingHorizontal: 16,
    fontSize: 18,
    textAlign: 'center',
    color: '#111827',
  },
  stepper: {
    width: 42,
    height: 42,
    borderRadius: 14,
    backgroundColor: '#0f172a',
    alignItems: 'center',
    justifyContent: 'center',
  },
  stepperText: {
    color: '#f8fafc',
    fontWeight: '800',
    fontSize: 20,
  },
  range: {
    color: '#94a3b8',
    fontSize: 12,
    fontWeight: '600',
  },
});
