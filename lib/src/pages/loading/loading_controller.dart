import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:get_it/get_it.dart';
import 'package:sentinela_app_pos_simulator/models/api_machines_available_model.dart';
import 'package:sentinela_app_pos_simulator/services/api_service.dart';
import 'package:sentinela_app_pos_simulator/services/logger_service.dart';
import 'package:sentinela_app_pos_simulator/utils/secure_storage_keys.dart';
import 'package:sentinela_app_pos_simulator/utils/utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// enum to control the view state of loading view
enum LoadingViewState { loading, getUserSerial, getAvailableMachines, registerReport, done }

class LoadingController {
  ValueNotifier<String> loadingStatus = ValueNotifier<String>('Inicializando');
  ValueNotifier<LoadingViewState> loadingViewState = ValueNotifier(LoadingViewState.loading);
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

  TextEditingController userSerialFormField = TextEditingController();
  ValueNotifier<ApiMachinesAvailable> availableMachines = ValueNotifier<ApiMachinesAvailable>(ApiMachinesAvailable(machines: []));

  ValueNotifier<bool> registered = ValueNotifier<bool>(false);
  ValueNotifier<String> appUUIDRegistration = ValueNotifier<String>('');
  TextEditingController registerController = TextEditingController();
  String returnMessage = "";
  ValueNotifier<Map<String, dynamic>> machineConfiguredInfos = ValueNotifier<Map<String, dynamic>>({});

  Map<String, dynamic> readAndroidBuildData(AndroidDeviceInfo build) {
    return <String, dynamic>{
      'version.securityPatch': build.version.securityPatch,
      'version.sdkInt': build.version.sdkInt,
      'version.release': build.version.release,
      'version.previewSdkInt': build.version.previewSdkInt,
      'version.incremental': build.version.incremental,
      'version.codename': build.version.codename,
      'version.baseOS': build.version.baseOS,
      'board': build.board,
      'bootloader': build.bootloader,
      'brand': build.brand,
      'device': build.device,
      'display': build.display,
      'fingerprint': build.fingerprint,
      'hardware': build.hardware,
      'host': build.host,
      'id': build.id,
      'manufacturer': build.manufacturer,
      'model': build.model,
      'product': build.product,
      'isPhysicalDevice': build.isPhysicalDevice,
      'serialNumber': build.serialNumber,
    };
  }

  // call the public schema table users
  Future<String?> findSerialGetSchema(String userSerial) async {
    try {
      final res = await GetIt.I<ApiService>().supabase.functions.invoke('sentinela-register-pos-by-client', body: {'client_serial': userSerial}).timeout(Duration(seconds: 30));
      final resEncoded = jsonEncode(res.data);
      final resDecoded = jsonDecode(resEncoded);
      await SecureStorageKey.main.instance.write(key: 'client_uuid', value: '${resDecoded['data']['id']}');

      loadingViewState.value = LoadingViewState.getAvailableMachines;

      GetIt.I<LoggerService>().d('raw 200 : ${res.data}');

      return null;
    } on FunctionException catch (e) {
      GetIt.I<LoggerService>().e(jsonEncode(e.details));
      GetIt.I<LoggerService>().e("function exeption : ${e.status}");

      returnMessage = e.details['message'];
      return returnMessage;
    } on TimeoutException {
      // Handle timeout specifically
      GetIt.I<LoggerService>().e("Request timed out while invoking the function.");
      return "Tempo limite excedido\nPor favor tente novamente";
    } on SocketException catch (e) {
      GetIt.I<LoggerService>().e("SocketException: $e");
      return "Erro de Rede\nPor favor, confira sua conexão com a internet";
    } catch (e) {
      // Handle any other exceptions
      GetIt.I<LoggerService>().e("An unexpected error occurred: $e  of type ${e.runtimeType}");
      return "Ocorreu um erro inesperado\nPor favor tente novamente";
    }
  }

  Future<String?> getAvailableMachines() async {
    try {
      final res = await GetIt.I<ApiService>().supabase.functions.invoke(
        'sentinela-machines-available',
        body: {'client': await SecureStorageKey.main.instance.read(key: 'client_uuid')},
      );
      availableMachines.value = ApiMachinesAvailable.fromJson(res.data);
      GetIt.I<LoggerService>().d("res 200 json available: ${availableMachines.value.toJson()}");

      return 'done';
    } on FunctionException catch (e) {
      GetIt.I<LoggerService>().e(jsonEncode(e.details));
      GetIt.I<LoggerService>().e("function exeption : ${e.status}");

      returnMessage = e.details['message'];
      return returnMessage;
    }
  }

  Future<Map<String, dynamic>> registerDevice(Machines machine) async {
    Map<String, dynamic> response = {};
    try {
      String udid = await FlutterUdid.udid;
      Map<String, dynamic> posInfos = readAndroidBuildData(await deviceInfoPlugin.androidInfo);
      Map<String, String> appInfos = await Utils.getAppVersionInfo();
      String client = await SecureStorageKey.main.instance.read(key: 'client_uuid') ?? '';

      Map<String, dynamic> payload = {'client': client, 'machine_id': machine.id, 'app_id': udid, 'pos_device_specs': posInfos, "sentinela_apk_package_info": appInfos};
      GetIt.I<LoggerService>().w("payload: $payload");

      final res = await GetIt.I<ApiService>().supabase.functions.invoke('sentinela-attach-pos-machine', body: payload).timeout(Duration(seconds: 30));

      GetIt.I<LoggerService>().d('raw 200 : ${res.data}');

      await SecureStorageKey.main.instance.write(key: 'machine_id', value: res.data['machine']['id'].toString());
      await SecureStorageKey.main.instance.write(key: 'machine_name', value: res.data['machine']['name']);
      await SecureStorageKey.main.instance.write(key: 'registered', value: "true");
      await SecureStorageKey.main.instance.write(key: 'blocked', value: "false");
      machineConfiguredInfos.value = jsonDecode(jsonEncode(res.data['machine']));
      GetIt.I<LoggerService>().d("machineConfiguredInfos: ${machineConfiguredInfos.value}");
      response = res.data;

      return jsonDecode(jsonEncode(res.data));
    } on FunctionException catch (e) {
      GetIt.I<LoggerService>().e(jsonEncode(e.details));
      GetIt.I<LoggerService>().e("function exeption : ${e.status}");
      response = e.details;
      return response;
    }
  }

  Future<bool> cancelRegisterDevice() async {
    String machineId = await SecureStorageKey.main.instance.read(key: 'machine_id') ?? '';
    try {
      final res = await GetIt.I<ApiService>().supabase.functions.invoke(
        'sentinela-remove-attach-pos-machine',
        body: {
          'client': await SecureStorageKey.main.instance.read(key: 'client_uuid'),
          'machine_id': machineId,
        },
      );

      GetIt.I<LoggerService>().d('raw 200 : ${res.data}');

      await SecureStorageKey.main.instance.write(key: 'machine_id', value: res.data['id'].toString());
      await SecureStorageKey.main.instance.write(key: 'machine_name', value: res.data['name']);
      await SecureStorageKey.main.instance.write(key: 'registered', value: "true");
      await SecureStorageKey.main.instance.write(key: 'blocked', value: "false");

      return true;
    } on FunctionException catch (e) {
      GetIt.I<LoggerService>().e(jsonEncode(e.details));
      GetIt.I<LoggerService>().e("function exeption : ${e.status}");

      returnMessage = e.details['message'];
      return false;
    }
  }

  void disposeController() {
    loadingStatus.dispose();
    loadingViewState.dispose();
    userSerialFormField.dispose();
    registerController.dispose();
    availableMachines.dispose();
    registered.dispose();
    appUUIDRegistration.dispose();
    machineConfiguredInfos.dispose();
    GetIt.I<LoggerService>().i("LoadingController disposed");
  }
}
