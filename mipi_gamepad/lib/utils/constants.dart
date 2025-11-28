import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color accent = Color(0xFFFF6600);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  
  static const Color shadowLight = Color(0xFF2C2C2C);
  static const Color shadowDark = Color(0xFF000000);
}

class AppStyles {
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
