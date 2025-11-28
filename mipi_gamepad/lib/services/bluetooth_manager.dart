import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart' as classic;

enum BluetoothMode { none, ble, classic }
enum AppConnectionState { disconnected, scanning, connecting, connected }

class BluetoothManager extends ChangeNotifier {
  BluetoothMode _mode = BluetoothMode.none;
  AppConnectionState _connectionState = AppConnectionState.disconnected;
  
  // BLE
  ble.BluetoothDevice? _bleDevice;
  ble.BluetoothCharacteristic? _writeCharacteristic;
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
      
      // Discover services
      List<ble.BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
           // Look for a characteristic with WRITE properties
           if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
             _writeCharacteristic = characteristic;
             // Keep looking for a better one or just break? Usually there's a specific UART service.
             // For now, we take the first writable one.
           }
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
}
