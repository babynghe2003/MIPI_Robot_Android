## Android Controller App

Modern React Native companion app that mirrors the robot's voice/gamepad command set. It discovers the ESP32-S3 robot over BLE, streams movement commands (press-and-hold to move, release to stop), and exposes a dedicated PID tuning workspace that mirrors the controls found in `pid_control.py`.

### Feature Overview

- **One-tap pairing** – filters BLE advertisements to devices whose name starts with `MIPIRobot`, handles Android 12+ Bluetooth permissions, and shows active scan status chips.
- **Gamepad-grade driving** – forward/back/left/right pads support press-and-hold gestures, instantly issuing `COMMAND_*` opcodes over BLE and cancelling on release.
- **PID tuning console** – dedicated screen with steppers/text inputs for Kp/Ki/Kd, live read-back from the robot, and safe min/max clamps.
- **Stateful design** – shared BLE controller provider backed by `react-native-ble-plx` + Zustand store so both screens stay in sync.
- **Production-ready UX** – safe-area aware layout, dark-on-light palette, gesture-handler integration, and bottom-tab navigation for quick switching.

### BLE Contract

| Purpose | UUID |
| --- | --- |
| Custom control service | `12345678-1234-5678-1234-56789abcdef0` |
| Movement characteristic | `12345678-1234-5678-1234-56789abcdef1` |
| PID gains characteristic | `12345678-1234-5678-1234-56789abcdef2` |

Payloads are UTF-8 strings that are base64-encoded before writing. Movement commands use the tokens defined in `src/constants/ble.ts` (e.g., `COMMAND_FORWARD`, `COMMAND_STOP`). PID updates are JSON objects: `{ "kp": number, "ki": number, "kd": number }`.

### Project Structure

```
android_controller_app
├── App.tsx                # Providers + navigation shell
├── src
│   ├── components         # Reusable UI (buttons, PID cards, status pills)
│   ├── constants          # BLE UUIDs, PID defaults, command map
│   ├── hooks              # BLE controller provider built on react-native-ble-plx
│   ├── navigation         # Bottom-tab navigator
│   ├── screens            # Control and PID tuning screens
│   └── store              # Zustand store for shared state
```

### Prerequisites

- React Native environment set up for Android (`adb`, Java 17+, Android SDK). Follow the official [environment setup guide](https://reactnative.dev/docs/set-up-your-environment) if needed.
- Robot firmware implementing the BLE service/characteristics above.
- Android 12+ device (for BLE permissions flow) or emulator with BLE support.

### Install & Run

```sh
cd android_controller_app
npm install

# Start Metro bundler
npm start

# In a second terminal, launch the Android build
npm run android
```

### Using the App

1. Open the **Điều khiển** tab and tap **Quét & ghép nối**. The app requests SCAN/CONNECT permissions automatically on Android 12+.
2. Choose your robot from the carousel (device names must start with `MIPIRobot`) or tap **Kết nối nhanh** to connect to the first match.
3. Hold the directional pads to move the robot; releasing the button immediately publishes `COMMAND_STOP`.
4. Switch to **PID Tuning** to adjust gains. Use the `+/-` steppers or type the value, then press **Gửi lên robot**. Tap **Đọc giá trị** to fetch the current gains from the robot.

### Android-specific Notes

- `AndroidManifest.xml` already declares all required Bluetooth + location permissions for API 31+.
- `react-native-reanimated` and `react-native-gesture-handler` are configured in `babel.config.js` and `index.js`.
- Buffer polyfill is installed and registered inside `App.tsx` so BLE payloads can be encoded/decoded on-device without extra dependencies.

### Troubleshooting

- **No devices in the list**: Ensure the robot advertises the custom service UUID and its name begins with `MIPIRobot`. Pull-to-refresh or tap **Quét & ghép nối** again to restart scanning.
- **Cannot connect**: Verify the robot exposes the control/ PID characteristics with write permissions. BLE pairing fails if another phone is already connected.
- **PID not updating**: Confirm the firmware echoes back the JSON payload through the PID characteristic; the app logs an alert if the write fails.

### Next Steps

- Add telemetry (battery, IMU readings) via additional BLE characteristics and display them in the control screen.
- Hook the pairing flow into Android's system pairing dialog if the robot requires bonding.
- Localize static copy (`vi`, `en`) using a translation library if needed.
