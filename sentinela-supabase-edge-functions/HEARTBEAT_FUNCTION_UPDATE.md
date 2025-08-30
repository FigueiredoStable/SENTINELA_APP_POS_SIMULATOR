# 🔄 Updated Supabase Edge Function: sentinela-heartbeat

## Overview

The `sentinela-heartbeat` edge function has been enhanced to accept and pass through device monitoring data including battery level, battery state, and Bluetooth RSSI tracking. The function stores this data as-is for application-level processing.

## 📡 Request Format

### Updated JSON Body

```json
{
    "client": "client-uuid-here",
    "machine_id": "machine-id-here",
    "fsm_data": "I1C1B1E1M1J1W1",
    "pinpad_authenticated": true,
    "device_battery_level": "085",
    "device_battery_state": "C",
    "bluetooth_rssi": "045"
}
```

### Field Descriptions

| Field                  | Type    | Required | Description                   | Example                   |
| ---------------------- | ------- | -------- | ----------------------------- | ------------------------- |
| `client`               | string  | ✅ Yes   | Client UUID                   | `"550e8400-e29b-41d4..."` |
| `machine_id`           | string  | ✅ Yes   | Machine identifier            | `"MACHINE_001"`           |
| `fsm_data`             | string  | ✅ Yes   | Finite State Machine data     | `"I1C1B1E1M1J1W1"`        |
| `pinpad_authenticated` | boolean | ✅ Yes   | POS authentication status     | `true`                    |
| `device_battery_level` | string  | ❌ No    | Battery percentage (000-100)  | `"085"`                   |
| `device_battery_state` | string  | ❌ No    | Battery state code            | `"C"`                     |
| `bluetooth_rssi`       | string  | ❌ No    | RSSI absolute value (000-100) | `"045"`                   |

### Battery State Codes

-   **C** = Charging
-   **D** = Discharging
-   **F** = Full
-   **N** = Connected Not Charging
-   **U** = Unknown

## 🗄️ Data Storage

The edge function stores the device monitoring fields **as-is** without any data transformation:

-   Fields are stored exactly as received from the client
-   No type conversion or validation performed
-   Application handles all data interpretation and processing
-   Database schema flexibility maintained

## 📊 Response Format

### Success Response

```json
{
    "success": true,
    "commands": [],
    "is_blocked": false
}
```

### With Commands

```json
{
    "success": true,
    "commands": [
        {
            "command": "CMD-MACHINE_RESTART",
            "event_id": "cmd-123",
            "type": "CMD"
        }
    ],
    "is_blocked": false
}
```

### Error Responses

#### Client Not Found (404)

```json
{
    "message": "Cliente não encontrado"
}
```

#### Machine Not Found (404)

```json
{
    "message": "Máquina não encontrada"
}
```

#### Server Error (500)

```json
{
    "message": "Falha de conexão, Tente novamente",
    "error": "detailed error message"
}
```

## 🔧 Function Logic Flow

1. **Parse Request**: Extract all fields from JSON body
2. **Validate Client**: Check client exists and get schema
3. **Validate Machine**: Verify machine exists in client schema
4. **Store Data**: Save FSM data + optional device monitoring fields as-is
5. **Process Commands**: Handle remote command queue
6. **Clean Queue**: Clear executed commands
7. **Return Response**: Send commands and status to client

## ✅ Backward Compatibility

The updated function maintains full backward compatibility:

-   ✅ **Old clients** without device monitoring fields continue to work
-   ✅ **Existing FSM data** processing unchanged
-   ✅ **Command queue functionality** preserved
-   ✅ **Response format** identical to before
-   ✅ **Optional fields** gracefully handled when missing

## 🎯 Benefits

1. **📊 Data Collection**: Collects device monitoring data for application processing
2. **� Flexibility**: No database schema assumptions
3. **⚡ Performance**: Minimal processing overhead
4. **�️ Simplicity**: Clean pass-through approach
5. **📈 Scalability**: Application handles all data interpretation
