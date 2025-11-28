import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import '../services/bluetooth_manager.dart';
import '../utils/constants.dart';
import '../widgets/vertical_throttle.dart';
import '../widgets/custom_joystick.dart';
import 'calibration_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isStarted = false;
  double _throttleValue = 0.0;
  double _turnValue = 0.0;

  @override
  void initState() {
    super.initState();
    // Force landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  void _sendControlData() {
    if (!_isStarted) return;
    // Format: SPEED:100|TURN:-50\n
    // Throttle: -1.0 to 1.0 -> -100 to 100
    // Turn: -1.0 to 1.0 -> -100 to 100
    int speed = (_throttleValue * 100).toInt();
    int turn = (_turnValue * 100).toInt();
    
    String data = "SPEED:$speed|TURN:$turn\n";
    context.read<BluetoothManager>().sendData(data);
  }

  void _onThrottleChanged(double value) {
    _throttleValue = value;
    _sendControlData();
  }

  void _onJoystickChanged(StickDragDetails details) {
    // details.x is -1 to 1 (Left/Right)
    _turnValue = details.x;
    _sendControlData();
  }

  void _toggleStartStop() {
    setState(() {
      _isStarted = !_isStarted;
    });
    // Send stop command if stopped?
    if (!_isStarted) {
      _throttleValue = 0;
      _turnValue = 0;
      context.read<BluetoothManager>().sendData("STOP\n");
    } else {
      context.read<BluetoothManager>().sendData("START\n");
    }
  }

  void _showBluetoothDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const BluetoothConnectionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Background Elements (Glows)
            Positioned(
              left: -100,
              top: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withOpacity(0.1),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            
            // Main Layout
            Row(
              children: [
                // Left Side: Throttle
                Expanded(
                  flex: 1,
                  child: Center(
                    child: VerticalThrottle(
                      onChanged: _onThrottleChanged,
                    ),
                  ),
                ),
                
                // Center: Controls
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Top Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Bluetooth Button
                          _buildNeumorphicButton(
                            icon: Icons.bluetooth,
                            onTap: _showBluetoothDialog,
                            active: context.watch<BluetoothManager>().isConnected,
                          ),
                          
                          // Start/Stop Toggle
                          GestureDetector(
                            onTap: _toggleStartStop,
                            child: Container(
                              width: 120,
                              height: 50,
                              decoration: AppStyles.neumorphicDecoration(
                                color: _isStarted ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                                borderRadius: 25,
                                pressed: _isStarted,
                              ).copyWith(
                                border: Border.all(
                                  color: _isStarted ? Colors.green : Colors.red,
                                  width: 2,
                                )
                              ),
                              child: Center(
                                child: Text(
                                  _isStarted ? "START" : "STOP",
                                  style: TextStyle(
                                    color: _isStarted ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          // Calibrate Button
                          _buildNeumorphicButton(
                            icon: Icons.settings,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CalibrationScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                      
                      const Spacer(),
                      // Status Text
                      Consumer<BluetoothManager>(
                        builder: (context, manager, child) {
                          return Text(
                            manager.isConnected 
                                ? "Connected: ${manager.connectedDeviceName ?? 'Unknown'}" 
                                : "Disconnected",
                            style: TextStyle(
                              color: manager.isConnected ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                
                // Right Side: Joystick
                Expanded(
                  flex: 1,
                  child: Center(
                    child: CustomJoystick(
                      listener: _onJoystickChanged,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeumorphicButton({required IconData icon, required VoidCallback onTap, bool active = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: AppStyles.neumorphicDecoration(
          color: active ? AppColors.accent : AppColors.surface,
          borderRadius: 15,
        ),
        child: Icon(
          icon,
          color: active ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class BluetoothConnectionSheet extends StatelessWidget {
  const BluetoothConnectionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<BluetoothManager>();

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text("Select Bluetooth Mode", style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  manager.setMode(BluetoothMode.ble);
                  manager.startScan();
                },
                style: ElevatedButton.styleFrom(backgroundColor: manager.mode == BluetoothMode.ble ? AppColors.accent : AppColors.surface),
                child: const Text("BLE"),
              ),
              ElevatedButton(
                onPressed: () {
                  manager.setMode(BluetoothMode.classic);
                  manager.startScan();
                },
                style: ElevatedButton.styleFrom(backgroundColor: manager.mode == BluetoothMode.classic ? AppColors.accent : AppColors.surface),
                child: const Text("Classic"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (manager.connectionState == AppConnectionState.scanning)
            const LinearProgressIndicator(color: AppColors.accent),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: [
                if (manager.mode == BluetoothMode.ble)
                  ...manager.bleScanResults.map((r) => ListTile(
                    title: Text(r.device.platformName.isNotEmpty ? r.device.platformName : "Unknown Device", style: const TextStyle(color: AppColors.textPrimary)),
                    subtitle: Text(r.device.remoteId.toString(), style: const TextStyle(color: AppColors.textSecondary)),
                    onTap: () => manager.connectBLE(r.device),
                  )),
                if (manager.mode == BluetoothMode.classic)
                  ...manager.classicScanResults.map((r) => ListTile(
                    title: Text(r.device.name ?? "Unknown Device", style: const TextStyle(color: AppColors.textPrimary)),
                    subtitle: Text(r.device.address, style: const TextStyle(color: AppColors.textSecondary)),
                    onTap: () => manager.connectClassic(r.device),
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
