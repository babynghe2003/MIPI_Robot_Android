import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart' as classic;

enum BluetoothMode { none, ble, classic }
enum AppConnectionState { disconnected, scanning, connecting, connected }

class BleUuids {
  static const service = '00ff';
  static const pidGroups = [
    'ff01',
    'ff02',
    'ff03',
    'ff04',
  ];
  static const velocity = 'ff05';
  static const yawAngle = 'ff06';
  static const pitchAxis = 'ff07';
  static const pitchOffset = 'ff08';
  static const robotHeight = 'ff09';
  static const leftLeg = 'ff0a';
  static const rightLeg = 'ff0b';
  static const fallenStatus = 'ff0c';
  static const action = 'ff0d';
}

class RobotActionCodes {
  static const int stop = 0;
  static const int start = 1;
  static const int dance = 2;
}

class BluetoothManager extends ChangeNotifier {
  BluetoothMode _mode = BluetoothMode.none;
  AppConnectionState _connectionState = AppConnectionState.disconnected;
  
  // BLE
  ble.BluetoothDevice? _bleDevice;
  ble.BluetoothCharacteristic? _writeCharacteristic;
  final Map<String, ble.BluetoothCharacteristic> _bleCharacteristics = {};
  List<ble.ScanResult> _bleScanResults = [];
  StreamSubscription? _bleScanSubscription;
  StreamSubscription? _bleConnectionSubscription;

  // Classic
  classic.BluetoothConnection? _classicConnection;
  List<classic.BluetoothDiscoveryResult> _classicScanResults = [];
  StreamSubscription? _classicScanSubscription;

  // Getters
  BluetoothMode get mode => _mode;
  AppConnectionState get connectionState => _connectionState;
  List<ble.ScanResult> get bleScanResults => _bleScanResults;
  List<classic.BluetoothDiscoveryResult> get classicScanResults => _classicScanResults;
  bool get isConnected => _connectionState == AppConnectionState.connected;
  String? get connectedDeviceName {
    if (_mode == BluetoothMode.ble) return _bleDevice?.platformName;
    if (_mode == BluetoothMode.classic) return _classicConnection?.isConnected == true ? "Classic Device" : null; // Classic connection doesn't easily store name after connect unless we save it
    return null;
  }

  void setMode(BluetoothMode mode) {
    disconnect();
    _mode = mode;
    notifyListeners();
  }

  Future<void> startScan() async {
    if (_connectionState == AppConnectionState.scanning) return;

    _connectionState = AppConnectionState.scanning;
    notifyListeners();

    if (_mode == BluetoothMode.ble) {
      _bleScanResults.clear();
      try {
        // Start scanning
        await ble.FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
        
        _bleScanSubscription = ble.FlutterBluePlus.scanResults.listen((results) {
          _bleScanResults = results;
          notifyListeners();
        });

        // Listen for scan stop
        ble.FlutterBluePlus.isScanning.listen((isScanning) {
          if (!isScanning && _connectionState == AppConnectionState.scanning) {
             _connectionState = AppConnectionState.disconnected;
             notifyListeners();
          }
        });

      } catch (e) {
        debugPrint("BLE Scan Error: $e");
        _connectionState = AppConnectionState.disconnected;
        notifyListeners();
      }
    } else if (_mode == BluetoothMode.classic) {
      _classicScanResults.clear();
      try {
        _classicScanSubscription = classic.FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
          final existingIndex = _classicScanResults.indexWhere((element) => element.device.address == r.device.address);
          if (existingIndex >= 0) {
            _classicScanResults[existingIndex] = r;
          } else {
            _classicScanResults.add(r);
          }
          notifyListeners();
        });
        
        _classicScanSubscription?.onDone(() {
           if(_connectionState == AppConnectionState.scanning) {
             _connectionState = AppConnectionState.disconnected;
             notifyListeners();
           }
        });
      } catch (e) {
         debugPrint("Classic Scan Error: $e");
         _connectionState = AppConnectionState.disconnected;
         notifyListeners();
      }
    }
  }

  Future<void> stopScan() async {
    if (_mode == BluetoothMode.ble) {
      await ble.FlutterBluePlus.stopScan();
      _bleScanSubscription?.cancel();
    } else if (_mode == BluetoothMode.classic) {
      await classic.FlutterBluetoothSerial.instance.cancelDiscovery();
      _classicScanSubscription?.cancel();
    }
    if (_connectionState == AppConnectionState.scanning) {
      _connectionState = AppConnectionState.disconnected;
      notifyListeners();
    }
  }

  Future<void> connectBLE(ble.BluetoothDevice device) async {
    await stopScan();
    _connectionState = AppConnectionState.connecting;
    notifyListeners();

    try {
      await device.connect();
      _bleDevice = device;
      _bleCharacteristics.clear();
      
      // Discover services
      List<ble.BluetoothService> services = await device.discoverServices();
      debugPrint('Discovered ${services.length} services:');
      for (var service in services) {
        debugPrint('Service: ${service.uuid}');
        for (var characteristic in service.characteristics) {
          final charUuid = characteristic.uuid.toString().toLowerCase();
          debugPrint('  Char: $charUuid in service ${service.uuid}, read: ${characteristic.properties.read}, write: ${characteristic.properties.write}, writeNoResp: ${characteristic.properties.writeWithoutResponse}');
        }
      }
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          final charUuid = characteristic.uuid.toString().toLowerCase();
          if (_writeCharacteristic == null && (characteristic.properties.write || characteristic.properties.writeWithoutResponse)) {
            _writeCharacteristic = characteristic;
          }
          _bleCharacteristics[charUuid] = characteristic;
        }
      }
      
      _bleConnectionSubscription = device.connectionState.listen((state) {
        if (state == ble.BluetoothConnectionState.disconnected) {
          disconnect();
        }
      });

      _connectionState = AppConnectionState.connected;
      notifyListeners();
    } catch (e) {
      debugPrint("BLE Connect Error: $e");
      disconnect();
    }
  }

  Future<void> connectClassic(classic.BluetoothDevice device) async {
    await stopScan();
    _connectionState = AppConnectionState.connecting;
    notifyListeners();
    
    try {
      _classicConnection = await classic.BluetoothConnection.toAddress(device.address);
      _connectionState = AppConnectionState.connected;
      
      // Listen for disconnection
      _classicConnection!.input!.listen(null).onDone(() {
        disconnect();
      });
      
      notifyListeners();
    } catch (e) {
      debugPrint("Classic Connect Error: $e");
      disconnect();
    }
  }

  Future<void> disconnect() async {
    if (_mode == BluetoothMode.ble) {
      if (_bleDevice != null) {
        await _bleDevice!.disconnect();
      }
      _bleConnectionSubscription?.cancel();
      _bleDevice = null;
      _writeCharacteristic = null;
      _bleCharacteristics.clear();
    } else if (_mode == BluetoothMode.classic) {
      if (_classicConnection != null) {
        await _classicConnection!.close();
        _classicConnection = null;
      }
    }
    _connectionState = AppConnectionState.disconnected;
    notifyListeners();
  }

  Future<void> sendData(String data) async {
    if (!isConnected) return;

    try {
      if (_mode == BluetoothMode.ble && _writeCharacteristic != null) {
        await _writeCharacteristic!.write(utf8.encode(data), withoutResponse: true);
      } else if (_mode == BluetoothMode.classic && _classicConnection != null) {
        _classicConnection!.output.add(utf8.encode(data));
        await _classicConnection!.output.allSent;
      }
    } catch (e) {
      debugPrint("Send Data Error: $e");
    }
  }

  Future<void> updateVelocity(double value) async {
    if (_mode != BluetoothMode.ble) return;
    await _writeFloat(BleUuids.velocity, value);
  }

  Future<void> updateYaw(double value) async {
    if (_mode != BluetoothMode.ble) return;
    await _writeFloat(BleUuids.yawAngle, value);
  }

  Future<void> updateLeftLegHeight(double value) async {
    if (_mode != BluetoothMode.ble) return;
    await _writeFloat(BleUuids.leftLeg, value);
  }

  Future<void> updateRightLegHeight(double value) async {
    if (_mode != BluetoothMode.ble) return;
    await _writeFloat(BleUuids.rightLeg, value);
  }

  Future<void> updatePidGroup(int groupIndex, List<double> values) async {
    if (_mode != BluetoothMode.ble) return;
    if (groupIndex < 0 || groupIndex >= BleUuids.pidGroups.length) return;
    await _writeFloatArray(BleUuids.pidGroups[groupIndex], values.take(3).toList());
  }

  Future<List<double>?> readPidGroup(int groupIndex) async {
    if (_mode != BluetoothMode.ble) return null;
    if (!isConnected) return null;
    if (groupIndex < 0 || groupIndex >= BleUuids.pidGroups.length) return null;
    return _readFloatArray(BleUuids.pidGroups[groupIndex], 3);
  }

  Future<void> sendActionCommand(int code) async {
    if (_mode != BluetoothMode.ble) return;
    await _writeUint8(BleUuids.action, code);
  }

  Future<void> _writeFloat(String uuid, double value) async {
    final data = ByteData(4)..setFloat32(0, value.toDouble(), Endian.little);
    await _writeBleCharacteristic(uuid, data.buffer.asUint8List());
  }

  Future<void> _writeFloatArray(String uuid, List<double> values) async {
    final byteData = ByteData(4 * values.length);
    for (int i = 0; i < values.length; i++) {
      byteData.setFloat32(i * 4, values[i].toDouble(), Endian.little);
    }
    await _writeBleCharacteristic(uuid, byteData.buffer.asUint8List());
  }

  Future<void> _writeUint8(String uuid, int value) async {
    final data = Uint8List.fromList([value & 0xFF]);
    await _writeBleCharacteristic(uuid, data);
  }

  Future<List<double>?> _readFloatArray(String uuid, int expectedLength) async {
    final bytes = await _readBleCharacteristic(uuid);
    if (bytes == null || bytes.length < expectedLength * 4) return null;
    final byteData = ByteData.sublistView(Uint8List.fromList(bytes));
    final result = <double>[];
    for (int i = 0; i < expectedLength; i++) {
      result.add(byteData.getFloat32(i * 4, Endian.little));
    }
    return result;
  }

  Future<List<int>?> _readBleCharacteristic(String uuid) async {
    if (!isConnected || _mode != BluetoothMode.ble) return null;
    final characteristic = _bleCharacteristics[uuid.toLowerCase()];
    if (characteristic == null || !characteristic.properties.read) return null;
    try {
      return await characteristic.read();
    } catch (e) {
      debugPrint('Read $uuid failed: $e');
      return null;
    }
  }

  Future<void> _writeBleCharacteristic(String uuid, List<int> value) async {
    if (!isConnected || _mode != BluetoothMode.ble) return;
    final characteristic = _bleCharacteristics[uuid.toLowerCase()];
    if (characteristic == null) return;
    final supportsWriteWithResponse = characteristic.properties.write;
    final supportsWriteWithoutResponse = characteristic.properties.writeWithoutResponse;
    bool attemptWithoutResponse = supportsWriteWithoutResponse && !supportsWriteWithResponse;
    try {
      await characteristic.write(value, withoutResponse: attemptWithoutResponse);
    } catch (e) {
      if (attemptWithoutResponse && supportsWriteWithResponse) {
        // Fallback to write with response if no-response is rejected at runtime.
        try {
          await characteristic.write(value, withoutResponse: false);
          return;
        } catch (_) {}
      }
      debugPrint('Write $uuid failed: $e');
    }
  }
}
