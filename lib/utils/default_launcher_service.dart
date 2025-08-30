// import 'package:flutter/services.dart';

import 'dart:developer';

import 'package:flutter/services.dart';

class SetDefaultLauncherService {
  static const MethodChannel _launcherChannel = MethodChannel('launcher_channel');

  Future<void> askUserToSetAsDefaultLauncher() async {
    try {
      await _launcherChannel.invokeMethod('promptLauncherSelection');
    } catch (e) {
      log('Erro ao solicitar launcher padrão: $e');
    }
  }
}
