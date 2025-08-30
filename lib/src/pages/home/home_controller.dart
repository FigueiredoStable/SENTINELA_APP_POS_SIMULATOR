import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:sentinela_app_pos_simulator/enums/interface_event_types_enum.dart';
import 'package:sentinela_app_pos_simulator/enums/payment_view_type.dart';
import 'package:sentinela_app_pos_simulator/models/api_initialization_global_settings_model.dart';
import 'package:sentinela_app_pos_simulator/models/bluetooth_model.dart';
import 'package:sentinela_app_pos_simulator/models/buy_data_model.dart';
import 'package:sentinela_app_pos_simulator/models/command_event_model.dart';
import 'package:sentinela_app_pos_simulator/models/heartbeat_response_model.dart';
import 'package:sentinela_app_pos_simulator/models/product_event_model.dart';
import 'package:sentinela_app_pos_simulator/models/sale_transaction_model.dart';
import 'package:sentinela_app_pos_simulator/models/sentinela_spolus_app_infos_model.dart';
import 'package:sentinela_app_pos_simulator/routes/navigation_service.dart';
import 'package:sentinela_app_pos_simulator/services/api_service.dart';
import 'package:sentinela_app_pos_simulator/services/bluetooth_service.dart';
import 'package:sentinela_app_pos_simulator/services/device_info_service.dart';
import 'package:sentinela_app_pos_simulator/services/internet_connection_service.dart';
import 'package:sentinela_app_pos_simulator/services/logger_service.dart';
import 'package:sentinela_app_pos_simulator/src/pagbank.dart';
import 'package:sentinela_app_pos_simulator/src/simulator/payment_simulator.dart';
import 'package:sentinela_app_pos_simulator/utils/logger_util.dart';
import 'package:sentinela_app_pos_simulator/utils/secure_storage_keys.dart';
import 'package:sentinela_app_pos_simulator/utils/utils.dart';

class HomeController {
  late BluetoothModel interfaceData;

  PriceOptions priceOptionsList = PriceOptions();
  PaymentsTypes paymentsTypesEnabled = PaymentsTypes();
  OperationOptions operationOptions = OperationOptions();
  DefaultInitializationSettings defaultInicializationSettings = DefaultInitializationSettings();

  ValueNotifier<String> homePaymentTypesEnabledTitle = ValueNotifier<String>("");
  ValueNotifier<bool> machineIsTurnnedOn = ValueNotifier<bool>(true);
  ValueNotifier<bool> isBlocked = ValueNotifier<bool>(false);
  ValueNotifier<bool> hasInternetConnection = ValueNotifier<bool>(true);
  SupportInformation supportInfo = SupportInformation();
  SentinelaSpolusAppInfosModel sentinelaSpolusAppInfos = SentinelaSpolusAppInfosModel();
  ValueNotifier<Color> sentinelaGlobalStatusColor = ValueNotifier<Color>(Colors.transparent);

  final ValueNotifier<BuyDataModel> buyData = ValueNotifier(BuyDataModel(price: "0", credit: "0", type: PaymentViewTypeEnum.SELECT));
  Timer? sendHeartbeatTimer;
  Timer? workingTimerWatchdog;
  ValueNotifier<String> interfaceFSM = ValueNotifier<String>("I0C0B0E0M0J0W0");
  ValueNotifier<Map<String, dynamic>> labelsFSM = ValueNotifier<Map<String, dynamic>>({});
  String? _waitingCommand;
  Timer? _responseTimeout;

  void Function(String response)? _onResponseReceived;
  void Function()? _onTimeout;

  // Timer para sincronizar eventos de pagamentos pendentes
  Timer? _pendingTransactionSyncTimer;
  Duration _currentTransactionInterval = Duration(seconds: 10); // começa com 10s
  final Duration _maxTransactionSyncInterval = Duration(minutes: 5); // no máximo 5 minutos

  // Timer para sincronizar eventos de produtos pendentes
  Timer? _pendingProductSyncTimer;
  Duration _currentProductInterval = Duration(seconds: 10); // começa com 10s
  final Duration _maxProductSyncInterval = Duration(minutes: 5); // no máximo 5 minutos

  // Timer para sincronizar eventos de comandos pendentes
  Timer? _pendingCommandSyncTimer;
  Duration _currentCommandInterval = Duration(seconds: 10); // começa com 10s
  final Duration _maxCommandSyncInterval = Duration(minutes: 5); // no máximo 5 minutos

  void Function(String response)? onTefResponseListener;
  void Function(String response)? onCommandResponseListener;

  // Bluetooth subscription and duplicate prevention
  StreamSubscription<BluetoothModel>? _bluetoothSubscription;

  // Static sets to persist across debug hot reloads
  static final Set<String> _globalProcessedEventIds = <String>{};
  static final Map<String, DateTime> _globalLastTransactionByValue = <String, DateTime>{};

  // Instance-level fallback for release builds
  final Set<String> _processedEventIds = <String>{};
  final Map<String, DateTime> _lastTransactionByValue = <String, DateTime>{};
  Timer? _eventIdCleanupTimer;

  // Helper methods to use appropriate sets based on debug mode
  Set<String> get _activeProcessedEventIds {
    return kDebugMode ? _globalProcessedEventIds : _processedEventIds;
  }

  Map<String, DateTime> get _activeLastTransactionByValue {
    return kDebugMode ? _globalLastTransactionByValue : _lastTransactionByValue;
  }

  int sendHeartBeatTimer = 45; // Timer para enviar heartbeat
  int supabaseFunctionGlobalTimeout = 30; // Timeout global para funções do Supabase

  Future<bool> initializeHomeData() async {
    try {
      // Initialize Device Info Service first
      if (!GetIt.I.isRegistered<DeviceInfoService>()) {
        GetIt.I.registerSingleton<DeviceInfoService>(DeviceInfoService());
      }
      await GetIt.I<DeviceInfoService>().initialize();
      GetIt.I<LoggerService>().i("DeviceInfoService initialized");

      // Inicia o listener do bluetooth
      if (GetIt.I.isRegistered<BluetoothService>()) {
        await GetIt.I<BluetoothService>().initialize();
        //* Inicia o listening do bluetooth
        startListeningToBluetooth();
        GetIt.I<LoggerService>().i("Bluetooth initialized");
      } else {
        GetIt.I<LoggerService>().w("BluetoothService not registered, skipping initialization");
      }

      Map<String, dynamic> defaultInicializationSettingsOptions = jsonDecode(await SecureStorageKey.main.instance.read(key: 'default_initialization_settings') as String);
      defaultInicializationSettings = DefaultInitializationSettings.fromJson(defaultInicializationSettingsOptions);
      GetIt.I<LoggerService>().d("Default initialization settings: ${jsonEncode(defaultInicializationSettings)}");

      Map<String, dynamic> timeoutList = jsonDecode(await SecureStorageKey.main.instance.read(key: 'counter_options') as String);
      final timeoutSettings = CounterOptions.fromJson(timeoutList);
      sendHeartBeatTimer = timeoutSettings.sendHeartBeatTimer ?? 45; // Default to 45 seconds if not set
      supabaseFunctionGlobalTimeout = timeoutSettings.supabaseFunctionGlobalTimeout ?? 30; // Default to 30 seconds if not set

      Map<String, dynamic> supportInfos = jsonDecode(await SecureStorageKey.main.instance.read(key: 'support_information') as String);
      supportInfo = SupportInformation.fromJson(supportInfos);
      GetIt.I<LoggerService>().d("Support infos: ${supportInfo.toJson()}");

      Map<String, dynamic> paymentTypes = jsonDecode(await SecureStorageKey.main.instance.read(key: 'payments_types') as String);
      paymentsTypesEnabled = PaymentsTypes.fromJson(paymentTypes);
      homePaymentTypesEnabledTitle.value = paymentsTypesEnabled.title!;
      GetIt.I<LoggerService>().d("Payment types title: ${homePaymentTypesEnabledTitle.value}");
      GetIt.I<LoggerService>().d("Payment types enabled: ${paymentsTypesEnabled.toString()}");

      Map<String, dynamic> operationOptionsData = jsonDecode(await SecureStorageKey.main.instance.read(key: 'operation_options') as String);
      operationOptions = OperationOptions.fromJson(operationOptionsData);
      GetIt.I<LoggerService>().d("Operation options: ${operationOptions.toString()}");

      Map<String, dynamic> priceList = jsonDecode(await SecureStorageKey.main.instance.read(key: 'price_options') as String);
      priceOptionsList = PriceOptions.fromJson(priceList);
      GetIt.I<LoggerService>().d("Price options: ${priceOptionsList.toJson()}");

      // * Sentinela Spolus app version info
      Map<String, String> appInfos = await Utils.getAppVersionInfo();
      sentinelaSpolusAppInfos = SentinelaSpolusAppInfosModel.fromJson(appInfos);

      // * Listen to internet connection changes
      GetIt.I<InternetCheckConnectionService>().onConnectionChanged.listen((isConnected) {
        hasInternetConnection.value = isConnected;
        if (isConnected) {
          GetIt.I<LoggerService>().i("Internet connection restored");
        } else {
          GetIt.I<LoggerService>().w("Internet connection lost");
        }
      });

      // * Aguardando o pagamento handler estar pronto se estiver registrado
      if (GetIt.I.isRegistered<PaymentHandlerController>()) {
        await GetIt.I<PaymentHandlerController>().ready;
        GetIt.I<LoggerService>().i("Payment handler is ready");
      } else {
        GetIt.I<LoggerService>().w("Payment handler not registered, skipping readiness check");
      }

      // * Somente usa o agendamento para o modo de operação automatizado se estiver globalmente habilitado
      if (defaultInicializationSettings.activateMachineOperationScheduling == true) {
        workingMachineTimerWatchdog();
      }

      startTransactionsEventPendingSyncTimer();
      startProductsEventPendingSyncTimer();
      startCommandsEventPendingSyncTimer();

      sendHeartbeat();

      // Start periodic cleanup of processed event IDs (every hour)
      _eventIdCleanupTimer = Timer.periodic(Duration(hours: 1), (timer) {
        if (_activeProcessedEventIds.length > 1000) {
          _activeProcessedEventIds.clear();
          GetIt.I<LoggerService>().i("Limpeza de IDs de eventos processados realizada");
        }
        // Clean up old transaction tracking (older than 1 hour)
        final now = DateTime.now();
        _activeLastTransactionByValue.removeWhere((key, timestamp) => now.difference(timestamp).inHours >= 1);
      });

      GetIt.I<LoggerService>().i("Home Screen is ready");

      return true;
    } catch (e) {
      GetIt.I<LoggerService>().e("Error initializing home controller: $e");
      return false;
    }
  }

  void startListeningToBluetooth() {
    // Cancel existing subscription to prevent duplicates
    _bluetoothSubscription?.cancel();

    GetIt.I<LoggerService>().i("Iniciando escuta do Bluetooth");
    _bluetoothSubscription = GetIt.I<BluetoothService>().bluetoothStream.listen((bluetoothData) {
      if (bluetoothData.deviceStatus == 2) {
        sentinelaGlobalStatusColor.value = Colors.green;
        if (bluetoothData.fsmData.isNotEmpty) {
          interfaceFSM.value = bluetoothData.fsmData;
          // Set W status (bluetooth connection status)
          // Utils.updateWStatus(fsm: interfaceFSM.value, newStatus: "1");
          labelsFSM.value = Utils.processFSMStatus(fsm: interfaceFSM.value);
          if (labelsFSM.value['M'] == "DESLIGADA") {
            GetIt.I<LoggerService>().w("Máquina está desligada, não é possível operar");
            sentinelaGlobalStatusColor.value = Colors.orange;
            machineIsTurnnedOn.value = false;
          } else if (labelsFSM.value['M'] == "LIGADA") {
            GetIt.I<LoggerService>().i("Máquina está ligada, pode operar");
            machineIsTurnnedOn.value = true;
          } else {
            GetIt.I<LoggerService>().w("Estado da máquina desconhecido: ${labelsFSM.value['M']}");
            machineIsTurnnedOn.value = true; // assume que está ativa, mas pode ser ajustado conforme necessidade
          }
        }
      } else if (bluetoothData.deviceStatus != 2) {
        // Set W status (bluetooth connection status)
        // Utils.updateWStatus(fsm: interfaceFSM.value, newStatus: "2");
        labelsFSM.value = Utils.processFSMStatus(fsm: interfaceFSM.value);
        GetIt.I<LoggerService>().w("Dispositivo Bluetooth desconectado ou status inválido: ${bluetoothData.deviceStatus}");
        sentinelaGlobalStatusColor.value = Colors.red;
      }

      // When banknote is inserted
      if (bluetoothData.transactionBanknoteResult != null) {
        final banknoteData = bluetoothData.transactionBanknoteResult!;
        // Clear the state immediately to prevent reprocessing
        GetIt.I<BluetoothService>().bluetoothState = GetIt.I<BluetoothService>().bluetoothState.copyWith(transactionBanknoteResult: null);
        // Process with the captured data
        processBanknoteInserted(banknoteData);
      }
      // When coin is inserted
      if (bluetoothData.transactionCoinResult != null) {
        final coinData = bluetoothData.transactionCoinResult!;
        GetIt.I<LoggerService>().i("Evento de moeda inserida recebido: $coinData");
        // Clear the state immediately to prevent reprocessing
        GetIt.I<BluetoothService>().bluetoothState = GetIt.I<BluetoothService>().bluetoothState.copyWith(transactionCoinResult: null);
        // Process with the captured data
        processCoinInserted(coinData);
      }
      // When product is collected
      if (bluetoothData.productCollected != null) {
        final productData = bluetoothData.productCollected!;
        GetIt.I<LoggerService>().i("Evento de produto recebido: $productData");
        // Clear the state immediately to prevent reprocessing
        GetIt.I<BluetoothService>().bluetoothState = GetIt.I<BluetoothService>().bluetoothState.copyWith(productCollected: null);
        // Process with the captured data
        processProductEvent(productData);
      }

      // Whem TEF is received
      if (bluetoothData.transactionTEFResult != null) {
        final tefResult = bluetoothData.transactionTEFResult!;
        GetIt.I<LoggerService>().d("Last TEF result: $tefResult");

        // Clear state first to prevent reprocessing
        GetIt.I<BluetoothService>().bluetoothState = GetIt.I<BluetoothService>().bluetoothState.copyWith(transactionTEFResult: null);

        // Then notify listeners
        if (onTefResponseListener != null) {
          final listener = onTefResponseListener;
          onTefResponseListener = null; // Clear before calling to prevent re-entry
          listener!(tefResult);
        } else {
          GetIt.I<LoggerService>().w("Resposta TEF recebida mas ninguém esperando.");
          // TODO: Aqui poderia ser adicionado um callback para o app, mas não é necessário por enquanto
        }
      }

      // Whem command is received
      if (bluetoothData.commandResult != null) {
        GetIt.I<LoggerService>().d("Última resposta recebida: ${bluetoothData.commandResult!}");
        // 👂 Se alguém estiver esperando, dispara
        if (onCommandResponseListener != null) {
          onCommandResponseListener!(bluetoothData.commandResult!);
          onCommandResponseListener = null; // limpa para não disparar de novo
        } else {
          GetIt.I<LoggerService>().w("Resposta do comando recebida mas ninguém esperando.");
          // TODO: Aqui poderia ser adicionado um callback para o app, mas não é necessário por enquanto
        }

        if (_waitingCommand != null) {
          final response = bluetoothData.commandResult!;

          // Cancela timeout antes de chamar o callback
          _responseTimeout?.cancel();
          _responseTimeout = null;

          final callback = _onResponseReceived;

          // Limpa estado antes de chamar o callback (para evitar reentrância ou duplicidade)
          _waitingCommand = null;
          _onResponseReceived = null;
          _onTimeout = null;

          GetIt.I<LoggerService>().i("✅ Chamando callback de sucesso com resposta: $response");
          callback?.call(response);
        }
      }
    });
  }

  void sendHeartbeat() async {
    sendHeartbeatTimer = Timer.periodic(Duration(seconds: sendHeartBeatTimer), (timer) async {
      try {
        bool isConnected = GetIt.I<PaymentHandlerController>().posAuthenticationStatus.value;

        // Get device diagnostic data
        String batteryInfo = "";
        String rssiInfo = "";

        if (GetIt.I.isRegistered<DeviceInfoService>()) {
          final deviceInfo = GetIt.I<DeviceInfoService>();
          batteryInfo = deviceInfo.batteryStatusForFSM;
          rssiInfo = deviceInfo.bluetoothRssiForFSM;

          GetIt.I<LoggerService>().d("Battery Info: ${deviceInfo.getBatteryInfo()}");
          GetIt.I<LoggerService>().d("Bluetooth Info: ${deviceInfo.getBluetoothInfo()}");
        }

        final response = await GetIt.I<ApiService>().supabase.functions
            .invoke(
              'sentinela-heartbeat',
              body: {
                'client': await SecureStorageKey.main.instance.read(key: 'client_uuid'),
                'machine_id': await SecureStorageKey.main.instance.read(key: 'machine_id'),
                'fsm_data': interfaceFSM.value,
                'pinpad_authenticated': isConnected,
                'device_battery_level': batteryInfo.isNotEmpty ? batteryInfo.substring(0, 3) : "000",
                'device_battery_state': batteryInfo.isNotEmpty ? batteryInfo.substring(3) : "U",
                'bluetooth_rssi': rssiInfo.isNotEmpty ? rssiInfo : "000",
              },
            )
            .timeout(Duration(seconds: supabaseFunctionGlobalTimeout));
        GetIt.I<LoggerService>().d("Heartbeat FSM payload: ${interfaceFSM.value}");

        if (response.status == 200) {
          GetIt.I<LoggerService>().i("Heartbeat enviado com sucesso: ${response.data}");
          final heartbeatResponse = HeartBeatResponseModel.fromJson(response.data);
          isBlocked.value = heartbeatResponse.isBlocked!;
          if (heartbeatResponse.commands != null && heartbeatResponse.commands!.isNotEmpty) {
            GetIt.I<LoggerService>().i("Comandos recebidos: ${heartbeatResponse.commands!.length}");
            for (var command in heartbeatResponse.commands!) {
              String commandString = command.command ?? '';
              if (commandString.isNotEmpty) {
                GetIt.I<LoggerService>().i("Processando comando remoto: $commandString");
                await processRemoteCommand(command);
              } else {
                GetIt.I<LoggerService>().w("Comando vazio recebido, ignorando.");
              }
            }
          }
        } else {
          GetIt.I<LoggerService>().e("Erro ao enviar heartbeat: ${response.status}");
        }
      } catch (e) {
        GetIt.I<LoggerService>().e("Erro ao executar heartbeat: $e");
      }
    });
  }

  void startTransactionsEventPendingSyncTimer() {
    // Se já existe um timer ativo, não cria outro
    if (_pendingTransactionSyncTimer != null && _pendingTransactionSyncTimer!.isActive) return;

    _pendingTransactionSyncTimer = Timer(_currentTransactionInterval, _syncTransactionsPendingEvents);
  }

  void startProductsEventPendingSyncTimer() {
    // Se já existe um timer ativo, não cria outro
    if (_pendingProductSyncTimer != null && _pendingProductSyncTimer!.isActive) return;

    _pendingProductSyncTimer = Timer(_currentProductInterval, _syncProductsPendingEvents);
  }

  void startCommandsEventPendingSyncTimer() {
    // Se já existe um timer ativo, não cria outro
    if (_pendingCommandSyncTimer != null && _pendingCommandSyncTimer!.isActive) return;

    _pendingCommandSyncTimer = Timer(_currentCommandInterval, _syncCommandsPendingEvents);
  }

  Future<void> _syncTransactionsPendingEvents() async {
    // Checar se esta na tela de rotina de pagamento, se estiver não procurar ou enviar transações
    if (GetIt.I<NavigationService>().isPaymentActualRoute()) {
      GetIt.I<LoggerService>().w("Tela de rotina de pagamento, não sincronizando transações.");
      _currentTransactionInterval = Duration(seconds: 10);
      _restartTransactionSyncTimer();
      return;
    }

    final List<dynamic> pendencias = await Utils.getLocalPendingEventsToSync(type: InterfaceEventTypesEnum.SALE_TRANSACTION);
    if (pendencias.isEmpty) {
      GetIt.I<LoggerService>().i("Nenhuma pendência de transação encontrada.");
    } else {
      GetIt.I<LoggerService>().i("Pendências de transação encontradas: ${jsonEncode(pendencias)}");
      // total de pendências
      GetIt.I<LoggerService>().w("Total de pendências: ${pendencias.length}");
    }

    if (pendencias.isEmpty) {
      // Se não há pendências, reseta o intervalo para o padrão e agenda próxima checagem
      _currentTransactionInterval = Duration(seconds: 10);
      _restartTransactionSyncTimer();
      return;
    }

    bool allSuccess = true;

    for (var transacao in pendencias) {
      // Pretty print JSON to avoid truncation
      String prettyJson = JsonEncoder.withIndent('  ').convert(transacao);
      logger.w("Enviando transação:\n$prettyJson");
      try {
        final response = await sendSaleTransactionsEvent(transacao);
        if (response) {
          await Utils.removePendingEventSyncedById(eventId: transacao.eventId, type: InterfaceEventTypesEnum.SALE_TRANSACTION);
        } else {
          allSuccess = false;
        }
      } catch (e) {
        GetIt.I<LoggerService>().e('Erro ao enviar transação: $e');
        allSuccess = false;
      }
    }

    if (allSuccess) {
      // Se tudo certo, reseta o intervalo
      _currentTransactionInterval = Duration(seconds: 10);
    } else {
      // Se houve erro, dobra o intervalo, mas sem ultrapassar o máximo
      _currentTransactionInterval = Duration(seconds: (_currentTransactionInterval.inSeconds * 2).clamp(10, _maxTransactionSyncInterval.inSeconds));
    }

    _restartTransactionSyncTimer();
  }

  Future<void> _syncProductsPendingEvents() async {
    final List<dynamic> pendencias = await Utils.getLocalPendingEventsToSync(type: InterfaceEventTypesEnum.PRODUCT);
    if (pendencias.isEmpty) {
      GetIt.I<LoggerService>().i("Nenhuma pendência de produto encontrada.");
    } else {
      GetIt.I<LoggerService>().i("Pendências produto encontradas: ${jsonEncode(pendencias)}");
    }

    if (pendencias.isEmpty) {
      // Se não há pendências, reseta o intervalo para o padrão e agenda próxima checagem
      _currentProductInterval = Duration(seconds: 10);
      _restartProductSyncTimer();
      return;
    }

    bool allSuccess = true;

    for (var produto in pendencias) {
      try {
        final response = await sendSaleProductEvent(produto);
        if (response) {
          await Utils.removePendingEventSyncedById(eventId: produto.eventId, type: InterfaceEventTypesEnum.PRODUCT);
        } else {
          allSuccess = false;
        }
      } catch (e) {
        GetIt.I<LoggerService>().e('Erro ao enviar produto: $e');
        allSuccess = false;
      }
    }

    if (allSuccess) {
      // Se tudo certo, reseta o intervalo
      _currentProductInterval = Duration(seconds: 10);
    } else {
      // Se houve erro, dobra o intervalo, mas sem ultrapassar o máximo
      _currentProductInterval = Duration(seconds: (_currentProductInterval.inSeconds * 2).clamp(10, _maxProductSyncInterval.inSeconds));
    }

    _restartProductSyncTimer();
  }

  Future<void> _syncCommandsPendingEvents() async {
    GetIt.I<LoggerService>().i("Iniciando sincronização de comandos pendentes...");
    final List<dynamic> pendencias = await Utils.getLocalPendingEventsToSync(type: InterfaceEventTypesEnum.COMMAND);
    if (pendencias.isEmpty) {
      GetIt.I<LoggerService>().i("Nenhuma pendência de comando encontrada.");
    } else {
      GetIt.I<LoggerService>().i("Pendências de comando encontradas: ${jsonEncode(pendencias)}");
    }

    if (pendencias.isEmpty) {
      // Se não há pendências, reseta o intervalo para o padrão e agenda próxima checagem
      _currentCommandInterval = Duration(seconds: 10);
      _restartCommandSyncTimer();
      return;
    }

    bool allSuccess = true;

    for (var comando in pendencias) {
      try {
        final response = await sendCommandEvent(comando);
        if (response) {
          await Utils.removePendingEventSyncedById(eventId: comando.eventId, type: InterfaceEventTypesEnum.COMMAND);
        } else {
          allSuccess = false;
        }
      } catch (e) {
        GetIt.I<LoggerService>().e('Erro ao enviar produto: $e');
        allSuccess = false;
      }
    }

    if (allSuccess) {
      // Se tudo certo, reseta o intervalo
      _currentCommandInterval = Duration(seconds: 10);
    } else {
      // Se houve erro, dobra o intervalo, mas sem ultrapassar o máximo
      _currentCommandInterval = Duration(seconds: (_currentCommandInterval.inSeconds * 2).clamp(10, _maxCommandSyncInterval.inSeconds));
    }

    _restartCommandSyncTimer();
  }

  Future<bool> sendSaleTransactionsEvent(Object body) async {
    try {
      final response = await GetIt.I<ApiService>().supabase.functions.invoke('sentinela-transaction-event', body: body).timeout(Duration(seconds: supabaseFunctionGlobalTimeout));
      GetIt.I<LoggerService>().d("Response: ${response.data}");

      if (response.status == 200) {
        final responseData = response.data as Map<String, dynamic>?;

        // Check if this is a duplicate that was already saved on server
        if (responseData?['duplicate_detected'] == true && responseData?['already_saved'] == true) {
          GetIt.I<LoggerService>().w("DUPLICATA JÁ SALVA NO SERVIDOR: ${responseData?['message']}");
          if (responseData?['existing_transaction'] != null) {
            final existing = responseData!['existing_transaction'];
            GetIt.I<LoggerService>().w("Transação existente: ID=${existing['event_id']}, Preço=${existing['price']}, Tipo=${existing['type']}, Método=${existing['method']}");
          }
          GetIt.I<LoggerService>().i("Removendo da fila local - transação já processada no servidor");
          // Return true to remove from pending queue since it's already saved on server
          return true;
        }

        GetIt.I<LoggerService>().i("Evento de transação enviado com sucesso");
        return true;
      } else if (response.status == 409) {
        // Handle legacy 409 responses (if any)
        final responseData = response.data as Map<String, dynamic>?;
        if (responseData?['duplicate_detected'] == true) {
          GetIt.I<LoggerService>().w("SERVIDOR BLOQUEOU DUPLICATA (409): ${responseData?['message']}");
          return true; // Remove from queue
        }
        GetIt.I<LoggerService>().e("Erro ao enviar evento de transação (409):\n ${response.status}");
        return false;
      } else {
        GetIt.I<LoggerService>().e("Erro ao enviar evento de transação:\n ${response.status}");
        return false;
      }
    } catch (e) {
      GetIt.I<LoggerService>().w("Object body: ${jsonEncode(body)}");
      GetIt.I<LoggerService>().e("Erro ao enviar evento de transação: $e");
      return false;
    }
  }

  Future<bool> sendSaleProductEvent(Object body) async {
    try {
      final response = await GetIt.I<ApiService>().supabase.functions.invoke('sentinela-product-event', body: body).timeout(Duration(seconds: supabaseFunctionGlobalTimeout));
      if (response.status == 200) {
        GetIt.I<LoggerService>().i("Evento de produto enviado com sucesso");
        return true;
      } else {
        GetIt.I<LoggerService>().e("Erro ao enviar evento de produto:\n ${response.status}");
        return false;
      }
    } catch (e) {
      GetIt.I<LoggerService>().e("Erro ao enviar evento de produto: $e");
      return false;
    }
  }

  Future<bool> sendCommandEvent(Object body) async {
    GetIt.I<LoggerService>().d("Enviando evento de comando: ${jsonEncode(body)}}");
    try {
      final response = await GetIt.I<ApiService>().supabase.functions.invoke('sentinela-command-event', body: body).timeout(Duration(seconds: supabaseFunctionGlobalTimeout));
      if (response.status == 200) {
        GetIt.I<LoggerService>().i("Evento de comando enviado com sucesso");
        return true;
      } else {
        GetIt.I<LoggerService>().e("Erro ao enviar evento de comando:\n ${response.status}");
        return false;
      }
    } catch (e) {
      GetIt.I<LoggerService>().e("Erro ao enviar evento de comando: $e");
      return false;
    }
  }

  void sendCommandToInterfaceAndWaitResponse(String commandToSend, {required void Function(String response) onSuccess, void Function()? onTimeout}) {
    // Cancela qualquer operação pendente
    _responseTimeout?.cancel();
    _waitingCommand = commandToSend;
    _onResponseReceived = onSuccess;
    _onTimeout = onTimeout;

    GetIt.I<LoggerService>().i("Comando enviado: $commandToSend");
    GetIt.I<BluetoothService>().writeToInterface(commandToSend);

    // Configura timeout de 45 segundos // TODO: Deixar configurável o timeout?
    _responseTimeout = Timer(const Duration(seconds: 45), () {
      if (_waitingCommand != null) {
        GetIt.I<LoggerService>().w("⏰ Timeout esperando resposta para $_waitingCommand");

        // Limpa estado interno
        _waitingCommand = null;
        final timeoutCallback = _onTimeout;
        _onTimeout = null;
        _onResponseReceived = null;
        _responseTimeout = null;

        timeoutCallback?.call();
      }
    });
  }

  Future<void> processRemoteCommand(Commands remoteCommand) async {
    // POS local commands
    if (remoteCommand.type == "POS") {
      GetIt.I<LoggerService>().w("Comando local recebido: ${remoteCommand.command}");
      if (remoteCommand.command == "POS-RESTART") {
        // Reinicia o POS
        processCommandEvent(commandData: remoteCommand, executed: true, responseFromInterface: "");
        await PaymentSimulator.instance().payment.rebootDevice();
        GetIt.I<LoggerService>().i("Reiniciando o POS");
      } else if (remoteCommand.command == "POS-ERASE_MAIN_STORAGE") {
        // Apaga as configurações do Sentinela
        Utils.clearMainStorage();
        await PaymentSimulator.instance().payment.rebootDevice();
        GetIt.I<LoggerService>().i("Reiniciando o POS");
      } else if (remoteCommand.command == "POS-ERASE_TRANSACTION_STORAGE") {
        // Apaga as transações não sincronizadas do Sentinela
        Utils.clearTransactionStorage();
        processCommandEvent(commandData: remoteCommand, executed: true, responseFromInterface: "");
        await PaymentSimulator.instance().payment.rebootDevice();
        GetIt.I<LoggerService>().i("Reiniciando o POS");
      } else if (remoteCommand.command == "POS-ERASE_PRODUCT_STORAGE") {
        // Apaga os produtos não sinronizados do Sentinela
        Utils.clearProductStorage();
        processCommandEvent(commandData: remoteCommand, executed: true, responseFromInterface: "");
        await PaymentSimulator.instance().payment.rebootDevice();
        GetIt.I<LoggerService>().i("Reiniciando o POS");
      } else if (remoteCommand.command == "POS-ERASE_COMMAND_STORAGE") {
        // Apaga os produtos não sinronizados do Sentinela
        Utils.clearCommandStorage();
        processCommandEvent(commandData: remoteCommand, executed: true, responseFromInterface: "");
        await PaymentSimulator.instance().payment.rebootDevice();
        GetIt.I<LoggerService>().i("Reiniciando o POS");
      }
    } else if (remoteCommand.type == "CMD") {
      Future.delayed(const Duration(seconds: 1));
      GetIt.I<LoggerService>().i("Comando local recebido: ${remoteCommand.command}");
      // Comandos remotos que não retornam resposta
      if (remoteCommand.command == "CMD-REBOOT_ESP") {
        processCommandEvent(commandData: remoteCommand, executed: true, responseFromInterface: "");
        GetIt.I<BluetoothService>().writeToInterface(remoteCommand.command!);
        GetIt.I<LoggerService>().i("Reinicia ESP32");
        return;
      } else if (remoteCommand.command == "CMD-MACHINE_RESTART" ||
          remoteCommand.command == "CMD-MACHINE_ON" ||
          remoteCommand.command == "CMD-MACHINE_OFF" ||
          remoteCommand.command == "CMD-COLLECTOR_ON" ||
          remoteCommand.command == "CMD-COLLECTOR_OFF" ||
          remoteCommand.command == "CMD-COLLECTOR_ALWAYS_ON" ||
          remoteCommand.command == "CMD-COLLECTOR_ALWAYS_OFF" ||
          remoteCommand.command == "CMD-INSERT_REMOTE_CREDIT" ||
          remoteCommand.command == "CMD-MACHINE_ALWAYS_ON" ||
          remoteCommand.command == "CMD-MACHINE_ALWAYS_OFF" ||
          remoteCommand.command == "CMD-CLEAR_STORAGE_EVENTS" ||
          remoteCommand.command == "CMD-SENTINELA_FACTORY_RESET" ||
          remoteCommand.command == "CMD-SYS_INFO") {
        String commandToSendWithEventID = "";
        if (remoteCommand.command == "CMD-INSERT_REMOTE_CREDIT") {
          commandToSendWithEventID = "${remoteCommand.command!}=${remoteCommand.remoteCreditValue!}-${remoteCommand.eventId!.replaceAll("-", "")}";
        } else {
          commandToSendWithEventID = "${remoteCommand.command!}-${remoteCommand.eventId!.replaceAll("-", "")}";
        }
        GetIt.I<LoggerService>().i("Comando remoto formatado enviado: $commandToSendWithEventID");

        sendCommandToInterfaceAndWaitResponse(
          commandToSendWithEventID,
          onSuccess: (interfaceResponse) {
            GetIt.I<LoggerService>().w("Resposta recebida: $interfaceResponse, comando enviado: $commandToSendWithEventID");

            if (interfaceResponse.contains(commandToSendWithEventID)) {
              processCommandEvent(commandData: remoteCommand, executed: true, responseFromInterface: interfaceResponse);
            } else {
              GetIt.I<LoggerService>().w("Resposta não corresponde ao comando enviado. Ignorada.");
              if (remoteCommand.command == "CMD-SYS_INFO") {
                // Se o comando for SYS_INFO, processa a resposta
                processEspSysInfoCommandEvent(commandData: remoteCommand, executed: true, responseFromInterface: interfaceResponse);
              }
            }
          },
          onTimeout: () {
            GetIt.I<LoggerService>().w("Timeout esperando resposta para ${remoteCommand.command}");
          },
        );
      } else {
        GetIt.I<LoggerService>().i("Comando não encontrado");
      }
    }
  }

  Future<void> processBanknoteInserted(String command) async {
    final eventId = Utils.extractOnlyEventId(command);

    GetIt.I<LoggerService>().w("PROCESSANDO NOTA: $command");
    GetIt.I<LoggerService>().w("Event ID extraído: $eventId");

    // Primary check: event ID based duplicate prevention
    if (eventId != null && _activeProcessedEventIds.contains(eventId)) {
      GetIt.I<LoggerService>().w("NOTA DUPLICADA - Evento de nota já processado (event ID): $eventId - COMANDO: $command");
      return;
    }

    // Secondary check: exact command string duplicate prevention
    String commandKey = "CMD_$command";
    if (_activeProcessedEventIds.contains(commandKey)) {
      GetIt.I<LoggerService>().w("NOTA DUPLICADA - Comando de nota exato já processado: $command - IGNORANDO");
      return;
    }

    // Extract transaction value for additional duplicate checking
    double price = double.parse(Utils.translateValueReceivedFromInterface(value: command));
    String transactionKey = "BANKNOTE_$price";
    DateTime now = DateTime.now();

    GetIt.I<LoggerService>().w("Valor da nota: R\$${price.toStringAsFixed(2)} - Key: $transactionKey");

    // Tertiary check: same value transaction was processed recently (within 3 seconds)
    if (_activeLastTransactionByValue.containsKey(transactionKey)) {
      final lastTime = _activeLastTransactionByValue[transactionKey]!;
      final timeDiff = now.difference(lastTime).inSeconds;
      if (timeDiff < 3) {
        GetIt.I<LoggerService>().w("NOTA DUPLICADA - Transação de nota duplicada detectada: R\$${price.toStringAsFixed(2)} processada há ${timeDiff}s - IGNORANDO");
        return;
      }
    }

    GetIt.I<LoggerService>().w("NOTA APROVADA - Processando transação: R\$${price.toStringAsFixed(2)}");

    // Add to processed sets and update last transaction time
    if (eventId != null) {
      _activeProcessedEventIds.add(eventId);
    }
    _activeProcessedEventIds.add(commandKey);
    _activeLastTransactionByValue[transactionKey] = now;
    SaleTransactionModel notePaymentData = SaleTransactionModel(
      client: await SecureStorageKey.main.instance.read(key: 'client_uuid') ?? "",
      machine: await SecureStorageKey.main.instance.read(key: 'machine_id') ?? "",
      price: price,
      product: Utils.calcularCreditos(price, priceOptionsList).toString(),
      type: "BANKNOTE",
      method: "PHYSICAL",
      productDeliveredStatus: "DELIVERED",
      transactionStatusDescription: command,
      transactionStatus: "PAID",
      receipt: {},
      eventId: Utils.extractOnlyEventId(command)!,
      interfaceEpochTimestamp: Utils.epochToUTCDateTime(int.parse(Utils.extractOnlyEpochWithoutStatus(command)!)),
      timestamp: Utils.getUTCDateTimeFromPOS(),
      saleStatus: true,
    );

    if (await Utils.addEventPendingToSync(notePaymentData)) {
      GetIt.I<LoggerService>().i("Evento de nota adicionada com sucesso");
    } else {
      GetIt.I<LoggerService>().e("Erro ao adicionar transação pendente");
    }
    GetIt.I<LoggerService>().i("Adicionando transação pendente para sincronização:\n ${jsonEncode(notePaymentData)}");
  }

  Future<void> processCoinInserted(String command) async {
    final eventId = Utils.extractOnlyEventId(command);

    GetIt.I<LoggerService>().w("PROCESSANDO MOEDA: $command");
    GetIt.I<LoggerService>().w("Event ID extraído: $eventId");

    // Primary check: event ID based duplicate prevention
    if (eventId != null && _activeProcessedEventIds.contains(eventId)) {
      GetIt.I<LoggerService>().w("MOEDA DUPLICADA - Evento de moeda já processado (event ID): $eventId - COMANDO: $command");
      return;
    }

    // Secondary check: exact command string duplicate prevention
    String commandKey = "CMD_$command";
    if (_activeProcessedEventIds.contains(commandKey)) {
      GetIt.I<LoggerService>().w("MOEDA DUPLICADA - Comando de moeda exato já processado: $command - IGNORANDO");
      return;
    }

    // Extract transaction value for additional duplicate checking
    double price = double.parse(Utils.translateValueReceivedFromInterface(value: command));
    String transactionKey = "COIN_$price";
    DateTime now = DateTime.now();

    GetIt.I<LoggerService>().w("Valor da moeda: R\$${price.toStringAsFixed(2)} - Key: $transactionKey");

    // Tertiary check: same value transaction was processed recently (within 3 seconds)
    if (_activeLastTransactionByValue.containsKey(transactionKey)) {
      final lastTime = _activeLastTransactionByValue[transactionKey]!;
      final timeDiff = now.difference(lastTime).inSeconds;
      if (timeDiff < 3) {
        GetIt.I<LoggerService>().w("MOEDA DUPLICADA - Transação de moeda duplicada detectada: R\$${price.toStringAsFixed(2)} processada há ${timeDiff}s - IGNORANDO");
        return;
      }
    }

    GetIt.I<LoggerService>().w("MOEDA APROVADA - Processando transação: R\$${price.toStringAsFixed(2)}");

    // Add to processed sets and update last transaction time
    if (eventId != null) {
      _activeProcessedEventIds.add(eventId);
    }
    _activeProcessedEventIds.add(commandKey);
    _activeLastTransactionByValue[transactionKey] = now;

    SaleTransactionModel notePaymentData = SaleTransactionModel(
      client: await SecureStorageKey.main.instance.read(key: 'client_uuid') ?? "",
      machine: await SecureStorageKey.main.instance.read(key: 'machine_id') ?? "",
      price: double.parse(Utils.translateValueReceivedFromInterface(value: command)),
      product: buyData.value.credit,
      type: "COIN",
      method: "PHYSICAL",
      productDeliveredStatus: "DELIVERED",
      transactionStatusDescription: command,
      transactionStatus: "PAID",
      receipt: {},
      eventId: Utils.extractOnlyEventId(command)!,
      interfaceEpochTimestamp: Utils.epochToUTCDateTime(int.parse(Utils.extractOnlyEpochWithoutStatus(command)!)),
      timestamp: Utils.getUTCDateTimeFromPOS(),
      saleStatus: true,
    );

    if (await Utils.addEventPendingToSync(notePaymentData)) {
      GetIt.I<LoggerService>().i("Evento de moeda adicionada com sucesso");
    } else {
      GetIt.I<LoggerService>().e("Erro ao adicionar transação pendente");
    }
    GetIt.I<LoggerService>().i("Adicionando transação pendente para sincronização:\n ${jsonEncode(notePaymentData)}");
  }

  Future<void> processProductEvent(String command) async {
    final eventId = Utils.extractOnlyEventId(command);

    // Check if already processed
    if (eventId != null && _activeProcessedEventIds.contains(eventId)) {
      GetIt.I<LoggerService>().w("Evento de produto já processado: $eventId");
      return;
    }

    GetIt.I<LoggerService>().i("Evento de produto recebido: $command");

    // Add to processed set
    if (eventId != null) {
      _activeProcessedEventIds.add(eventId);
    }

    ProductEventModel productEventtData = ProductEventModel(
      client: await SecureStorageKey.main.instance.read(key: 'client_uuid') ?? "",
      machine: await SecureStorageKey.main.instance.read(key: 'machine_id') ?? "",
      eventId: Utils.extractOnlyEventId(command)!,
      interfaceEpochTimestamp: Utils.epochToUTCDateTime(int.parse(Utils.extractOnlyEpochWithoutStatus(command)!)),
      timestamp: Utils.getUTCDateTimeFromPOS(),
    );

    // Salva o evento pendente para sincronização
    if (await Utils.addEventPendingToSync(productEventtData)) {
      GetIt.I<LoggerService>().i("Evento de produto adicionado com sucesso");
    } else {
      GetIt.I<LoggerService>().e("Erro ao adicionar evento pendente");
    }
    GetIt.I<LoggerService>().i("Adicionando evento pendente para sincronização:\n ${jsonEncode(productEventtData)}");
  }

  Future<void> processCommandEvent({required Commands commandData, required bool executed, required String responseFromInterface}) async {
    GetIt.I<LoggerService>().i("Evento de comando recebido: ${commandData.command}");
    String extractEpochFromInterfaceResponse = "";
    if (responseFromInterface.isNotEmpty) {
      extractEpochFromInterfaceResponse = responseFromInterface.split("-").last.split(":").first.trim();
      GetIt.I<LoggerService>().i("Extraindo epoch do comando: $extractEpochFromInterfaceResponse");
    } else {
      GetIt.I<LoggerService>().w("Resposta da interface está vazia, usando hora atual");
    }

    CommandEventModel commandEventData = CommandEventModel(
      client: await SecureStorageKey.main.instance.read(key: 'client_uuid') ?? "",
      machine: await SecureStorageKey.main.instance.read(key: 'machine_id') ?? "",
      commandDescription: commandData.command!,
      interfaceResponse: responseFromInterface,
      interfaceEpochTimestamp: responseFromInterface.isNotEmpty ? Utils.epochToUTCDateTime(int.parse(extractEpochFromInterfaceResponse)) : Utils.getUTCDateTimeFromPOS(),
      executed: executed,
      eventId: commandData.eventId!,
    );

    // Salva o evento pendente para sincronização
    if (await Utils.addEventPendingToSync(commandEventData)) {
      GetIt.I<LoggerService>().i("Evento de comando adicionado com sucesso");
      GetIt.I<BluetoothService>().bluetoothState = GetIt.I<BluetoothService>().bluetoothState.copyWith(commandResult: null);
    } else {
      GetIt.I<LoggerService>().e("Erro ao adicionar evento pendente");
    }
  }

  Future<void> processEspSysInfoCommandEvent({required Commands commandData, required bool executed, required String responseFromInterface}) async {
    GetIt.I<LoggerService>().i("Evento de comando recebido: ${commandData.command}");

    CommandEventModel commandEventData = CommandEventModel(
      client: await SecureStorageKey.main.instance.read(key: 'client_uuid') ?? "",
      machine: await SecureStorageKey.main.instance.read(key: 'machine_id') ?? "",
      commandDescription: commandData.command!,
      interfaceResponse: responseFromInterface,
      interfaceEpochTimestamp: Utils.epochToUTCDateTime(int.parse(Utils.extractOnlyEpochWithoutStatus(responseFromInterface)!)),
      executed: executed,
      eventId: commandData.eventId!,
    );

    // Salva o evento pendente para sincronização
    if (await Utils.addEventPendingToSync(commandEventData)) {
      GetIt.I<LoggerService>().i("Evento de comando adicionado com sucesso");
      GetIt.I<BluetoothService>().bluetoothState = GetIt.I<BluetoothService>().bluetoothState.copyWith(commandResult: null);
    } else {
      GetIt.I<LoggerService>().e("Erro ao adicionar evento pendente");
    }
  }

  void workingMachineTimerWatchdog() {
    workingTimerWatchdog = Timer.periodic(const Duration(minutes: 1), (timer) async {
      final bluetoothState = GetIt.I<BluetoothService>().bluetoothState;

      if (bluetoothState.deviceStatus != 2) {
        // Set W status (bluetooth connection status)
        labelsFSM.value['W'] = "DESCONECTADO";
        GetIt.I<LoggerService>().e("❌ Interface desconectada, não é possível operar");
        return;
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final startParts = operationOptions.workingHoursStart.toString().split(":");
      final endParts = operationOptions.workingHoursEnd.toString().split(":");

      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);

      DateTime startTime = DateTime(today.year, today.month, today.day, startHour, startMinute);
      DateTime endTime = DateTime(today.year, today.month, today.day, endHour, endMinute);

      // Se o horário de fim for antes do de início, soma 1 dia no fim
      if (endTime.isBefore(startTime)) {
        endTime = endTime.add(const Duration(days: 1));
      }

      final storage = SecureStorageKey.main.instance;
      final turnedOnFlag = (await storage.read(key: 'machine_was_turned_on_by_schedule')) ?? "false";
      final turnedOffFlag = (await storage.read(key: 'machine_was_turned_off_by_schedule')) ?? "false";

      GetIt.I<LoggerService>().w("🕒 Agora: ${now.hour}:${now.minute.toString().padLeft(2, '0')}");
      GetIt.I<LoggerService>().w("🟢 Início: ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}");
      GetIt.I<LoggerService>().w("🔴 Fim: ${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}");

      bool isWithinWorkingHours;
      if (endTime.isAfter(startTime)) {
        // Intervalo no mesmo dia
        isWithinWorkingHours = now.isAfter(startTime) && now.isBefore(endTime);
      } else {
        // Intervalo que cruza a meia-noite
        isWithinWorkingHours = now.isAfter(startTime) || now.isBefore(endTime);
      }
      final isOutsideWorkingHours = !isWithinWorkingHours;

      // Ligar se está dentro do intervalo e ainda não ligou
      if (isWithinWorkingHours && turnedOnFlag != "true") {
        GetIt.I<LoggerService>().w("🚀 Ligando máquina (horário de trabalho)");

        sendCommandToInterfaceAndWaitResponse(
          "CMD-MACHINE_ON",
          onSuccess: (response) async {
            GetIt.I<LoggerService>().i("✅ Máquina ligada: $response");
            await storage.write(key: 'machine_was_turned_on_by_schedule', value: "true");
            await storage.write(key: 'machine_was_turned_off_by_schedule', value: "false");
          },
          onTimeout: () {
            GetIt.I<LoggerService>().e("⏱️ Timeout ao tentar ligar a máquina");
          },
        );
      }

      // Desligar se está fora do horário e ainda não desligou
      if (isOutsideWorkingHours && turnedOffFlag != "true") {
        GetIt.I<LoggerService>().w("⛔ Desligando máquina (fim do turno)");

        sendCommandToInterfaceAndWaitResponse(
          "CMD-MACHINE_OFF",
          onSuccess: (response) async {
            GetIt.I<LoggerService>().i("✅ Máquina desligada: $response");
            await storage.write(key: 'machine_was_turned_off_by_schedule', value: "true");
            await storage.write(key: 'machine_was_turned_on_by_schedule', value: "false");
          },
          onTimeout: () {
            GetIt.I<LoggerService>().e("⏱️ Timeout ao tentar desligar a máquina");
          },
        );
      }
    });
  }

  void _restartTransactionSyncTimer() {
    _pendingTransactionSyncTimer?.cancel();
    _pendingTransactionSyncTimer = Timer(_currentTransactionInterval, _syncTransactionsPendingEvents);
  }

  void stopPendingTransactionSyncTimer() {
    _pendingTransactionSyncTimer?.cancel();
    _pendingTransactionSyncTimer = null;
  }

  void _restartProductSyncTimer() {
    _pendingProductSyncTimer?.cancel();
    _pendingProductSyncTimer = Timer(_currentProductInterval, _syncProductsPendingEvents);
  }

  void stopPendingProductSyncTimer() {
    _pendingProductSyncTimer?.cancel();
    _pendingProductSyncTimer = null;
  }

  void _restartCommandSyncTimer() {
    _pendingCommandSyncTimer?.cancel();
    _pendingCommandSyncTimer = Timer(_currentCommandInterval, _syncCommandsPendingEvents);
  }

  void stopPendingCommandSyncTimer() {
    _pendingCommandSyncTimer?.cancel();
    _pendingCommandSyncTimer = null;
  }

  void disposeHomeController() {
    buyData.dispose();
    homePaymentTypesEnabledTitle.dispose();
    machineIsTurnnedOn.dispose();
    sendHeartbeatTimer?.cancel();
    interfaceFSM.dispose();
    GetIt.I<BluetoothService>().disposeBluetoothService();
    GetIt.I<PaymentHandlerController>().disposePaymentHandlerController();

    // Dispose DeviceInfoService
    if (GetIt.I.isRegistered<DeviceInfoService>()) {
      GetIt.I<DeviceInfoService>().dispose();
    }

    stopPendingTransactionSyncTimer();
    stopPendingProductSyncTimer();
    stopPendingCommandSyncTimer();
    sendHeartbeatTimer?.cancel();
    sendHeartbeatTimer = null;
    _pendingTransactionSyncTimer?.cancel();
    _pendingTransactionSyncTimer = null;
    _responseTimeout?.cancel();
    _responseTimeout = null;
    _waitingCommand = null;
    _onResponseReceived = null;
    _onTimeout = null;

    // Clean up Bluetooth subscription and duplicate prevention
    _bluetoothSubscription?.cancel();
    _bluetoothSubscription = null;
    _eventIdCleanupTimer?.cancel();
    _eventIdCleanupTimer = null;

    // Clear both instance and static collections
    _processedEventIds.clear();
    _lastTransactionByValue.clear();
    if (kDebugMode) {
      _globalProcessedEventIds.clear();
      _globalLastTransactionByValue.clear();
    }
  }
}
