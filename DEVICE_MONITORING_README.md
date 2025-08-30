# 🔋📡 Battery & Bluetooth RSSI Monitoring Implementation

## Overview

This implementation adds battery level monitoring and Bluetooth RSSI (signal strength) tracking to your vending machine Flutter app, providing valuable diagnostic data to the server via enhanced FSM (Finite State Machine) reporting.

## 🚀 Features Added

### 1. **Battery Monitoring**

-   **Real-time battery level** (0-100%)
-   **Battery state tracking** (Charging, Discharging, Full, etc.)
-   **Automatic periodic updates** (every 30 seconds)
-   **FSM-formatted output** for server integration

### 2. **Bluetooth RSSI Monitoring**

-   **Connection status tracking**
-   **Estimated signal strength** when connected
-   **Uses existing BluetoothService** integration
-   **Automatic periodic updates** (every 15 seconds)

### 3. **Clean JSON Integration**

-   **Original FSM preserved**: No concatenation or modification
-   **Separate JSON fields** for battery and RSSI data
-   **Backward compatible** with existing FSM parsing
-   **Structured data** for easy server-side processing

## 📁 Files Created/Modified

### New Files:

1. **`lib/services/device_info_service.dart`** - Core service for device monitoring

### Modified Files:

1. **`pubspec.yaml`** - Added `battery_plus: ^6.0.1` dependency
2. **`lib/src/pages/home/home_controller.dart`** - Integrated DeviceInfoService

## 🔧 Technical Implementation

### DeviceInfoService Architecture

```dart
class DeviceInfoService {
  // Battery monitoring
  int _batteryLevel = 0;
  BatteryState _batteryState = BatteryState.unknown;

  // Bluetooth RSSI monitoring
  int _bluetoothRssi = 0;
  bool _isBluetoothConnected = false;

  // FSM-formatted output methods
  String get batteryStatusForFSM;     // e.g., "085C" (85% Charging)
  String get bluetoothRssiForFSM;     // e.g., "045" (-45 dBm)
}
```

### Enhanced JSON Format

```
Original FSM: "I1C1B1E1M1J1W1" (unchanged)
```

### Heartbeat Data Structure

```json
{
    "fsm_data": "I1C1B1E1M1J1W1",
    "device_battery_level": "085",
    "device_battery_state": "C",
    "bluetooth_rssi": "045"
}
```

## 🎯 **Key Advantages of This Approach:**

### 1. **Clean Separation of Concerns**

-   **FSM Data**: Pure machine state information
-   **Device Health**: Separate structured fields
-   **No Data Mixing**: Each data type in its proper place

### 2. **Backward Compatibility**

-   **Existing FSM parsing**: Works unchanged
-   **No backend modifications**: For FSM processing
-   **Incremental adoption**: Use new fields when ready

### 3. **Better Data Structure**

-   **Typed fields**: Easy validation and processing
-   **Query friendly**: Direct database field access
-   **API evolution**: Easy to add more device metrics

### 📊 **Data Format Specifications**

### Battery State Codes

-   **C** = Charging
-   **D** = Discharging
-   **F** = Full
-   **N** = Connected Not Charging
-   **U** = Unknown

### RSSI Format

-   **000-100** = Signal strength (absolute value of dBm)
-   **000** = No connection
-   **025** = Very strong signal (-25 dBm)
-   **045** = Good signal (-45 dBm)
-   **075** = Weak signal (-75 dBm)

### Battery Level Format

-   **000-100** = Battery percentage (3 digits, zero-padded)
-   **085** = 85% battery level
-   **100** = 100% battery level
-   **025** = 25% battery level

## 🔄 Monitoring Intervals

-   **Battery Updates**: Every 30 seconds
-   **RSSI Updates**: Every 15 seconds
-   **Heartbeat Transmission**: Every 45 seconds (configurable)
-   **Cleanup Operations**: Every 1 hour

## 💡 Benefits for Client Support

### 1. **Proactive Issue Detection**

-   Low battery warnings
-   Weak Bluetooth signal alerts
-   Connection stability monitoring

### 2. **Remote Diagnostics**

-   Real-time device health status
-   Historical battery/signal trends
-   Predictive maintenance insights

### 3. **Improved Troubleshooting**

-   Correlate transaction issues with signal strength
-   Identify battery-related problems
-   Optimize device placement based on RSSI data

## 🛠️ Usage Examples

### Server-Side Monitoring

```sql
-- Identify machines with low battery
SELECT machine_id, device_battery_level
FROM heartbeats
WHERE device_battery_level < 20;

-- Find machines with weak Bluetooth signal
SELECT machine_id, bluetooth_rssi
FROM heartbeats
WHERE bluetooth_rssi > 70; -- -70 dBm or weaker
```

### Alert Thresholds

-   **Battery Critical**: < 15%
-   **Battery Low**: < 30%
-   **RSSI Weak**: > 70 (-70 dBm)
-   **RSSI Critical**: > 85 (-85 dBm)

## 🔧 Platform Requirements

### Android

-   **API Level**: 21+ (Android 5.0+)
-   **Permissions**: BLUETOOTH, BLUETOOTH_ADMIN (automatically handled)
-   **Hardware**: Bluetooth capability required

### Dependencies

-   **battery_plus**: ^6.0.1 (cross-platform battery monitoring)
-   **bluetooth_classic**: existing (Bluetooth communication)
-   **get_it**: existing (dependency injection)

_No custom platform channels or MainActivity modifications required!_

## 🚦 Implementation Status

✅ **Completed Features:**

-   DeviceInfoService implementation
-   Battery monitoring with state tracking
-   Basic Bluetooth RSSI framework
-   FSM integration and formatting
-   HomeController integration
-   Android platform setup

🔄 **Future Enhancements:**

-   Advanced GATT-based RSSI reading
-   iOS platform implementation
-   Historical data caching
-   Predictive analytics integration

## 📝 Configuration

### Enable/Disable Monitoring

```dart
// In HomeController initialization
if (enableDeviceMonitoring) {
  await GetIt.I<DeviceInfoService>().initialize();
}
```

### Adjust Update Intervals

```dart
// In DeviceInfoService
_batteryTimer = Timer.periodic(Duration(seconds: 30), ...);  // Battery
_rssiTimer = Timer.periodic(Duration(seconds: 15), ...);     // RSSI
```

This implementation provides comprehensive device health monitoring that will significantly improve your ability to provide remote support and maintain optimal vending machine performance! 🎯
