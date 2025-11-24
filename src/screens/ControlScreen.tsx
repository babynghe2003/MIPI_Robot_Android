import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { ControlButton } from '../components/ControlButton';
import { DeviceList } from '../components/DeviceList';
import { StatusPill } from '../components/StatusPill';
import { useBleController } from '../hooks/useBleController';
import { useControlStore } from '../store/useControlStore';

export const ControlScreen = () => {
  const {
    availableDevices,
    connectedDevice,
    isScanning,
    isPairing,
    startScan,
    connectToDevice,
    disconnect,
    sendDirectionalCommand,
    stopMotion,
  } = useBleController();
  const activeCommand = useControlStore(state => state.activeCommand);

  const statusLabel = connectedDevice
    ? `Đang điều khiển ${connectedDevice.name ?? connectedDevice.id}`
    : isScanning
    ? 'Đang quét thiết bị...'
    : 'Chưa kết nối robot';
  const statusState: 'connected' | 'disconnected' | 'scanning' = connectedDevice
    ? 'connected'
    : isScanning
    ? 'scanning'
    : 'disconnected';

  return (
    <SafeAreaView style={styles.safe}>
      <ScrollView contentContainerStyle={styles.screen}>
        <View style={styles.card}>
          <View style={styles.cardHeader}>
            <Text style={styles.title}>Kết nối & ghép nối</Text>
            <StatusPill label={statusLabel} status={statusState} />
          </View>
          <View style={styles.actionsRow}>
            <View style={styles.infoColumn}>
              <Text style={styles.subtitle}>Quét & kết nối tự động</Text>
              <Text style={styles.body}>
                Hệ thống tự lọc các thiết bị bắt đầu bằng "MIPIRobot" để đảm bảo đúng robot.
              </Text>
            </View>
            <View style={styles.primaryButtons}>
              <Pressable style={styles.primaryButton} onPress={startScan}>
                <Text style={styles.primaryButtonLabel}>
                  {isScanning ? 'Đang quét...' : 'Quét & ghép nối'}
                </Text>
              </Pressable>
              <Pressable
                style={[styles.primaryButton, !connectedDevice && !isPairing && styles.primaryButtonDisabled]}
                onPress={() =>
                  connectedDevice ? disconnect() : connectToDevice(availableDevices[0])
                }
              >
                <Text style={styles.primaryButtonLabel}>
                  {connectedDevice ? 'Ngắt kết nối' : isPairing ? 'Đang ghép nối' : 'Kết nối nhanh'}
                </Text>
              </Pressable>
            </View>
          </View>
          <DeviceList
            devices={availableDevices}
            onConnect={device => connectToDevice(device)}
            selectedDeviceId={connectedDevice?.id}
          />
        </View>

        <View style={styles.card}>
          <View style={styles.cardHeader}>
            <Text style={styles.title}>Điều khiển chuyển động</Text>
            <Text style={styles.body}>Nhấn giữ để duy trì chuyển động, thả để dừng.</Text>
          </View>
          <View style={styles.dpad}>
            <ControlButton
              label="Tiến"
              command="forward"
              onPressIn={sendDirectionalCommand}
              onPressOut={stopMotion}
              isActive={activeCommand === 'forward'}
            />
            <View style={styles.middleRow}>
              <ControlButton
                label="Trái"
                command="left"
                onPressIn={sendDirectionalCommand}
                onPressOut={stopMotion}
                isActive={activeCommand === 'left'}
              />
              <ControlButton
                label="Dừng"
                command="stop"
                onPressIn={() => {
                  stopMotion();
                }}
                onPressOut={() => undefined}
                isActive={activeCommand === null}
              />
              <ControlButton
                label="Phải"
                command="right"
                onPressIn={sendDirectionalCommand}
                onPressOut={stopMotion}
                isActive={activeCommand === 'right'}
              />
            </View>
            <ControlButton
              label="Lùi"
              command="backward"
              onPressIn={sendDirectionalCommand}
              onPressOut={stopMotion}
              isActive={activeCommand === 'backward'}
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
    gap: 16,
  },
  card: {
    backgroundColor: '#ffffff',
    borderRadius: 24,
    padding: 20,
    gap: 18,
    shadowColor: '#000',
    shadowOpacity: 0.05,
    shadowOffset: { width: 0, height: 8 },
    shadowRadius: 16,
    elevation: 4,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    gap: 12,
  },
  title: {
    fontSize: 20,
    fontWeight: '700',
    color: '#0f172a',
    flex: 1,
  },
  subtitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#0f172a',
    marginBottom: 4,
  },
  body: {
    color: '#475569',
    fontSize: 14,
    lineHeight: 20,
  },
  actionsRow: {
    flexDirection: 'row',
    gap: 16,
    alignItems: 'center',
  },
  primaryButtons: {
    gap: 12,
  },
  primaryButton: {
    backgroundColor: '#0f172a',
    paddingVertical: 12,
    paddingHorizontal: 18,
    borderRadius: 16,
  },
  primaryButtonDisabled: {
    backgroundColor: '#94a3b8',
  },
  primaryButtonLabel: {
    color: '#f8fafc',
    fontWeight: '600',
    letterSpacing: 0.5,
  },
  dpad: {
    gap: 12,
    alignItems: 'center',
  },
  middleRow: {
    flexDirection: 'row',
    gap: 12,
    alignItems: 'center',
  },
  infoColumn: {
    flex: 1,
  },
});
