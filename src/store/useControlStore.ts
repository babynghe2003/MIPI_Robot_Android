import { create } from 'zustand';
import type { Device } from 'react-native-ble-plx';
import type { ControlCommand, PidGains } from '../types/control';
import { DEFAULT_PID } from '../constants/ble';

interface ControlState {
  availableDevices: Device[];
  connectedDevice: Device | null;
  isScanning: boolean;
  activeCommand: ControlCommand | null;
  pid: PidGains;
  setAvailableDevices: (devices: Device[]) => void;
  upsertDevice: (device: Device) => void;
  setConnectedDevice: (device: Device | null) => void;
  setScanning: (next: boolean) => void;
  setActiveCommand: (command: ControlCommand | null) => void;
  setPid: (pid: PidGains) => void;
  reset: () => void;
}

export const useControlStore = create<ControlState>(set => ({
  availableDevices: [],
  connectedDevice: null,
  isScanning: false,
  activeCommand: null,
  pid: DEFAULT_PID,
  setAvailableDevices: devices => set({ availableDevices: devices }),
  upsertDevice: device =>
    set(state => {
      const exists = state.availableDevices.some(d => d.id === device.id);
      return exists
        ? state
        : { availableDevices: [...state.availableDevices, device] };
    }),
  setConnectedDevice: device => set({ connectedDevice: device }),
  setScanning: next => set({ isScanning: next }),
  setActiveCommand: command => set({ activeCommand: command }),
  setPid: pid => set({ pid }),
  reset: () =>
    set({
      availableDevices: [],
      connectedDevice: null,
      isScanning: false,
      activeCommand: null,
      pid: DEFAULT_PID,
    }),
}));
