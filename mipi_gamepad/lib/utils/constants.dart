import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color accent = Color.fromARGB(255, 255, 107, 1);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  
  static const Color shadowLight = Color(0xFF2C2C2C);
  static const Color shadowDark = Color(0xFF000000);

  // Control surface colors
  static const Color controlSurface = Color(0xFF6C6B6B);
  static const Color controlHighlight = Color.fromARGB(64, 255, 255, 255);
  static const Color controlShadow = Color.fromARGB(64, 0, 0, 0);
}

class AppStyles {
  /// Common style for control containers (throttle track, joystick base, buttons)
  static BoxDecoration controlContainerDecoration({
    double borderRadius = 71,
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.controlSurface,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: const [
        BoxShadow(
          color: AppColors.controlHighlight,
          offset: Offset(-1, -4),
          blurRadius: 4.5,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: AppColors.controlShadow,
          offset: Offset(1, 4),
          blurRadius: 8,
          spreadRadius: 1,
        ),
      ],
    );
  }

  /// Style for joystick base with stronger shadows
  static BoxDecoration joystickBaseDecoration({
    double borderRadius = 71,
  }) {
    return BoxDecoration(
      color: AppColors.controlSurface,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: const [
        BoxShadow(
          color: AppColors.controlHighlight,
          offset: Offset(-2, -5),
          blurRadius: 10,
          spreadRadius: 2,
        ),
        BoxShadow(
          color: Color.fromARGB(125, 0, 0, 0),
          offset: Offset(2, 8),
          blurRadius: 10,
          spreadRadius: 2,
        ),
      ],
    );
  }

  /// Style for control thumb/handle (throttle handle)
  static BoxDecoration controlThumbDecoration({
    Color color = AppColors.accent,
    double borderRadius = 15,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.4),
          blurRadius: 8,
          spreadRadius: 2,
        ),
      ],
    );
  }

  /// Style for buttons with glow effect
  static BoxDecoration glowButtonDecoration({
    required Color glowColor,
    double borderRadius = 25,
    bool active = true,
  }) {
    return BoxDecoration(
      color: AppColors.controlSurface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: glowColor, width: 2),
      boxShadow: active
          ? [
              BoxShadow(
                color: glowColor.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ]
          : null,
    );
  }

  static BoxDecoration neumorphicDecoration({
    Color color = AppColors.surface,
    double borderRadius = 16,
    bool pressed = false,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: pressed
          ? [
              // Inner shadow simulation for pressed state
              BoxShadow(
                color: AppColors.shadowDark.withOpacity(0.5),
                offset: const Offset(4, 4),
                blurRadius: 15,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: AppColors.shadowLight.withOpacity(0.1),
                offset: const Offset(-4, -4),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ]
          : [
              BoxShadow(
                color: AppColors.shadowDark,
                offset: const Offset(4, 4),
                blurRadius: 15,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: AppColors.shadowLight,
                offset: const Offset(-4, -4),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
    );
  }
  
  static BoxDecoration glassDecoration({
    Color color = Colors.black,
    double opacity = 0.3,
    double borderRadius = 16,
  }) {
    return BoxDecoration(
      color: color.withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(0.1),
        width: 1,
      ),
    );
  }
}
