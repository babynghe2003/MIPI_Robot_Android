import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/bluetooth_manager.dart';
import '../../../utils/constants.dart';

class BluetoothConnectionDialog extends StatefulWidget {
  const BluetoothConnectionDialog({super.key});

  @override
  State<BluetoothConnectionDialog> createState() => _BluetoothConnectionDialogState();
}

class _BluetoothConnectionDialogState extends State<BluetoothConnectionDialog> {
  @override
  Widget build(BuildContext context) {
    final manager = context.watch<BluetoothManager>();
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: screenSize.width * 0.9,
        height: screenSize.height * 0.9,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.accent,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        manager.setMode(BluetoothMode.ble);
                        manager.startScan();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: manager.mode == BluetoothMode.ble ? AppColors.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: manager.mode == BluetoothMode.ble ? AppColors.accent : AppColors.shadowLight,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'BLE',
                            style: TextStyle(
                              color: manager.mode == BluetoothMode.ble ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        manager.setMode(BluetoothMode.classic);
                        manager.startScan();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: manager.mode == BluetoothMode.classic ? AppColors.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: manager.mode == BluetoothMode.classic ? AppColors.accent : AppColors.shadowLight,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Classic',
                            style: TextStyle(
                              color: manager.mode == BluetoothMode.classic ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            if (manager.connectionState == AppConnectionState.scanning)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      backgroundColor: AppColors.background,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Scanning for devices...',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (manager.connectionState == AppConnectionState.connecting)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Connecting...',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.shadowLight, width: 1),
                ),
                child: _buildDeviceList(manager),
              ),
            ),
            if (manager.isConnected)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        manager.connectedDeviceName ?? 'Connected',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => manager.disconnect(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Disconnect',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceList(BluetoothManager manager) {
    if (manager.mode == BluetoothMode.none) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bluetooth_disabled, color: AppColors.textSecondary, size: 48),
            SizedBox(height: 16),
            Text(
              'Select a Bluetooth mode to start scanning',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final devices = manager.mode == BluetoothMode.ble
        ? manager.bleScanResults
        : manager.classicScanResults;

    if (devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              manager.connectionState == AppConnectionState.scanning ? Icons.bluetooth_searching : Icons.devices,
              color: AppColors.textSecondary,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              manager.connectionState == AppConnectionState.scanning ? 'Searching for devices...' : 'No devices found',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (manager.connectionState != AppConnectionState.scanning)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Start Scan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => manager.startScan(),
                ),
              ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: devices.length,
      separatorBuilder: (context, index) => Divider(color: AppColors.shadowLight, height: 1),
      itemBuilder: (context, index) {
        if (manager.mode == BluetoothMode.ble) {
          final result = manager.bleScanResults[index];
          final deviceName = result.device.platformName.isNotEmpty ? result.device.platformName : 'Unknown Device';
          final deviceId = result.device.remoteId.toString();
          final rssi = result.rssi;
          return _buildDeviceTile(
            name: deviceName,
            subtitle: deviceId,
            rssi: rssi,
            onTap: () => manager.connectBLE(result.device),
          );
        } else {
          final result = manager.classicScanResults[index];
          final deviceName = result.device.name ?? 'Unknown Device';
          final deviceId = result.device.address;
          final rssi = result.rssi;
          return _buildDeviceTile(
            name: deviceName,
            subtitle: deviceId,
            rssi: rssi,
            onTap: () => manager.connectClassic(result.device),
          );
        }
      },
    );
  }

  Widget _buildDeviceTile({
    required String name,
    required String subtitle,
    required int rssi,
    required VoidCallback onTap,
  }) {
    IconData signalIcon;
    Color signalColor;
    if (rssi >= -50) {
      signalIcon = Icons.signal_cellular_4_bar;
      signalColor = Colors.green;
    } else if (rssi >= -70) {
      signalIcon = Icons.signal_cellular_alt;
      signalColor = Colors.orange;
    } else {
      signalIcon = Icons.signal_cellular_alt_1_bar;
      signalColor = Colors.red;
    }

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.bluetooth, color: AppColors.accent),
      ),
      title: Text(
        name,
        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(signalIcon, color: signalColor, size: 18),
          const SizedBox(width: 4),
          Text(
            '$rssi dBm',
            style: TextStyle(color: signalColor, fontSize: 11),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 14),
        ],
      ),
      onTap: onTap,
    );
  }
}
