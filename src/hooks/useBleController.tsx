import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react';
import type { PropsWithChildren } from 'react';
import { Alert, PermissionsAndroid, Platform } from 'react-native';
import { BleManager, Device } from 'react-native-ble-plx';
import { Buffer } from 'buffer';
import {
  BLE_SCAN_TIMEOUT_MS,
  COMMAND_PAYLOADS,
  PID_LIMITS,
  ROBOT_COMMAND_CHARACTERISTIC_UUID,
  ROBOT_DEVICE_NAME_PREFIX,
  ROBOT_PID_CHARACTERISTIC_UUID,
  ROBOT_SERVICE_UUID,
} from '../constants/ble';
import type { ControlCommand, PidGains } from '../types/control';
import { useControlStore } from '../store/useControlStore';

const bleManager = new BleManager();

const encodePayload = (text: string) => Buffer.from(text, 'utf-8').toString('base64');

const clampPid = (pid: PidGains): PidGains => ({
  kp: Math.min(Math.max(pid.kp, PID_LIMITS.kp.min), PID_LIMITS.kp.max),
  ki: Math.min(Math.max(pid.ki, PID_LIMITS.ki.min), PID_LIMITS.ki.max),
  kd: Math.min(Math.max(pid.kd, PID_LIMITS.kd.min), PID_LIMITS.kd.max),
});

const useBleControllerImpl = () => {
  const availableDevices = useControlStore(state => state.availableDevices);
  const connectedDevice = useControlStore(state => state.connectedDevice);
  const isScanning = useControlStore(state => state.isScanning);
  const pid = useControlStore(state => state.pid);
  const upsertDevice = useControlStore(state => state.upsertDevice);
  const setAvailableDevices = useControlStore(state => state.setAvailableDevices);
  const setConnectedDevice = useControlStore(state => state.setConnectedDevice);
  const setScanning = useControlStore(state => state.setScanning);
  const setActiveCommand = useControlStore(state => state.setActiveCommand);
  const setPid = useControlStore(state => state.setPid);
  const [permissionsGranted, setPermissionsGranted] = useState(false);
  const [isPairing, setIsPairing] = useState(false);
  const [isWriting, setIsWriting] = useState(false);
  const scanTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    requestPermissions().catch(() => undefined);

    return () => {
      bleManager.stopDeviceScan();
    };
  }, []);

  const requestPermissions = useCallback(async () => {
    if (Platform.OS !== 'android') {
      setPermissionsGranted(true);
      return;
    }

    if (Platform.Version >= 31) {
      const result = await PermissionsAndroid.requestMultiple([
        PermissionsAndroid.PERMISSIONS.BLUETOOTH_SCAN,
        PermissionsAndroid.PERMISSIONS.BLUETOOTH_CONNECT,
        PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION,
      ]);
      const granted = Object.values(result).every(status => status === PermissionsAndroid.RESULTS.GRANTED);
      setPermissionsGranted(granted);
      if (!granted) {
        Alert.alert('Bluetooth permissions required', 'Please grant Bluetooth permissions to control the robot.');
      }
    } else {
      const fineLocation = await PermissionsAndroid.request(
        PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION,
      );
      setPermissionsGranted(fineLocation === PermissionsAndroid.RESULTS.GRANTED);
    }
  }, []);

  const stopScan = useCallback(() => {
    bleManager.stopDeviceScan();
    setScanning(false);
    if (scanTimer.current) {
      clearTimeout(scanTimer.current);
      scanTimer.current = null;
    }
  }, [setScanning]);

  const startScan = useCallback(async () => {
    if (!permissionsGranted) {
      await requestPermissions();
    }
    setAvailableDevices([]);
    setScanning(true);

    bleManager.startDeviceScan([ROBOT_SERVICE_UUID], null, (error, device) => {
      if (error) {
        stopScan();
        Alert.alert('Scan error', error.message);
        return;
      }
      if (!device) {
        return;
      }
      if (device.name?.startsWith(ROBOT_DEVICE_NAME_PREFIX)) {
        upsertDevice(device);
      }
    });

    scanTimer.current = setTimeout(() => {
      stopScan();
    }, BLE_SCAN_TIMEOUT_MS);
  }, [permissionsGranted, requestPermissions, setAvailableDevices, setScanning, stopScan, upsertDevice]);

  const connectToDevice = useCallback(
    async (device?: Device) => {
      const target = device ?? availableDevices[0];
      if (!target) {
        Alert.alert('No devices', 'Start scanning to discover the robot.');
        return;
      }
      setIsPairing(true);
      try {
        stopScan();
        const connected = await bleManager.connectToDevice(target.id, { autoConnect: true });
        const withServices = await connected.discoverAllServicesAndCharacteristics();
        setConnectedDevice(withServices);
        bleManager.onDeviceDisconnected(withServices.id, () => {
          setConnectedDevice(null);
          setActiveCommand(null);
        });
      } catch (error) {
        Alert.alert('Connection failed', (error as Error).message);
      } finally {
        setIsPairing(false);
      }
    },
    [availableDevices, setActiveCommand, setConnectedDevice, stopScan],
  );

  const disconnect = useCallback(async () => {
    if (!connectedDevice) {
      return;
    }
    try {
      await bleManager.cancelDeviceConnection(connectedDevice.id);
      setConnectedDevice(null);
      setActiveCommand(null);
    } catch (error) {
      Alert.alert('Disconnect failed', (error as Error).message);
    }
  }, [connectedDevice, setActiveCommand, setConnectedDevice]);

  const writeCommand = useCallback(
    async (payload: string) => {
      if (!connectedDevice) {
        Alert.alert('No device', 'Connect to the robot before sending commands.');
        return;
      }
      setIsWriting(true);
      try {
        await connectedDevice.writeCharacteristicWithResponseForService(
          ROBOT_SERVICE_UUID,
          ROBOT_COMMAND_CHARACTERISTIC_UUID,
          encodePayload(payload),
        );
      } catch (error) {
        Alert.alert('Command failed', (error as Error).message);
      } finally {
        setIsWriting(false);
      }
    },
    [connectedDevice],
  );

  const sendDirectionalCommand = useCallback(
    async (command: ControlCommand) => {
      setActiveCommand(command);
      await writeCommand(COMMAND_PAYLOADS[command]);
    },
    [setActiveCommand, writeCommand],
  );

  const stopMotion = useCallback(async () => {
    setActiveCommand(null);
    await writeCommand(COMMAND_PAYLOADS.stop);
  }, [setActiveCommand, writeCommand]);

  const sendPidValues = useCallback(
    async (nextPid: PidGains) => {
      if (!connectedDevice) {
        Alert.alert('No device', 'Connect to the robot before tuning PID values.');
        return;
      }
      const clamped = clampPid(nextPid);
      setPid(clamped);
      try {
        await connectedDevice.writeCharacteristicWithResponseForService(
          ROBOT_SERVICE_UUID,
          ROBOT_PID_CHARACTERISTIC_UUID,
          encodePayload(JSON.stringify(clamped)),
        );
      } catch (error) {
        Alert.alert('PID update failed', (error as Error).message);
      }
    },
    [connectedDevice, setPid],
  );

  const refreshPid = useCallback(async () => {
    if (!connectedDevice) {
      return;
    }
    try {
      const characteristic = await connectedDevice.readCharacteristicForService(
        ROBOT_SERVICE_UUID,
        ROBOT_PID_CHARACTERISTIC_UUID,
      );
      if (characteristic?.value) {
        const decoded = Buffer.from(characteristic.value, 'base64').toString('utf-8');
        const parsed = JSON.parse(decoded) as PidGains;
        setPid(clampPid(parsed));
      }
    } catch (error) {
      // Silent read failure is acceptable during startup
    }
  }, [connectedDevice, setPid]);

  const status = useMemo(
    () => ({
      availableDevices,
      connectedDevice,
      isScanning,
      permissionsGranted,
      isPairing,
      isWriting,
      pid,
    }),
    [availableDevices, connectedDevice, isPairing, isScanning, isWriting, permissionsGranted, pid],
  );

  return {
    ...status,
    startScan,
    stopScan,
    connectToDevice,
    disconnect,
    sendDirectionalCommand,
    stopMotion,
    sendPidValues,
    refreshPid,
  };
};

type BleControllerValue = ReturnType<typeof useBleControllerImpl>;

const BleControllerContext = createContext<BleControllerValue | null>(null);

export const BleControllerProvider = ({ children }: PropsWithChildren) => {
  const value = useBleControllerImpl();
  return <BleControllerContext.Provider value={value}>{children}</BleControllerContext.Provider>;
};

export const useBleController = () => {
  const ctx = useContext(BleControllerContext);
  if (!ctx) {
    throw new Error('useBleController must be used inside BleControllerProvider');
  }
  return ctx;
};
