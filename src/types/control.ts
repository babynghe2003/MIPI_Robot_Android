export type ControlCommand = 'forward' | 'backward' | 'left' | 'right' | 'stop';

export interface PidGains {
  kp: number;
  ki: number;
  kd: number;
}
