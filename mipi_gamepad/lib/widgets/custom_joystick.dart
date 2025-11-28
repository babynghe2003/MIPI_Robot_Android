import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Custom joystick details returned in listener callback
class StickDragDetails {
  final double x; // -1.0 to 1.0
  final double y; // -1.0 to 1.0

  StickDragDetails({required this.x, required this.y});
}

/// Custom joystick widget that allows stick center to reach the edge of base
/// The stick can visually extend beyond the base boundary
class CustomJoystick extends StatefulWidget {
  final Function(StickDragDetails) listener;
  final double baseSize;
  final double stickSize;

  const CustomJoystick({
    super.key,
    required this.listener,
    this.baseSize = 150.0,
    this.stickSize = 80.0,
  });

  @override
  State<CustomJoystick> createState() => _CustomJoystickState();
}

class _CustomJoystickState extends State<CustomJoystick> {
  Offset _stickPosition = Offset.zero;

  void _onPanUpdate(DragUpdateDetails details, double baseRadius) {
    // Calculate offset from center of base
    final dx = details.localPosition.dx - baseRadius;
    final dy = details.localPosition.dy - baseRadius;
    
    // Calculate distance from center
    final distance = sqrt(dx * dx + dy * dy);
    
    // Maximum distance is the base radius (stick center can reach edge)
    final maxDistance = baseRadius;
    
    double newX, newY;
    
    if (distance <= maxDistance) {
      // Within bounds - use actual position
      newX = dx;
      newY = dy;
    } else {
      // Outside bounds - clamp to edge
      final scale = maxDistance / distance;
      newX = dx * scale;
      newY = dy * scale;
    }
    
    setState(() {
      _stickPosition = Offset(newX, newY);
    });
    
    // Normalize to -1.0 to 1.0
    widget.listener(StickDragDetails(
      x: newX / maxDistance,
      y: newY / maxDistance,
    ));
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _stickPosition = Offset.zero;
    });
    widget.listener(StickDragDetails(x: 0, y: 0));
  }

  @override
  Widget build(BuildContext context) {
    final baseRadius = widget.baseSize / 2;
    final stickRadius = widget.stickSize / 2;
    
    // Total size needs to account for stick extending beyond base
    final totalSize = widget.baseSize + widget.stickSize;
    final offset = widget.stickSize / 2; // Padding for stick overflow
    
    return SizedBox(
      width: totalSize,
      height: totalSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) {
          // Adjust for the offset padding
          _onPanUpdate(
            DragUpdateDetails(
              globalPosition: details.globalPosition,
              localPosition: Offset(
                details.localPosition.dx - offset,
                details.localPosition.dy - offset,
              ),
              delta: details.delta,
            ),
            baseRadius,
          );
        },
        onPanEnd: _onPanEnd,
        child: Stack(
          children: [
            // Base - centered with padding for stick overflow
            Positioned(
              left: offset,
              top: offset,
              child: Container(
                width: widget.baseSize,
                height: widget.baseSize,
                decoration: AppStyles.neumorphicDecoration(
                  borderRadius: baseRadius,
                  pressed: false, // Raised effect for base
                ).copyWith(
                  image: DecorationImage(
                    image: const AssetImage('resources/images/JoyBase.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // Stick - positioned relative to base center
            Positioned(
              left: offset + baseRadius - stickRadius + _stickPosition.dx,
              top: offset + baseRadius - stickRadius + _stickPosition.dy,
              child: Image.asset(
                'resources/images/JoyStick.png',
                width: widget.stickSize,
                height: widget.stickSize,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
