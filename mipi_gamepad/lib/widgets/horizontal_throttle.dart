import 'package:flutter/material.dart';
import '../utils/constants.dart';

class HorizontalThrottle extends StatefulWidget {
  final ValueChanged<double> onChanged;
  final String? label;

  const HorizontalThrottle({super.key, required this.onChanged, this.label});

  @override
  State<HorizontalThrottle> createState() => _HorizontalThrottleState();
}

class _HorizontalThrottleState extends State<HorizontalThrottle> {
  double _value = 0.0; // -1.0 to 1.0
  final double _thumbWidth = 70.0;

  void _updatePosition(double localX, double maxWidth) {
    double center = maxWidth / 2;
    double offset = localX - center;
    double maxMove = (maxWidth - _thumbWidth) / 2;

    double normalized = (offset / maxMove).clamp(-1.0, 1.0);

    setState(() {
      _value = normalized;
    });
    widget.onChanged(_value);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth > 0 ? constraints.maxWidth : 280;
        double height = 80;
        double center = width / 2;
        double maxMove = (width - _thumbWidth) / 2;

        double thumbX = center + (_value * maxMove) - (_thumbWidth / 2);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onHorizontalDragUpdate: (details) {
                _updatePosition(details.localPosition.dx, width);
              },
              onHorizontalDragEnd: (details) {
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
                        width: width - 40,
                        height: 6,
                        color: AppColors.shadowDark.withOpacity(0.5),
                      ),
                    ),
                    // Thumb
                    Positioned(
                      left: thumbX,
                      top: 10,
                      bottom: 10,
                      child: Container(
                        width: _thumbWidth,
                        decoration: AppStyles.controlThumbDecoration(),
                        child: const Icon(
                          Icons.drag_handle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.label != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.label!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
