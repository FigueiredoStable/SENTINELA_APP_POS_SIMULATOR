import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:get_it/get_it.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:sentinela_app_pos_simulator/models/api_initialization_global_settings_model.dart';
import 'package:sentinela_app_pos_simulator/routes/navigation_service.dart';
import 'package:sentinela_app_pos_simulator/services/api_service.dart';
import 'package:sentinela_app_pos_simulator/services/bluetooth_service.dart';
import 'package:sentinela_app_pos_simulator/services/internet_connection_service.dart';
import 'package:sentinela_app_pos_simulator/src/core/di/service_locator.dart';
import 'package:sentinela_app_pos_simulator/src/pagbank.dart';
import 'package:sentinela_app_pos_simulator/src/pages/home/home_controller.dart';
import 'package:sentinela_app_pos_simulator/utils/constants.dart';
import 'package:sentinela_app_pos_simulator/utils/default_launcher_service.dart';
import 'package:sentinela_app_pos_simulator/utils/logger_util.dart';
import 'package:sentinela_app_pos_simulator/utils/utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../utils/secure_storage_keys.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final bool isReady = false;
  final platform = MethodChannel('bluetooth_pairing');
  final ValueNotifier<String> returnCheck = ValueNotifier<String>("Carregando...");
  final ValueNotifier<String> internetCheckStatus = ValueNotifier<String>("Checando conexão com a internet...");
  Timer? validadePOSTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init(); // começa a carregar só após o Lottie estar visível
    });
  }

  @override
  void dispose() {
    returnCheck.dispose();
    validadePOSTimer?.cancel();
    validadePOSTimer = null;
    super.dispose();
  }

  Future<void> enableBluetooth() async {
    await platform.invokeMethod('enableBluetooth');
  }

  Future<bool> isBluetoothEnabled() async {
    return await platform.invokeMethod('isBluetoothEnabled');
  }

  Future<bool> pairDevice(String mac) async {
    return await platform.invokeMethod('pairDevice', {'mac': mac});
  }

  initPlatformState() async {
    try {
      String udid = await FlutterUdid.udid;
      if (!await SecureStorageKey.main.instance.containsKey(key: 'maintenance_code')) await SecureStorageKey.main.instance.write(key: 'maintenance_code', value: "397285");
      if (!await SecureStorageKey.main.instance.containsKey(key: 'instalation_udid')) await SecureStorageKey.main.instance.write(key: 'instalation_udid', value: udid);
      if (!await SecureStorageKey.main.instance.containsKey(key: 'active_pinpad_code')) await SecureStorageKey.main.instance.write(key: 'active_pinpad_code', value: "000000");
      if (!await SecureStorageKey.main.instance.containsKey(key: 'interface_bluetooth_mac')) {
        await SecureStorageKey.main.instance.write(key: 'interface_bluetooth_mac', value: "00:00:00:00:00");
      }
      if (!await SecureStorageKey.main.instance.containsKey(key: 'user_serial')) await SecureStorageKey.main.instance.write(key: 'user_serial', value: "000000");
      if (!await SecureStorageKey.main.instance.containsKey(key: 'device_key')) await SecureStorageKey.main.instance.write(key: 'device_key', value: "000000");
      if (!await SecureStorageKey.main.instance.containsKey(key: 'version')) await SecureStorageKey.main.instance.write(key: 'version', value: "1.0.0");
      if (!await SecureStorageKey.main.instance.containsKey(key: 'registered')) await SecureStorageKey.main.instance.write(key: 'registered', value: "false");
      if (!await SecureStorageKey.main.instance.containsKey(key: 'blocked')) await SecureStorageKey.main.instance.write(key: 'blocked', value: "false");
      if (!await SecureStorageKey.main.instance.containsKey(key: 'schema')) await SecureStorageKey.main.instance.write(key: 'schema', value: null);
      if (!await SecureStorageKey.main.instance.containsKey(key: 'client_uuid')) await SecureStorageKey.main.instance.write(key: 'client_uuid', value: null);
      if (!await SecureStorageKey.main.instance.containsKey(key: 'app_id')) await SecureStorageKey.main.instance.write(key: 'app_id', value: udid);
      if (!await SecureStorageKey.main.instance.containsKey(key: 'machine_id')) await SecureStorageKey.main.instance.write(key: 'machine_id', value: null);
      if (!await SecureStorageKey.main.instance.containsKey(key: 'machine_name')) await SecureStorageKey.main.instance.write(key: 'machine_name', value: null);
      if (!await SecureStorageKey.main.instance.containsKey(key: 'price_options')) await SecureStorageKey.main.instance.write(key: 'price_options', value: null);
      if (!await SecureStorageKey.main.instance.containsKey(key: 'counter_options')) await SecureStorageKey.main.instance.write(key: 'counter_options', value: null);
      if (!await SecureStorageKey.main.instance.containsKey(key: 'payments_types_options')) await SecureStorageKey.main.instance.write(key: 'payments_types_options', value: null);
      if (!await SecureStorageKey.main.instance.containsKey(key: 'support_informations')) await SecureStorageKey.main.instance.write(key: 'support_informations', value: null);
      if (!await SecureStorageKey.main.instance.containsKey(key: 'operation_options')) await SecureStorageKey.main.instance.write(key: 'operation_options', value: null);
      if (!await SecureStorageKey.main.instance.containsKey(key: 'default_initialization_settings')) {
        await SecureStorageKey.main.instance.write(key: 'default_initialization_settings', value: null);
      }
      if (!await SecureStorageKey.main.instance.containsKey(key: 'machine_was_turned_on_by_schedule')) {
        await SecureStorageKey.main.instance.write(key: 'machine_was_turned_on_by_schedule', value: "false");
      }
      if (!await SecureStorageKey.main.instance.containsKey(key: 'machine_was_turned_off_by_schedule')) {
        await SecureStorageKey.main.instance.write(key: 'machine_was_turned_off_by_schedule', value: "false");
      }
    } on PlatformException {
      logger.e("Failed to initialize platform state");
    }
  }

  // * Configurar UI
  Future<void> configureSystemUI() async {
    // Remover todas as barras (SystemChrome)
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive, overlays: []);

    // Travar orientação
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  //* Configurar tela
  Future<void> configureScreenSettings() async {
    // Manter a tela ligada
    await WakelockPlus.enable();

    // Aumentar brilho
    await ScreenBrightness().setApplicationScreenBrightness(1.0);
  }

  Future<void> requestAppPermissions() async {
    await [Permission.bluetooth, Permission.bluetoothScan, Permission.bluetoothConnect, Permission.location, Permission.storage].request();
  }

  Future<void> _initializeApp() async {
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // * Verifica se o bluetooth esta ativo
        final bluetoothEnabled = await isBluetoothEnabled();
        if (!bluetoothEnabled) {
          logger.w('Bluetooth não está ativo, tentando ativar...');
          await enableBluetooth();
          logger.w('Bluetooth ativado.');
        }
        returnCheck.value = 'Ativando POS';

        //* Services (sincrono com signalsReady, aqui é onde o app vai ficar esperando o retorno do POS)
        // * Bluetooth responsavel por gerenciar a conexão com o a interface
        final bluetoothService = BluetoothService();
        GetIt.I.registerSingleton<BluetoothService>(bluetoothService, dispose: (instance) => instance.disposeBluetoothService());

        logger.w(await SecureStorageKey.main.instance.read(key: "pos_activation_code"));
        String clientPinpadId = await SecureStorageKey.main.instance.read(key: "pos_activation_code") ?? "000000";

        logger.w('Aguardando o POS ser ativado...');
        final paymentHandler = PaymentHandlerController();
        GetIt.I.registerSingleton<PaymentHandlerController>(paymentHandler, signalsReady: true, dispose: (instance) => instance.disposePaymentHandlerController());
        await paymentHandler.init(pinpadId: clientPinpadId);

        returnCheck.value = 'Aguarde...';
        await GetIt.I.allReady();
        logger.w('POS ativado com sucesso!');
        returnCheck.value = 'Sentinela inicializado.';

        GetIt.I<NavigationService>().pushAndRemoveUntil('/home');
      });
    } catch (e, s) {
      logger.e("Erro ao iniciar app", e, s);
      // TODO - ver a necessidade de criar uma tela de erro
    }
  }

  Future<void> getAppConfigurations() async {
    //* Show all storage data
    Utils.showAllStorageData();

    // * Check if the device is registered and not blocked
    final registered = await SecureStorageKey.main.instance.read(key: 'registered');
    final blocked = await SecureStorageKey.main.instance.read(key: 'blocked');
    logger.w("registered: $registered \n blocked: $blocked");
    if (registered == 'false') {
      returnCheck.value = 'Indo para tela de registro';

      GetIt.I<NavigationService>().pushAndRemoveUntil('/loading');
      return;
    }

    if (GetIt.I<InternetCheckConnectionService>().isConnected) {
      internetCheckStatus.value = "Conectado à internet";
    }

    bool success = await checkLocalSettings();
    if (!success) {
      // * Se não conseguiu validar as configurações do POS, inicia o timer para tentar novamente
      validadePOSTimer = Timer.periodic(const Duration(seconds: 20), (timer) async {
        final connected = GetIt.I<InternetCheckConnectionService>().isConnected;
        if (!connected) {
          logger.w("POS não está conectado à internet.");
          internetCheckStatus.value = "Sem conexão com a internet\nTentando novamente...";
        } else {
          internetCheckStatus.value = "Conectado à internet";
        }
        logger.w("Validando configurações do POS... tentando novamente");
        await checkLocalSettings();
      });
    }
  }

  Future<bool> checkLocalSettings() async {
    bool responseStatus = false;
    try {
      String client = await SecureStorageKey.main.instance.read(key: 'client_uuid') ?? '';
      String machineId = await SecureStorageKey.main.instance.read(key: 'machine_id') ?? '';
      int firstBootTime = Utils.getCurrentEpoch();
      Map<String, String> appInfos = await Utils.getAppVersionInfo();
      Map<String, dynamic> payload = {'client': client, 'machine_id': machineId, "sentinela_info": appInfos, 'first_boot_time': firstBootTime};
      logger.w("Payload validate settings: $payload");

      final response = await GetIt.I<ApiService>().supabase.functions.invoke('sentinela-validate-pos-settings', body: payload).timeout(Duration(seconds: 45));

      if (response.status == 200) {
        // Populate model
        final configurations = ApiInititializationGlobalSettings.fromJson(response.data);

        // * Verifica se o dispositivo foi registrado, caso não tenha sido, vai para o fluxo de registro
        if (configurations.configuration!.registered == false) {
          returnCheck.value = 'Liberando Sentinela para novo registro';

          await SecureStorageKey.main.instance.write(key: 'registered', value: 'false');
          await SecureStorageKey.main.instance.write(key: 'blocked', value: 'false');
          await SecureStorageKey.main.instance.write(key: 'machine_id', value: null);
          await SecureStorageKey.main.instance.write(key: 'machine_name', value: null);

          await Future.delayed(Duration(seconds: 1));
          GetIt.I<NavigationService>().pushAndRemoveUntil('/loading');
          responseStatus = true;
        }

        // TODO - Mesmo quando bloqueado o app deve continuar mandando movimento
        // * Verifica se o dispositivo foi bloqueado, caso tenha sido, vai para o fluxo de bloqueio
        if (configurations.configuration!.blocked == true) {
          await SecureStorageKey.main.instance.write(key: 'blocked', value: 'true');
          await Future.delayed(Duration(seconds: 1));

          GetIt.I<HomeController>().isBlocked.value = true;
          GetIt.I<NavigationService>().pushAndRemoveUntil('/home');

          responseStatus = true;
        }

        logger.i('Configurações do Sentinela: ${configurations.toJson()}');

        await SecureStorageKey.main.instance.write(key: 'machine_name', value: configurations.configuration!.name);
        await SecureStorageKey.main.instance.write(key: 'blocked', value: configurations.configuration!.blocked.toString());
        await SecureStorageKey.main.instance.write(key: 'registered', value: configurations.configuration!.registered.toString());
        await SecureStorageKey.main.instance.write(key: 'price_options', value: jsonEncode(configurations.configuration!.priceOptions));
        await SecureStorageKey.main.instance.write(key: 'counter_options', value: jsonEncode(configurations.configuration!.counterOptions));
        await SecureStorageKey.main.instance.write(key: 'payments_types', value: jsonEncode(configurations.configuration!.paymentsTypes));
        await SecureStorageKey.main.instance.write(key: 'support_information', value: jsonEncode(configurations.configuration!.supportInformation));
        await SecureStorageKey.main.instance.write(key: 'operation_options', value: jsonEncode(configurations.configuration!.operationOptions));
        await SecureStorageKey.main.instance.write(key: 'interface_bluetooth_mac', value: configurations.configuration!.interfaceMacAddress.toString());
        await SecureStorageKey.main.instance.write(key: 'pos_activation_code', value: configurations.configuration!.pos.toString());
        await SecureStorageKey.main.instance.write(key: 'default_initialization_settings', value: jsonEncode(configurations.configuration!.defaultInitializationSettings));
        await SecureStorageKey.main.instance.write(key: 'maintenance_code', value: configurations.configuration!.defaultInitializationSettings!.maintenanceCode.toString());

        // * Inicia o app
        _initializeApp();
      } else {
        logger.e("Response: ${response.status}");
        returnCheck.value = response.data['message'];
        responseStatus = false;
      }

      responseStatus = true;
    } on FunctionException catch (e) {
      logger.e("Exeption: ${e.status}\n, details: ${jsonEncode(e.details)}");
      returnCheck.value = e.details['message'];
      responseStatus = false;
    } on TimeoutException {
      logger.e("Request timed out while invoking the function.");
      returnCheck.value = "Tempo limite excedido\nTentando novament...";
      responseStatus = false;
    } on SocketException catch (e) {
      logger.e("Request timed out while invoking the function, exception: $e");
      returnCheck.value = "Problemas com a rede\nTentando novamente...";
    } on Exception catch (e) {
      // Handle any other exceptions
      logger.e("An unexpected error occurred: $e  of type ${e.runtimeType}");
      returnCheck.value = "Ocorreu um erro inesperado\nTentando novamente...";
      responseStatus = false;
    }
    return responseStatus;
  }

  Future<void> _init() async {
    returnCheck.value = "Iniciando Sentinela";
    await Future.delayed(const Duration(milliseconds: 100));

    await setupLocator();
    returnCheck.value = "Ativando serviços";

    await Firebase.initializeApp();
    logger.i("Firebase inicializado com sucesso");

    await requestAppPermissions();
    logger.i("Permissões solicitadas com sucesso");

    if (Utils.checkIfIsNotReleaseMode()) {
      await SetDefaultLauncherService().askUserToSetAsDefaultLauncher();
      logger.i("Solicitação para definir como launcher padrão enviada");
    }

    await configureSystemUI();
    logger.i("UI configurada com sucesso");

    await configureScreenSettings();
    logger.i("Tela configurada com sucesso");

    await initPlatformState();
    logger.i("Estado da plataforma inicializado com sucesso");

    await getAppConfigurations();
    returnCheck.value = "Aguardando configurações";
    Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // Bloqueia completamente a tentativa de voltar
        debugPrint("Voltar bloqueado. didPop: $didPop, result: $result");
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(gradient: Constants.kbackgroundGradient),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset("assets/lottie/sentinela-spolus.json", height: 300),
                const SizedBox(height: 16),
                ValueListenableBuilder<String>(
                  valueListenable: internetCheckStatus,
                  builder: (_, value, __) => AutoSizeText(
                    value,
                    style: TextStyle(
                      color: value.contains("Sem conexão") ? Colors.yellowAccent : Colors.white,
                      fontWeight: FontWeight.w900,
                      shadows: [Shadow(blurRadius: 8.0, color: Colors.black.withAlpha(100), offset: Offset(2, 2))],
                    ),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    minFontSize: 14,
                    maxFontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<String>(
                  valueListenable: returnCheck,
                  builder: (_, value, __) => AutoSizeText(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(blurRadius: 8.0, color: Colors.black.withAlpha(100), offset: Offset(2, 2))],
                    ),
                    maxLines: 4,
                    textAlign: TextAlign.center,
                    minFontSize: 21,
                    maxFontSize: 26,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
