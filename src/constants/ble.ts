export const ROBOT_SERVICE_UUID = '12345678-1234-5678-1234-56789abcdef0';
export const ROBOT_COMMAND_CHARACTERISTIC_UUID = '12345678-1234-5678-1234-56789abcdef1';
export const ROBOT_PID_CHARACTERISTIC_UUID = '12345678-1234-5678-1234-56789abcdef2';
export const ROBOT_DEVICE_NAME_PREFIX = 'MIPIRobot';
export const BLE_SCAN_TIMEOUT_MS = 15000;

export const COMMAND_PAYLOADS = {
  forward: 'COMMAND_FORWARD',
  backward: 'COMMAND_BACKWARD',
  left: 'COMMAND_LEFT',
  right: 'COMMAND_RIGHT',
  stop: 'COMMAND_STOP',
};

export const PID_LIMITS = {
  kp: { min: 0, max: 40 },
  ki: { min: 0, max: 5 },
  kd: { min: 0, max: 5 },
};

export const DEFAULT_PID = {
  kp: 12,
  ki: 0.8,
  kd: 0.15,
};
