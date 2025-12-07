import 'package:flutter/material.dart';
import '../utils/constants.dart';

class VerticalThrottle extends StatefulWidget {
  final ValueChanged<double> onChanged;

  const VerticalThrottle({super.key, required this.onChanged});

  @override
  State<VerticalThrottle> createState() => _VerticalThrottleState();
}

class _VerticalThrottleState extends State<VerticalThrottle> {
  double _value = 0.0; // -1.0 to 1.0
  final double _thumbHeight = 70.0;

  void _updatePosition(double localY, double maxHeight) {
    // Center is maxHeight / 2
    double center = maxHeight / 2;
    // Calculate offset from center
    double offset = localY - center;

    // Normalize to -1.0 to 1.0
    // Max movement is (maxHeight - thumbHeight) / 2
    double maxMove = (maxHeight - _thumbHeight) / 2;

    double normalized = (offset / maxMove).clamp(-1.0, 1.0);

    // Invert because Y goes down
    // Up should be positive (Forward), Down negative (Backward)
    // But in screen coords, Up is smaller Y.
    // So if localY < center, offset is negative. We want positive.
    // So we invert.
    normalized = -normalized;

    setState(() {
      _value = normalized;
    });
    widget.onChanged(_value);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double height = constraints.maxHeight > 0 ? constraints.maxHeight : 280;
        double width = 80;
        double center = height / 2;
        double maxMove = (height - _thumbHeight) / 2;

        // Calculate thumb position from value
        // value 1.0 -> top -> center - maxMove
        // value -1.0 -> bottom -> center + maxMove
        // value 0.0 -> center

        double thumbY = center - (_value * maxMove) - (_thumbHeight / 2);

        return GestureDetector(
          onVerticalDragUpdate: (details) {
            _updatePosition(details.localPosition.dy, height);
          },
          onVerticalDragEnd: (details) {
            // Snap back to center
            setState(() {
              _value = 0.0;
            });
            widget.onChanged(0.0);
          },
          child: Container(
            width: width,
            height: height,
            decoration: AppStyles.controlContainerDecoration(),
            child: Stack(
              children: [
                // Center Line
                Center(
                  child: Container(
                    width: 6,
                    height: height - 40,
                    color: AppColors.shadowDark.withOpacity(0.5),
                  ),
                ),
                // Thumb
                Positioned(
                  top: thumbY,
                  left: 10,
                  right: 10,
                  child: Container(
                    height: _thumbHeight,
                    decoration: AppStyles.controlThumbDecoration(),
                    child: const Icon(Icons.drag_handle, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
