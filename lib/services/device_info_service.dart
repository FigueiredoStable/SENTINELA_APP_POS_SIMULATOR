import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:sentinela_app_pos_simulator/services/bluetooth_service.dart';
import 'package:sentinela_app_pos_simulator/services/logger_service.dart';

class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  factory DeviceInfoService() => _instance;
  DeviceInfoService._internal();

  final Battery _battery = Battery();
  Timer? _batteryTimer;
  Timer? _rssiTimer;

  // Battery state tracking
  int _batteryLevel = 0;
  BatteryState _batteryState = BatteryState.unknown;

  // Bluetooth RSSI tracking
  int _bluetoothRssi = 0;
  bool _isBluetoothConnected = false;

  // Getters
  int get batteryLevel => _batteryLevel;
  BatteryState get batteryState => _batteryState;
  int get bluetoothRssi => _bluetoothRssi;
  bool get isBluetoothConnected => _isBluetoothConnected;

  // Battery status as string for FSM
  String get batteryStatusForFSM {
    String levelStr = _batteryLevel.toString().padLeft(3, '0'); // 000-100
    String stateStr = _getBatteryStateCode();
    return '$levelStr$stateStr'; // e.g., "085C" = 85% Charging
  }

  // Bluetooth RSSI as string for FSM (absolute value, 3 digits)
  String get bluetoothRssiForFSM {
    if (!_isBluetoothConnected) return "000";
    int absoluteRssi = _bluetoothRssi.abs();
    return absoluteRssi.toString().padLeft(3, '0'); // e.g., "045" = -45 dBm
  }

  /// Initialize the service and start monitoring
  Future<void> initialize() async {
    try {
      await _updateBatteryInfo();
      await _updateBluetoothRssi();

      // Start periodic updates
      _startBatteryMonitoring();
      _startRssiMonitoring();

      GetIt.I<LoggerService>().i("DeviceInfoService initialized successfully");
    } catch (e) {
      GetIt.I<LoggerService>().e("Error initializing DeviceInfoService: $e");
    }
  }

  /// Start monitoring battery status
  void _startBatteryMonitoring() {
    // Update battery info every 30 seconds
    _batteryTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateBatteryInfo();
    });

    // Listen to battery state changes
    _battery.onBatteryStateChanged.listen((BatteryState state) {
      _batteryState = state;
      GetIt.I<LoggerService>().d("Battery state changed: $state");
    });
  }

  /// Start monitoring Bluetooth RSSI
  void _startRssiMonitoring() {
    // Update RSSI every 15 seconds when connected
    _rssiTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _updateBluetoothRssi();
    });
  }

  /// Update battery level and state
  Future<void> _updateBatteryInfo() async {
    try {
      _batteryLevel = await _battery.batteryLevel;
      _batteryState = await _battery.batteryState;

      GetIt.I<LoggerService>().d("Battery: $_batteryLevel% - State: $_batteryState");
    } catch (e) {
      GetIt.I<LoggerService>().e("Error updating battery info: $e");
    }
  }

  /// Update Bluetooth RSSI
  Future<void> _updateBluetoothRssi() async {
    try {
      // Get Bluetooth connection status from existing BluetoothService
      if (GetIt.I.isRegistered<BluetoothService>()) {
        final bluetoothService = GetIt.I<BluetoothService>();
        final bluetoothState = bluetoothService.bluetoothState;

        // Check if device is connected (status 2 means connected)
        if (bluetoothState.deviceStatus == 2) {
          _isBluetoothConnected = true;
          // For now, use a default good signal strength when connected
          // Real RSSI measurement would require more complex Bluetooth GATT implementation
          _bluetoothRssi = -50; // Default moderate signal strength for connected device

          GetIt.I<LoggerService>().d("Bluetooth connected with estimated RSSI: $_bluetoothRssi dBm");
        } else {
          _isBluetoothConnected = false;
          _bluetoothRssi = 0;
          GetIt.I<LoggerService>().d("Bluetooth device not connected (status: ${bluetoothState.deviceStatus})");
        }
      } else {
        _isBluetoothConnected = false;
        _bluetoothRssi = 0;
        GetIt.I<LoggerService>().d("BluetoothService not registered");
      }
    } catch (e) {
      GetIt.I<LoggerService>().e("Error updating Bluetooth RSSI: $e");
      _isBluetoothConnected = false;
      _bluetoothRssi = 0;
    }
  }

  /// Convert battery state to single character code for FSM
  String _getBatteryStateCode() {
    switch (_batteryState) {
      case BatteryState.charging:
        return 'C';
      case BatteryState.discharging:
        return 'D';
      case BatteryState.full:
        return 'F';
      case BatteryState.connectedNotCharging:
        return 'N';
      case BatteryState.unknown:
        return 'U';
    }
  }

  /// Get detailed battery info for logging
  Map<String, dynamic> getBatteryInfo() {
    return {'level': _batteryLevel, 'state': _batteryState.toString(), 'stateCode': _getBatteryStateCode(), 'fsmFormat': batteryStatusForFSM};
  }

  /// Get detailed Bluetooth info for logging
  Map<String, dynamic> getBluetoothInfo() {
    return {'rssi': _bluetoothRssi, 'isConnected': _isBluetoothConnected, 'fsmFormat': bluetoothRssiForFSM};
  }

  /// Dispose the service and cancel timers
  void dispose() {
    _batteryTimer?.cancel();
    _rssiTimer?.cancel();
    _batteryTimer = null;
    _rssiTimer = null;
    GetIt.I<LoggerService>().i("DeviceInfoService disposed");
  }
}
