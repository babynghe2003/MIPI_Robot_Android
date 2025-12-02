import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_manager.dart';
import '../utils/constants.dart';
import '../widgets/vertical_throttle.dart';
import '../widgets/horizontal_throttle.dart';
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
  
  // Analog joystick values (for future use)
  double _leftJoystickX = 0.0;
  double _leftJoystickY = 0.0;
  double _rightJoystickX = 0.0;
  double _rightJoystickY = 0.0;
  
  // Robot action states
  bool _voiceCommandEnabled = false;
  bool _isStanding = true;

  late final _RateLimitedSender _velocitySender;
  late final _RateLimitedSender _yawSender;
  late final _RateLimitedSender _leftLegSender;
  late final _RateLimitedSender _rightLegSender;

  @override
  void initState() {
    super.initState();
    _velocitySender = _RateLimitedSender(onSend: _sendVelocity);
    _yawSender = _RateLimitedSender(onSend: _sendYaw);
    _leftLegSender = _RateLimitedSender(onSend: _sendLeftLegHeight);
    _rightLegSender = _RateLimitedSender(onSend: _sendRightLegHeight);
    // Force landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Hide system UI for fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _velocitySender.dispose();
    _yawSender.dispose();
    _leftLegSender.dispose();
    _rightLegSender.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onThrottleChanged(double value) {
    _throttleValue = value;
    _velocitySender.update(value);
  }

  void _onTurnChanged(double value) {
    _turnValue = value;
    _yawSender.update(value);
  }

  void _onLeftJoystickChanged(StickDragDetails details) {
    _leftJoystickX = details.x;
    _leftJoystickY = details.y;
    _leftLegSender.update(_joystickToLegHeight(_leftJoystickY));
  }

  void _onRightJoystickChanged(StickDragDetails details) {
    _rightJoystickX = details.x;
    _rightJoystickY = details.y;
    _rightLegSender.update(_joystickToLegHeight(_rightJoystickY));
  }

  double _joystickToLegHeight(double value) {
    final percent = ((-value + 1) / 2) * 100;
    return percent.clamp(0.0, 100.0);
  }

  void _sendLegacyControlData(BluetoothManager manager) {
    if (!_isStarted) return;
    final speed = (_throttleValue * 100).toInt();
    final turn = (_turnValue * 100).toInt();
    final lx = (_leftJoystickX * 100).toInt();
    final ly = (_leftJoystickY * 100).toInt();
    final rx = (_rightJoystickX * 100).toInt();
    final ry = (_rightJoystickY * 100).toInt();
    final data = "SPEED:$speed|TURN:$turn|LX:$lx|LY:$ly|RX:$rx|RY:$ry\n";
    manager.sendData(data);
  }

  void _sendVelocity(double value) {
    if (!mounted) return;
    final manager = context.read<BluetoothManager>();
    manager.updateVelocity(value);
    if (manager.mode != BluetoothMode.ble) {
      _sendLegacyControlData(manager);
    }
  }

  void _sendYaw(double value) {
    if (!mounted) return;
    final manager = context.read<BluetoothManager>();
    manager.updateYaw(value);
    if (manager.mode != BluetoothMode.ble) {
      _sendLegacyControlData(manager);
    }
  }

  void _sendLeftLegHeight(double value) {
    if (!mounted) return;
    final manager = context.read<BluetoothManager>();
    if (manager.mode == BluetoothMode.ble) {
      manager.updateLeftLegHeight(value);
    } else {
      _sendLegacyControlData(manager);
    }
  }

  void _sendRightLegHeight(double value) {
    if (!mounted) return;
    final manager = context.read<BluetoothManager>();
    if (manager.mode == BluetoothMode.ble) {
      manager.updateRightLegHeight(value);
    } else {
      _sendLegacyControlData(manager);
    }
  }

  void _toggleStartStop() {
    final manager = context.read<BluetoothManager>();
    setState(() {
      _isStarted = !_isStarted;
    });

    if (_isStarted) {
      manager.sendActionCommand(RobotActionCodes.start);
      if (manager.mode != BluetoothMode.ble) {
        manager.sendData("START\n");
        _sendLegacyControlData(manager);
      } else {
        _velocitySender.forceSend(_throttleValue);
        _yawSender.forceSend(_turnValue);
        _leftLegSender.forceSend(_joystickToLegHeight(_leftJoystickY));
        _rightLegSender.forceSend(_joystickToLegHeight(_rightJoystickY));
      }
    } else {
      _throttleValue = 0;
      _turnValue = 0;
      _leftJoystickX = 0;
      _leftJoystickY = 0;
      _rightJoystickX = 0;
      _rightJoystickY = 0;
      manager.sendActionCommand(RobotActionCodes.stop);
      if (manager.mode != BluetoothMode.ble) {
        manager.sendData("STOP\n");
      } else {
        _velocitySender.forceSend(0);
        _yawSender.forceSend(0);
        final resetHeight = _joystickToLegHeight(0);
        _leftLegSender.forceSend(resetHeight);
        _rightLegSender.forceSend(resetHeight);
      }
    }
  }

  void _showBluetoothDialog() {
    showDialog(
      context: context,
      builder: (context) => const BluetoothConnectionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // Joystick dimensions
    const joystickBaseSize = 150.0;
    const joystickStickSize = 80.0;
    const joystickTotalSize = joystickBaseSize + joystickStickSize; // 230
    
    // Throttle dimensions
    const verticalThrottleHeight = 280.0;
    const horizontalThrottleWidth = 200.0;
    
    // Positions - joysticks centered at bottom, can overlap with throttles
    final joystickY = screenHeight - joystickTotalSize - 10; // 20px from bottom
    final leftJoystickX = screenWidth * 0.3 - joystickTotalSize / 2;
    final rightJoystickX = screenWidth * 0.7 - joystickTotalSize / 2;
    
    // Vertical throttle on left side
    const verticalThrottleX = 50.0;
    final verticalThrottleY = (screenHeight - verticalThrottleHeight) / 2 - 30;
    
    // Horizontal throttle on right side
    final horizontalThrottleX = screenWidth - horizontalThrottleWidth - 30;
    final horizontalThrottleY = (screenHeight - 100) / 2 - 30; // 100 is throttle height
    
    // Center controls position
    final controlsY = screenHeight * 0.1;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        children: [
          // Background Glow Effects
          Positioned(
            left: -250,
            top: -250,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withOpacity(0.08),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
              right: -100,
              bottom: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withOpacity(0.08),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            
            // Vertical Throttle (Left Side)
            Positioned(
              left: verticalThrottleX,
              top: verticalThrottleY,
              child: SizedBox(
                height: verticalThrottleHeight,
                child: VerticalThrottle(
                  onChanged: _onThrottleChanged,
                ),
              ),
            ),
            
            // Horizontal Throttle (Right Side)
            Positioned(
              left: horizontalThrottleX,
              top: horizontalThrottleY,
              child: SizedBox(
                width: horizontalThrottleWidth,
                child: HorizontalThrottle(
                  onChanged: _onTurnChanged,
                ),
              ),
            ),
            
            // Center Controls and Status Text (aligned in column)
            Positioned(
              left: 0,
              right: 0,
              top: controlsY,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Controls Row (Bluetooth, Start/Stop, Settings)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bluetooth Button with glow status
                      _buildBluetoothButton(),
                      const SizedBox(width: 20),
                      
                      // Start/Stop Toggle
                      GestureDetector(
                        onTap: _toggleStartStop,
                        child: Container(
                          width: 140,
                          height: 50,
                          decoration: AppStyles.neumorphicDecoration(
                            color: _isStarted ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                            borderRadius: 25,
                            pressed: _isStarted,
                          ).copyWith(
                            border: Border.all(
                              color: _isStarted ? Colors.green : Colors.red,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_isStarted ? Colors.green : Colors.red).withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isStarted ? Icons.play_arrow : Icons.stop,
                                  color: _isStarted ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isStarted ? "RUNNING" : "STOPPED",
                                  style: TextStyle(
                                    color: _isStarted ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      
                      // Settings Button
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
                  
                  const SizedBox(height: 50),
                  
                  // Action Buttons (Inverted Triangle)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top row - 2 buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Jump Button
                          _buildActionButton(
                            icon: Icons.arrow_upward,
                            color: Colors.orange,
                            onTap: _onJumpPressed,
                          ),
                          const SizedBox(width: 16),
                          // Voice Command Toggle
                          _buildActionButton(
                            icon: _voiceCommandEnabled ? Icons.mic : Icons.mic_off,
                            color: _voiceCommandEnabled ? Colors.blue : Colors.grey,
                            onTap: _onVoiceToggle,
                            active: _voiceCommandEnabled,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Bottom row - 1 button (centered)
                      _buildActionButton(
                        icon: _isStanding ? Icons.airline_seat_recline_normal : Icons.accessibility_new,
                        color: Colors.purple,
                        onTap: _onStandSitToggle,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Left Analog Joystick
            Positioned(
              left: leftJoystickX,
              top: joystickY,
              child: CustomJoystick(
                listener: _onLeftJoystickChanged,
              ),
            ),
            
            // Right Analog Joystick
            Positioned(
              left: rightJoystickX,
              top: joystickY,
              child: CustomJoystick(
                listener: _onRightJoystickChanged,
              ),
            ),
            
            // Code/Documentation Button (Top Right) - Subtle style
            Positioned(
              right: 16,
              top: 16,
              child: GestureDetector(
                onTap: _showCodeInfoDialog,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.textSecondary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.code,
                    color: AppColors.textSecondary.withOpacity(0.6),
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }

  void _showCodeInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.accent.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.code,
                      color: AppColors.accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'ESP/Arduino Code',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Content
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tải code ESP32/Arduino tại:',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    SelectableText(
                      'https://github.com/babynghe2003/MIPI_Robot',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Data Format:',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'SPEED:<-100~100>|TURN:<-100~100>|LX:<val>|LY:<val>|RX:<val>|RY:<val>',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
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
        ).copyWith(
          boxShadow: active ? [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
            )
          ] : null,
        ),
        child: Icon(
          icon,
          color: active ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildBluetoothButton() {
    final isConnected = context.watch<BluetoothManager>().isConnected;
    return GestureDetector(
      onTap: _showBluetoothDialog,
      child: Container(
        width: 50,
        height: 50,
        decoration: AppStyles.neumorphicDecoration(
          color: isConnected ? Colors.blue.withOpacity(0.2) : AppColors.surface,
          borderRadius: 15,
        ).copyWith(
          border: Border.all(
            color: isConnected ? Colors.blue : Colors.transparent,
            width: isConnected ? 2 : 0,
          ),
          boxShadow: isConnected ? [
            BoxShadow(
              color: Colors.blue.withOpacity(0.6),
              blurRadius: 20,
              spreadRadius: 3,
            ),
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ] : null,
        ),
        child: Icon(
          isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
          color: isConnected ? Colors.blue : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool active = false,
  }) {
    const double size = 45.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: AppStyles.neumorphicDecoration(
          color: active ? color.withOpacity(0.3) : AppColors.surface,
          borderRadius: size / 2, // 50% radius for circle
          pressed: true,
        ).copyWith(
          border: Border.all(
            color: color.withOpacity(active ? 0.8 : 0.3),
            width: 1.5,
          ),
          boxShadow: active ? [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 1,
            )
          ] : null,
        ),
        child: Icon(
          icon,
          color: color,
          size: 22,
        ),
      ),
    );
  }

  void _onJumpPressed() {
    context.read<BluetoothManager>().sendData("ACTION:JUMP\n");
  }

  void _onVoiceToggle() {
    setState(() {
      _voiceCommandEnabled = !_voiceCommandEnabled;
    });
    context.read<BluetoothManager>().sendData("ACTION:VOICE:${_voiceCommandEnabled ? 'ON' : 'OFF'}\n");
  }

  void _onStandSitToggle() {
    setState(() {
      _isStanding = !_isStanding;
    });
    context.read<BluetoothManager>().sendData("ACTION:${_isStanding ? 'STAND' : 'SIT'}\n");
  }
}

// Improved Bluetooth Dialog
class BluetoothConnectionDialog extends StatefulWidget {
  const BluetoothConnectionDialog({super.key});

  @override
  State<BluetoothConnectionDialog> createState() => _BluetoothConnectionDialogState();
}

class _BluetoothConnectionDialogState extends State<BluetoothConnectionDialog> {
  @override
  Widget build(BuildContext context) {
    final manager = context.watch<BluetoothManager>();
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: screenSize.width * 0.9,
        height: screenSize.height * 0.9,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.accent.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Compact Header with Mode Selection
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  // BLE Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        manager.setMode(BluetoothMode.ble);
                        manager.startScan();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: manager.mode == BluetoothMode.ble ? AppColors.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: manager.mode == BluetoothMode.ble ? AppColors.accent : AppColors.shadowLight,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            "BLE",
                            style: TextStyle(
                              color: manager.mode == BluetoothMode.ble ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Classic Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        manager.setMode(BluetoothMode.classic);
                        manager.startScan();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: manager.mode == BluetoothMode.classic ? AppColors.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: manager.mode == BluetoothMode.classic ? AppColors.accent : AppColors.shadowLight,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            "Classic",
                            style: TextStyle(
                              color: manager.mode == BluetoothMode.classic ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Close Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            
            // Scan Status
            if (manager.connectionState == AppConnectionState.scanning)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      backgroundColor: AppColors.background,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Scanning for devices...",
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            
            if (manager.connectionState == AppConnectionState.connecting)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Connecting...",
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 4),
            
            // Device List
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.shadowLight, width: 1),
                ),
                child: _buildDeviceList(manager),
              ),
            ),
            
            // Connected Device Info
            if (manager.isConnected)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        manager.connectedDeviceName ?? 'Connected',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => manager.disconnect(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text("Disconnect", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceList(BluetoothManager manager) {
    if (manager.mode == BluetoothMode.none) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bluetooth_disabled, color: AppColors.textSecondary, size: 48),
            SizedBox(height: 16),
            Text(
              "Select a Bluetooth mode to start scanning",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final devices = manager.mode == BluetoothMode.ble 
        ? manager.bleScanResults 
        : manager.classicScanResults;

    if (devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              manager.connectionState == AppConnectionState.scanning 
                  ? Icons.bluetooth_searching 
                  : Icons.devices,
              color: AppColors.textSecondary,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              manager.connectionState == AppConnectionState.scanning 
                  ? "Searching for devices..." 
                  : "No devices found",
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (manager.connectionState != AppConnectionState.scanning)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("Start Scan"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => manager.startScan(),
                ),
              ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: devices.length,
      separatorBuilder: (context, index) => Divider(color: AppColors.shadowLight, height: 1),
      itemBuilder: (context, index) {
        if (manager.mode == BluetoothMode.ble) {
          final result = manager.bleScanResults[index];
          final deviceName = result.device.platformName.isNotEmpty 
              ? result.device.platformName 
              : "Unknown Device";
          final deviceId = result.device.remoteId.toString();
          final rssi = result.rssi;
          
          return _buildDeviceTile(
            name: deviceName,
            subtitle: deviceId,
            rssi: rssi,
            onTap: () => manager.connectBLE(result.device),
          );
        } else {
          final result = manager.classicScanResults[index];
          final deviceName = result.device.name ?? "Unknown Device";
          final deviceId = result.device.address;
          final rssi = result.rssi;
          
          return _buildDeviceTile(
            name: deviceName,
            subtitle: deviceId,
            rssi: rssi,
            onTap: () => manager.connectClassic(result.device),
          );
        }
      },
    );
  }

  Widget _buildDeviceTile({
    required String name,
    required String subtitle,
    required int rssi,
    required VoidCallback onTap,
  }) {
    // Calculate signal strength icon
    IconData signalIcon;
    Color signalColor;
    if (rssi >= -50) {
      signalIcon = Icons.signal_cellular_4_bar;
      signalColor = Colors.green;
    } else if (rssi >= -70) {
      signalIcon = Icons.signal_cellular_alt;
      signalColor = Colors.orange;
    } else {
      signalIcon = Icons.signal_cellular_alt_1_bar;
      signalColor = Colors.red;
    }

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.bluetooth, color: AppColors.accent),
      ),
      title: Text(
        name,
        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(signalIcon, color: signalColor, size: 18),
          const SizedBox(width: 4),
          Text(
            "$rssi dBm",
            style: TextStyle(color: signalColor, fontSize: 11),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 14),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _RateLimitedSender {
  _RateLimitedSender({
    required this.onSend,
  }) : minInterval = const Duration(milliseconds: 50);

  final void Function(double value) onSend;
  final Duration minInterval;

  DateTime? _lastSent;
  Timer? _pendingTimer;
  double? _pendingValue;
  double? _lastSentValue;

  void update(double value) {
    if (_pendingValue == null && _lastSentValue != null && value == _lastSentValue) {
      return;
    }

    final now = DateTime.now();
    final elapsed = _lastSent == null ? minInterval : now.difference(_lastSent!);
    if (_lastSent == null || elapsed >= minInterval) {
      _dispatch(value);
    } else {
      final delay = minInterval - elapsed;
      _pendingValue = value;
      _pendingTimer?.cancel();
      _pendingTimer = Timer(delay, () {
        if (_pendingValue != null) {
          _dispatch(_pendingValue!);
        }
      });
    }
  }

  void forceSend(double value) {
    _dispatch(value, force: true);
  }

  void _dispatch(double value, {bool force = false}) {
    _pendingTimer?.cancel();
    _pendingTimer = null;
    _pendingValue = null;

    if (!force && _lastSentValue != null && value == _lastSentValue) {
      _lastSent = DateTime.now();
      return;
    }

    onSend(value);
    _lastSentValue = value;
    _lastSent = DateTime.now();
  }

  void dispose() {
    _pendingTimer?.cancel();
    _pendingTimer = null;
    _pendingValue = null;
  }
}
