import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/bluetooth_manager.dart';
import '../../utils/constants.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  final List<List<double>> _pids = [
    [0.0, 0.0, 0.0], // Pitch
    [0.0, 0.0, 0.0], // Roll
    [0.0, 0.0, 0.0], // Yaw
  ];

  // Min/Max ranges for each slider [groupIndex][paramIndex] = (min, max)
  final List<List<(double, double)>> _ranges = [
    [(-5.0, 5.0), (-5.0, 5.0), (-5.0, 5.0)], // Pitch P, I, D
    [(-5.0, 5.0), (-5.0, 5.0), (-5.0, 5.0)], // Roll P, I, D
    [(-5.0, 5.0), (-5.0, 5.0), (-5.0, 5.0)], // Yaw P, I, D
  ];

  final List<String> _groupNames = ['Pitch', 'Roll', 'Yaw'];
  final List<String> _paramNames = ['P', 'I', 'D'];

  @override
  void initState() {
    super.initState();
    _loadSavedRanges();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialPidValues();
    });
  }

  Future<void> _loadSavedRanges() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (int g = 0; g < 3; g++) {
        for (int p = 0; p < 3; p++) {
          final key = 'pid_range_${g}_$p';
          final min = prefs.getDouble('${key}_min') ?? -5.0;
          final max = prefs.getDouble('${key}_max') ?? 5.0;
          _ranges[g][p] = (min, max);
        }
      }
    });
  }

  Future<void> _saveRange(int groupIndex, int paramIndex, double min, double max) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'pid_range_${groupIndex}_$paramIndex';
    await prefs.setDouble('${key}_min', min);
    await prefs.setDouble('${key}_max', max);
  }

  void _showGroupRangeEditor(int groupIndex) {
    // Copy current ranges for P, I, D
    List<(double, double)> newRanges = [
      _ranges[groupIndex][0],
      _ranges[groupIndex][1],
      _ranges[groupIndex][2],
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          title: Text(
            '${_groupNames[groupIndex]} - Range Settings',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
          ),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                // Header row
                Row(
                  children: [
                    const SizedBox(width: 32),
                    Expanded(child: Center(child: Text('Min', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)))),
                    Expanded(child: Center(child: Text('Max', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)))),
                  ],
                ),
                const SizedBox(height: 8),
                // P, I, D rows
                for (int p = 0; p < 3; p++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: Text(_paramNames[p], style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: _buildMiniInput(newRanges[p].$1, (v) {
                            setDialogState(() => newRanges[p] = (v, newRanges[p].$2));
                          }),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMiniInput(newRanges[p].$2, (v) {
                            setDialogState(() => newRanges[p] = (newRanges[p].$1, v));
                          }),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                // Presets - apply to all 3
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPresetButton('±1', () => setDialogState(() {
                      for (int i = 0; i < 3; i++) newRanges[i] = (-1.0, 1.0);
                    })),
                    _buildPresetButton('±5', () => setDialogState(() {
                      for (int i = 0; i < 3; i++) newRanges[i] = (-5.0, 5.0);
                    })),
                    _buildPresetButton('±10', () => setDialogState(() {
                      for (int i = 0; i < 3; i++) newRanges[i] = (-10.0, 10.0);
                    })),
                    _buildPresetButton('0~1', () => setDialogState(() {
                      for (int i = 0; i < 3; i++) newRanges[i] = (0.0, 1.0);
                    })),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                // Validate all ranges
                for (int p = 0; p < 3; p++) {
                  if (newRanges[p].$1 >= newRanges[p].$2) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('${_paramNames[p]}: Min must be less than Max')),
                    );
                    return;
                  }
                }
                // Apply all ranges
                setState(() {
                  for (int p = 0; p < 3; p++) {
                    _ranges[groupIndex][p] = newRanges[p];
                    _pids[groupIndex][p] = _pids[groupIndex][p].clamp(newRanges[p].$1, newRanges[p].$2);
                    _saveRange(groupIndex, p, newRanges[p].$1, newRanges[p].$2);
                  }
                });
                Navigator.pop(ctx);
              },
              child: const Text('Save', style: TextStyle(color: AppColors.accent)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniInput(double value, ValueChanged<double> onChanged) {
    return SizedBox(
      height: 32,
      child: TextFormField(
        initialValue: value.toString(),
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (text) {
          final parsed = double.tryParse(text);
          if (parsed != null) onChanged(parsed);
        },
      ),
    );
  }

  Widget _buildPresetButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.shadowLight),
        ),
        child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
      ),
    );
  }

  void _onSliderChanged(int groupIndex, int paramIndex, double value) {
    setState(() {
      _pids[groupIndex][paramIndex] = value;
    });
  }

  void _sendPidGroup(int groupIndex) {
    if (!mounted) return;
    context.read<BluetoothManager>().updatePidGroup(groupIndex, List<double>.from(_pids[groupIndex]));
  }

  Future<void> _loadInitialPidValues() async {
    final manager = context.read<BluetoothManager>();
    if (!manager.isConnected || manager.mode != BluetoothMode.ble) return;
    for (int groupIndex = 0; groupIndex < _pids.length; groupIndex++) {
      final values = await manager.readPidGroup(groupIndex);
      if (!mounted) return;
      if (values != null && values.length >= 3) {
        setState(() {
          for (int paramIndex = 0; paramIndex < 3; paramIndex++) {
            _pids[groupIndex][paramIndex] = values[paramIndex];
          }
        });
      }
    }
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
          GestureDetector(
            onLongPress: () => _showGroupRangeEditor(groupIndex),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _groupNames[groupIndex],
                style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
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
    final range = _ranges[groupIndex][paramIndex];
    final min = range.$1;
    final max = range.$2;
    final divisions = ((max - min) * 20).round().clamp(10, 200);

    final clampedValue = _pids[groupIndex][paramIndex].clamp(min, max);
    if (clampedValue != _pids[groupIndex][paramIndex]) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _pids[groupIndex][paramIndex] = clampedValue);
      });
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            clampedValue.toStringAsFixed(2),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ),
        Text(
          '[${min.toStringAsFixed(1)}, ${max.toStringAsFixed(1)}]',
          style: TextStyle(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 8),
        ),
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: Slider(
              value: clampedValue,
              min: min,
              max: max,
              divisions: divisions,
              activeColor: AppColors.accent,
              inactiveColor: AppColors.shadowLight,
              onChanged: (val) => _onSliderChanged(groupIndex, paramIndex, val),
              onChangeEnd: (_) => _sendPidGroup(groupIndex),
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
