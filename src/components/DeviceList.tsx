import { memo } from 'react';
import { FlatList, Pressable, StyleSheet, Text, View } from 'react-native';
import type { Device } from 'react-native-ble-plx';

interface DeviceListProps {
  devices: Device[];
  onConnect: (device: Device) => void;
  selectedDeviceId?: string;
}

export const DeviceList = memo<DeviceListProps>(({ devices, onConnect, selectedDeviceId }) => {
  if (!devices.length) {
    return (
      <View style={styles.emptyState}>
        <Text style={styles.emptyTitle}>Chưa tìm thấy robot</Text>
        <Text style={styles.emptySubtitle}>Bấm "Quét & ghép nối" để bắt đầu.</Text>
      </View>
    );
  }

  return (
    <FlatList
      data={devices}
      keyExtractor={item => item.id}
      horizontal
      showsHorizontalScrollIndicator={false}
      contentContainerStyle={styles.listContent}
      renderItem={({ item }) => {
        const isSelected = selectedDeviceId === item.id;
        return (
          <Pressable
            onPress={() => onConnect(item)}
            style={[styles.card, isSelected && styles.cardSelected]}
          >
            <Text style={styles.deviceName}>{item.name ?? 'Robot vô danh'}</Text>
            <Text style={styles.deviceId}>{item.id}</Text>
            <Text style={styles.deviceAction}>{isSelected ? 'Đang kết nối' : 'Chạm để kết nối'}</Text>
          </Pressable>
        );
      }}
    />
  );
});

const styles = StyleSheet.create({
  listContent: {
    gap: 12,
    paddingVertical: 4,
  },
  card: {
    backgroundColor: '#0f172a',
    padding: 16,
    borderRadius: 18,
    width: 260,
    gap: 8,
  },
  cardSelected: {
    borderColor: '#38bdf8',
    borderWidth: 1.5,
  },
  deviceName: {
    color: '#f8fafc',
    fontSize: 18,
    fontWeight: '700',
  },
  deviceId: {
    color: '#94a3b8',
    fontSize: 12,
  },
  deviceAction: {
    color: '#38bdf8',
    fontWeight: '600',
  },
  emptyState: {
    padding: 24,
    borderRadius: 18,
    backgroundColor: '#f8fafc',
    borderWidth: 1,
    borderColor: '#e2e8f0',
    alignItems: 'center',
    gap: 6,
  },
  emptyTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#0f172a',
  },
  emptySubtitle: {
    fontSize: 14,
    color: '#475569',
  },
});
