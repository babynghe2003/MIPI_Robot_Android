import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../utils/constants.dart';
import '../../../widgets/custom_joystick.dart';
import '../../../widgets/horizontal_throttle.dart';
import '../../../widgets/vertical_throttle.dart';

class HomeUiState {
  const HomeUiState({
    required this.isStarted,
    required this.voiceCommandEnabled,
    required this.isStanding,
    required this.throttleValue,
    required this.turnValue,
    required this.leftJoystickX,
    required this.leftJoystickY,
    required this.rightJoystickX,
    required this.rightJoystickY,
  });

  final bool isStarted;
  final bool voiceCommandEnabled;
  final bool isStanding;
  final double throttleValue;
  final double turnValue;
  final double leftJoystickX;
  final double leftJoystickY;
  final double rightJoystickX;
  final double rightJoystickY;
}

class HomeView extends StatelessWidget {
  const HomeView({
    super.key,
    required this.state,
    required this.isBluetoothConnected,
    required this.onThrottleChanged,
    required this.onTurnChanged,
    required this.onLeftJoystickChanged,
    required this.onRightJoystickChanged,
    required this.onToggleStartStop,
    required this.onOpenCalibration,
    required this.onShowBluetoothDialog,
    required this.onShowCodeInfo,
    required this.onJump,
    required this.onVoiceToggle,
    required this.onStandSitToggle,
  });

  final HomeUiState state;
  final bool isBluetoothConnected;
  final ValueChanged<double> onThrottleChanged;
  final ValueChanged<double> onTurnChanged;
  final ValueChanged<StickDragDetails> onLeftJoystickChanged;
  final ValueChanged<StickDragDetails> onRightJoystickChanged;
  final VoidCallback onToggleStartStop;
  final VoidCallback onOpenCalibration;
  final VoidCallback onShowBluetoothDialog;
  final VoidCallback onShowCodeInfo;
  final VoidCallback onJump;
  final VoidCallback onVoiceToggle;
  final VoidCallback onStandSitToggle;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    const joystickBaseSize = 150.0;
    const joystickStickSize = 80.0;
    const joystickTotalSize = joystickBaseSize + joystickStickSize;

    const verticalThrottleHeight = 280.0;
    const horizontalThrottleWidth = 200.0;

    final joystickY = screenHeight - joystickTotalSize - 10;
    final leftJoystickX = screenWidth * 0.3 - joystickTotalSize / 2;
    final rightJoystickX = screenWidth * 0.7 - joystickTotalSize / 2;

    const verticalThrottleX = 50.0;
    final verticalThrottleY = (screenHeight - verticalThrottleHeight) / 2 - 30;

    final horizontalThrottleX = screenWidth - horizontalThrottleWidth - 30;
    final horizontalThrottleY = (screenHeight - 100) / 2 - 30;

    final controlsY = screenHeight * 0.1;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF7D7D7D), // 0% - #7D7D7D 100%
            Color.fromARGB(255, 75, 75, 75), // 54% - #2C2C2C 81%
            Color(0xFF464646), // 100% - #464646 100%
          ],
          stops: [0.0, 0.74, 1.0], // Positions: 0%, 54%, 100%
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned(
              left: verticalThrottleX,
              top: verticalThrottleY,
              child: SizedBox(
                height: verticalThrottleHeight,
                child: VerticalThrottle(onChanged: onThrottleChanged),
              ),
            ),
            Positioned(
              left: horizontalThrottleX,
              top: horizontalThrottleY,
              child: SizedBox(
                width: horizontalThrottleWidth,
                child: HorizontalThrottle(onChanged: onTurnChanged),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: controlsY,
              child: _buildCenterControls(context),
            ),
            Positioned(
              left: leftJoystickX,
              top: joystickY,
              child: CustomJoystick(listener: onLeftJoystickChanged),
            ),
            Positioned(
              left: rightJoystickX,
              top: joystickY,
              child: CustomJoystick(listener: onRightJoystickChanged),
            ),
            Positioned(
              right: 16,
              top: 16,
              child: GestureDetector(
                onTap: onShowCodeInfo,
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
      ),
    );
  }

  Widget _buildCenterControls(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row 1: Main action bar
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            // color: const Color(0xFF161616),
            color: const Color.fromARGB(111, 82, 82, 82), // outer border color
            borderRadius: BorderRadius.circular(41), // 35 + 6
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                offset: const Offset(2, 4),
                blurRadius: 10,
                spreadRadius: -1,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.25),
                offset: const Offset(-2, -4),
                blurRadius: 8,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(
                color: AppColors.accent,
                width: 1,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
              boxShadow: null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bluetooth button
                GestureDetector(
                  onTap: onShowBluetoothDialog,
                  child: Icon(
                    Icons.bluetooth,
                    color: isBluetoothConnected
                        ? Colors.blue
                        : AppColors.textSecondary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                // Start/Stop button
                GestureDetector(
                  onTap: onToggleStartStop,
                  child: Container(
                    width: 100,
                    height: 40,
                    decoration: BoxDecoration(
                      color: state.isStarted
                          ? const Color(0xFF23BA35)
                          : const Color(0xFFE2524D),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        state.isStarted ? 'RUNNING' : 'STOPPED',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Settings button
                GestureDetector(
                  onTap: onOpenCalibration,
                  child: Icon(
                    Icons.settings,
                    color: AppColors.textSecondary,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 50),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(
                  icon: Icons.arrow_upward,
                  color: Colors.orange,
                  onTap: onJump,
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  icon: state.voiceCommandEnabled ? Icons.mic : Icons.mic_off,
                  color: state.voiceCommandEnabled ? Colors.blue : Colors.grey,
                  onTap: onVoiceToggle,
                  active: state.voiceCommandEnabled,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: state.isStanding
                  ? Icons.airline_seat_recline_normal
                  : Icons.accessibility_new,
              color: Colors.purple,
              onTap: onStandSitToggle,
            ),
          ],
        ),
      ],
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
        decoration:
            AppStyles.neumorphicDecoration(
              color: active ? color.withOpacity(0.3) : AppColors.surface,
              borderRadius: size / 2,
              pressed: true,
            ).copyWith(
              border: Border.all(
                color: color.withOpacity(active ? 0.8 : 0.3),
                width: 1.5,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}
