# MIPIRobot BLE API Documentation

This document outlines the Bluetooth Low Energy (BLE) interface for the MIPIRobot. The robot acts as a BLE Peripheral (Server), and the Android Gamepad App acts as the Central (Client).

## Connection Details

- **Device Name**: `MIPIRobot`
- **Service UUID**: `000000FF-0000-1000-8000-00805F9B34FB` (16-bit: `0x00FF`)

All characteristics belong to the primary service `0x00FF`.

## Characteristics

### PID Control Parameters
Used to tune the PID controllers on the robot.

| Characteristic | UUID (16-bit) | Properties | Data Type | Description |
| :--- | :--- | :--- | :--- | :--- |
| **PID 1** | `0xFF01` | Read, Write | `float[3]` | PID parameters for Controller 1. Bytes: `[Kp, Ki, Kd]` |
| **PID 2** | `0xFF02` | Read, Write | `float[3]` | PID parameters for Controller 2. Bytes: `[Kp, Ki, Kd]` |
| **PID 3** | `0xFF03` | Read, Write | `float[3]` | PID parameters for Controller 3. Bytes: `[Kp, Ki, Kd]` |
| **PID 4** | `0xFF04` | Read, Write | `float[3]` | PID parameters for Controller 4. Bytes: `[Kp, Ki, Kd]` |

**Data Format (`float[3]`)**:
- 12 bytes total.
- 3 x 32-bit IEEE 754 floating point numbers.
- Little-endian byte order.
- Structure: `struct { float kp; float ki; float kd; }`

---

### Movement & State
Control the robot's movement and read its current state.

| Characteristic | UUID (16-bit) | Properties | Data Type | Description |
| :--- | :--- | :--- | :--- | :--- |
| **Velocity** | `0xFF05` | Read, Write | `float` | Target velocity. |
| **Yaw Angle** | `0xFF06` | Read, Write | `float` | Target yaw angle. |
| **Pitch Axis** | `0xFF07` | Read | `float` | Current pitch angle (telemetry). |
| **Pitch Offset** | `0xFF08` | Read, Write | `float` | Calibration offset for pitch. |

**Data Format (`float`)**:
- 4 bytes.
- 32-bit IEEE 754 floating point number.
- Little-endian.

---

### Height Control
Control the height of the robot and individual legs.

| Characteristic | UUID (16-bit) | Properties | Data Type | Description |
| :--- | :--- | :--- | :--- | :--- |
| **Robot Height** | `0xFF09` | Read, Write | `float` | Target overall robot height. |
| **Left Leg** | `0xFF0A` | Read, Write | `float` | Target height/position for left leg. |
| **Right Leg** | `0xFF0B` | Read, Write | `float` | Target height/position for right leg. |

---

### System Status & Actions

| Characteristic | UUID (16-bit) | Properties | Data Type | Description |
| :--- | :--- | :--- | :--- | :--- |
| **Fallen Status** | `0xFF0C` | Read, Notify | `uint8_t` | 1 if robot has fallen, 0 otherwise. Subscribing enables notifications. |
| **Action** | `0xFF0D` | Write | `uint8_t` | Send commands to the robot. |

**Action Codes (`uint8_t`)**:
- `0`: **Stop** - Disable motors/control.
- `1`: **Start** - Enable motors/control.
- `2`: **Dance** - Trigger dance sequence.

## Example Data Packets

### Writing PID
To set Kp=1.5, Ki=0.0, Kd=0.5 for PID 1 (`0xFF01`):
- `Kp` (1.5) = `0x3FC00000` -> Little Endian: `00 00 C0 3F`
- `Ki` (0.0) = `0x00000000` -> Little Endian: `00 00 00 00`
- `Kd` (0.5) = `0x3F000000` -> Little Endian: `00 00 00 3F`
- **Payload**: `00 00 C0 3F 00 00 00 00 00 00 00 3F`

### Writing Action
To start the robot (`0xFF0D`):
- **Payload**: `01`
