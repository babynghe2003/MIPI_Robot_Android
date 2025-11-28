import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import '../utils/constants.dart';

class CustomJoystick extends StatelessWidget {
  final JoystickMode mode;
  final Function(StickDragDetails) listener;

  const CustomJoystick({
    super.key,
    this.mode = JoystickMode.all,
    required this.listener,
  });

  @override
  Widget build(BuildContext context) {
    return Joystick(
      mode: mode,
      listener: listener,
      base: Container(
        width: 200,
        height: 200,
        decoration: AppStyles.neumorphicDecoration(
          borderRadius: 100,
          pressed: true,
        ),
      ),
      stick: Container(
        width: 80,
        height: 80,
        decoration: AppStyles.neumorphicDecoration(
          color: AppColors.accent,
          borderRadius: 40,
        ).copyWith(
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            )
          ]
        ),
      ),
    );
  }
}
