// import 'dart:developer';

// import 'package:flutter/services.dart';

// class AndroidLockTaskService {
//   static const MethodChannel _kioskChannel = MethodChannel('kiosk_channel');

//   Future<void> startKioskMode() async {
//     final result = await _kioskChannel.invokeMethod('startKioskMode');
//     log('Kiosk mode started: $result');
//   }

//   Future<void> stopKioskMode() async {
//     final result = await _kioskChannel.invokeMethod('stopKioskMode');
//     log('Kiosk mode stopped: $result');
//   }

//   Future<bool> isKioskActive() async {
//     return await _kioskChannel.invokeMethod('isKioskModeActive');
//   }
// }
