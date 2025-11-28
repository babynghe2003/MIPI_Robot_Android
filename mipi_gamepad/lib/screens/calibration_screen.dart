import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_manager.dart';
import '../utils/constants.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  // Mock data structure for PID
  // Group 1: Pitch (P, I, D)
  // Group 2: Roll (P, I, D)
  // Group 3: Yaw (P, I, D)
  
  final List<List<double>> _pids = [
    [0.0, 0.0, 0.0], // Pitch
    [0.0, 0.0, 0.0], // Roll
    [0.0, 0.0, 0.0], // Yaw
  ];

  final List<String> _groupNames = ['Pitch', 'Roll', 'Yaw'];
  final List<String> _paramNames = ['P', 'I', 'D'];

  void _onSliderChanged(int groupIndex, int paramIndex, double value) {
    setState(() {
      _pids[groupIndex][paramIndex] = value;
    });
    _sendCalibrationData();
  }

  void _sendCalibrationData() {
    // Format: CAL:G:P:V (Calibration:Group:Param:Value) or similar
    // Or send all: CAL:P1,I1,D1;P2,I2,D2;P3,I3,D3
    String data = "CAL:";
    for (var group in _pids) {
      data += "${group[0].toStringAsFixed(2)},${group[1].toStringAsFixed(2)},${group[2].toStringAsFixed(2)};";
    }
    data += "\n";
    
    context.read<BluetoothManager>().sendData(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Calibration (PID Tuning)'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (groupIndex) {
            return Expanded(child: _buildGroup(groupIndex));
          }),
        ),
      ),
    );
  }

  Widget _buildGroup(int groupIndex) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(8),
      decoration: AppStyles.neumorphicDecoration(color: AppColors.surface),
      child: Column(
        children: [
          Text(
            _groupNames[groupIndex],
            style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(3, (paramIndex) {
                return _buildSlider(groupIndex, paramIndex);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(int groupIndex, int paramIndex) {
    return Column(
      children: [
        Text(
          _pids[groupIndex][paramIndex].toStringAsFixed(1),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: Slider(
              value: _pids[groupIndex][paramIndex],
              min: 0.0,
              max: 10.0,
              activeColor: AppColors.accent,
              inactiveColor: AppColors.shadowLight,
              onChanged: (val) => _onSliderChanged(groupIndex, paramIndex, val),
            ),
          ),
        ),
        Text(
          _paramNames[paramIndex],
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
