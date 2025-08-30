# 🛡️ Debug Mode Duplicate Protection

## Problem Analysis

The duplicate event **"NOTE-020-1755390186-0000000030004000800000d9b4ddb582:1:2:1"** was occurring because in **debug mode**, Flutter's hot reload feature can cause:

1. **Controller Recreation**: `HomeController` instances are recreated during hot reload
2. **State Loss**: The `_processedEventIds` Set and `_lastTransactionByValue` Map are cleared
3. **Duplicate Processing**: Events that were already processed get processed again

## Solution Implemented

### Static Collections for Debug Mode

Added static collections that persist across hot reloads:

```dart
// Static sets to persist across debug hot reloads
static final Set<String> _globalProcessedEventIds = <String>{};
static final Map<String, DateTime> _globalLastTransactionByValue = <String, DateTime>{};

// Instance-level fallback for release builds
Set<String> _processedEventIds = <String>{};
Map<String, DateTime> _lastTransactionByValue = <String, DateTime>{};
```

### Helper Methods

Created getters that automatically choose the appropriate collection:

```dart
Set<String> get _activeProcessedEventIds {
  return kDebugMode ? _globalProcessedEventIds : _processedEventIds;
}

Map<String, DateTime> get _activeLastTransactionByValue {
  return kDebugMode ? _globalLastTransactionByValue : _lastTransactionByValue;
}
```

### Universal Updates

All duplicate checking methods now use `_activeProcessedEventIds` and `_activeLastTransactionByValue`:

-   ✅ `processBanknoteInserted()`
-   ✅ `processCoinInserted()`
-   ✅ `processProductEvent()`
-   ✅ Periodic cleanup timer
-   ✅ Dispose method

## How It Works

### Debug Mode (kDebugMode = true)

-   Uses **static collections** that survive hot reload
-   Event IDs persist across controller recreations
-   Prevents duplicate processing during development

### Release Mode (kDebugMode = false)

-   Uses **instance collections** for better memory management
-   Normal cleanup and disposal behavior
-   Optimal performance for production

## Testing Verification

The problematic event **"NOTE-020-1755390186-0000000030004000800000d9b4ddb582:1:2:1"** should now be properly prevented from duplicating, even during hot reload scenarios.

### Expected Behavior:

1. First occurrence: ✅ **Processed normally**
2. Hot reload occurs: 🔄 **Static collections preserved**
3. Duplicate attempt: ❌ **Blocked with log message**

## Logs to Monitor

Look for these log messages:

-   `❌ NOTA DUPLICADA - Evento de nota já processado (event ID): [eventId]`
-   `❌ NOTA DUPLICADA - Comando de nota exato já processado: [command]`
-   `❌ NOTA DUPLICADA - Transação de nota duplicada detectada: R$[value]`

## Cleanup Strategy

-   **Debug mode**: Static collections are only cleared on app restart or manual dispose
-   **Release mode**: Regular cleanup every hour + normal disposal
-   **Memory management**: Automatic cleanup for transactions older than 1 hour
