import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../calibration_screen/calibration_screen.dart';
import '../../services/bluetooth_manager.dart';
import '../../widgets/custom_joystick.dart';
import 'widgets/bluetooth_connection_dialog.dart';
import 'widgets/code_info_dialog.dart';
import 'widgets/home_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _throttleValue = 0.0;
  double _turnValue = 0.0;
  double _leftJoystickX = 0.0;
  double _leftJoystickY = 0.0;
  double _rightJoystickX = 0.0;
  double _rightJoystickY = 0.0;
  bool _voiceCommandEnabled = false;
  bool _isStanding = true;

  late final _RateLimitedSender<double> _leftThrottleSender;
  late final _RateLimitedSender<double> _rightThrottleSender;
  late final _RateLimitedSender<(double, double)> _leftJoySender;
  late final _RateLimitedSender<(double, double)> _rightJoySender;

  @override
  void initState() {
    super.initState();
    _leftThrottleSender = _RateLimitedSender<double>(onSend: _sendLeftThrottle);
    _rightThrottleSender = _RateLimitedSender<double>(onSend: _sendRightThrottle);
    _leftJoySender = _RateLimitedSender<(double, double)>(onSend: _sendLeftJoy);
    _rightJoySender = _RateLimitedSender<(double, double)>(onSend: _sendRightJoy);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _leftThrottleSender.dispose();
    _rightThrottleSender.dispose();
    _leftJoySender.dispose();
    _rightJoySender.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  HomeUiState _buildUiState(BluetoothManager manager) {
    return HomeUiState(
      isStarted: manager.isRunning,
      voiceCommandEnabled: _voiceCommandEnabled,
      isStanding: _isStanding,
      throttleValue: _throttleValue,
      turnValue: _turnValue,
      leftJoystickX: _leftJoystickX,
      leftJoystickY: _leftJoystickY,
      rightJoystickX: _rightJoystickX,
      rightJoystickY: _rightJoystickY,
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<BluetoothManager>();
    return HomeView(
      state: _buildUiState(manager),
      isBluetoothConnected: manager.isConnected,
      onThrottleChanged: _onThrottleChanged,
      onTurnChanged: _onTurnChanged,
      onLeftJoystickChanged: _onLeftJoystickChanged,
      onRightJoystickChanged: _onRightJoystickChanged,
      onToggleStartStop: _toggleStartStop,
      onOpenCalibration: _openCalibration,
      onShowBluetoothDialog: _showBluetoothDialog,
      onShowCodeInfo: _showCodeInfoDialog,
      onJump: _onJumpPressed,
      onVoiceToggle: _onVoiceToggle,
      onStandSitToggle: _onStandSitToggle,
    );
  }

  void _onThrottleChanged(double value) {
    _throttleValue = value;
    _leftThrottleSender.update(value);
  }

  void _onTurnChanged(double value) {
    _turnValue = value;
    _rightThrottleSender.update(value);
  }

  void _onLeftJoystickChanged(StickDragDetails details) {
    _leftJoystickX = details.x;
    _leftJoystickY = details.y;
    _leftJoySender.update((_leftJoystickX, _leftJoystickY));
  }

  void _onRightJoystickChanged(StickDragDetails details) {
    _rightJoystickX = details.x;
    _rightJoystickY = details.y;
    _rightJoySender.update((_rightJoystickX, _rightJoystickY));
  }

  void _sendLegacyControlData(BluetoothManager manager) {
    if (!manager.isRunning) return;
    final speed = (_throttleValue * 100).toInt();
    final turn = (_turnValue * 100).toInt();
    final lx = (_leftJoystickX * 100).toInt();
    final ly = (_leftJoystickY * 100).toInt();
    final rx = (_rightJoystickX * 100).toInt();
    final ry = (_rightJoystickY * 100).toInt();
    final data = "SPEED:$speed|TURN:$turn|LX:$lx|LY:$ly|RX:$rx|RY:$ry\n";
    manager.sendData(data);
  }

  void _sendLeftThrottle(double value) {
    if (!mounted) return;
    final manager = context.read<BluetoothManager>();
    manager.updateLeftThrottle(value);
    if (manager.mode != BluetoothMode.ble) {
      _sendLegacyControlData(manager);
    }
  }

  void _sendRightThrottle(double value) {
    if (!mounted) return;
    final manager = context.read<BluetoothManager>();
    manager.updateRightThrottle(value);
    if (manager.mode != BluetoothMode.ble) {
      _sendLegacyControlData(manager);
    }
  }

  void _sendLeftJoy((double, double) value) {
    if (!mounted) return;
    final manager = context.read<BluetoothManager>();
    if (manager.mode == BluetoothMode.ble) {
      manager.updateLeftJoy(value.$1, value.$2);
    } else {
      _sendLegacyControlData(manager);
    }
  }

  void _sendRightJoy((double, double) value) {
    if (!mounted) return;
    final manager = context.read<BluetoothManager>();
    if (manager.mode == BluetoothMode.ble) {
      manager.updateRightJoy(value.$1, value.$2);
    } else {
      _sendLegacyControlData(manager);
    }
  }

  void _toggleStartStop() {
    final manager = context.read<BluetoothManager>();
    final newState = !manager.isRunning;

    manager.sendIsRunningCommand(newState);

    if (newState) {
      if (manager.mode != BluetoothMode.ble) {
        manager.sendData("START\n");
        _sendLegacyControlData(manager);
      } else {
        _leftThrottleSender.forceSend(_throttleValue);
        _rightThrottleSender.forceSend(_turnValue);
        _leftJoySender.forceSend((_leftJoystickX, _leftJoystickY));
        _rightJoySender.forceSend((_rightJoystickX, _rightJoystickY));
      }
    } else {
      _resetControlValues();
      if (manager.mode != BluetoothMode.ble) {
        manager.sendData("STOP\n");
      } else {
        _leftThrottleSender.forceSend(0);
        _rightThrottleSender.forceSend(0);
        _leftJoySender.forceSend((0.0, 0.0));
        _rightJoySender.forceSend((0.0, 0.0));
      }
    }
  }

  void _resetControlValues() {
    _throttleValue = 0;
    _turnValue = 0;
    _leftJoystickX = 0;
    _leftJoystickY = 0;
    _rightJoystickX = 0;
    _rightJoystickY = 0;
  }

  void _openCalibration() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CalibrationScreen()),
    );
  }

  void _showBluetoothDialog() {
    showDialog(
      context: context,
      builder: (context) => const BluetoothConnectionDialog(),
    );
  }

  void _showCodeInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => const CodeInfoDialog(),
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

class _RateLimitedSender<T> {
  _RateLimitedSender({
    required this.onSend,
  }) : minInterval = const Duration(milliseconds: 50);

  final void Function(T value) onSend;
  final Duration minInterval;

  DateTime? _lastSent;
  Timer? _pendingTimer;
  T? _pendingValue;
  T? _lastSentValue;

  void update(T value) {
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
          _dispatch(_pendingValue as T);
        }
      });
    }
  }

  void forceSend(T value) {
    _dispatch(value, force: true);
  }

  void _dispatch(T value, {bool force = false}) {
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
