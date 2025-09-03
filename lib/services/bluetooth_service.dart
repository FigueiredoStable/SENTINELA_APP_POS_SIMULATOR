import 'dart:async' show StreamController, StreamSubscription, Timer;
import 'dart:convert';

import 'package:bluetooth_classic/bluetooth_classic.dart' show BluetoothClassic;
import 'package:bluetooth_classic/models/device.dart' show Device;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel, Uint8List;
import 'package:get_it/get_it.dart';
import 'package:sentinela_app_pos_simulator/models/api_initialization_global_settings_model.dart' show OperationOptions, DefaultInitializationSettings;
import 'package:sentinela_app_pos_simulator/models/bluetooth_model.dart';
import 'package:sentinela_app_pos_simulator/services/logger_service.dart';
import 'package:sentinela_app_pos_simulator/utils/secure_storage_keys.dart';
import 'package:sentinela_app_pos_simulator/utils/utils.dart';

class BluetoothService {
  final StreamController<BluetoothModel> _bluetoothController = StreamController<BluetoothModel>.broadcast(); // StreamController para notificações
  Stream<BluetoothModel> get bluetoothStream => _bluetoothController.stream; // Getter para expor o Stream
  BluetoothModel bluetoothState = BluetoothModel(
    interfaceINFO: "",
    statusMessage: "Inicializando...",
    deviceStatus: Device.disconnected,
    transactionBanknoteResult: "",
    transactionCoinResult: "",
    transactionTEFResult: "",
    commandResult: "",
    productCollected: "",
    fsmData: "",
  );

  final BluetoothClassic _bluetoothClassic = BluetoothClassic();
  static String _macAddress = "00:00:00:00:00:00"; // MAC Address do dispositivo Bluetooth
  static const platform = MethodChannel('bluetooth_pairing');
  StreamSubscription<int>? _statusSubscription;
  StreamSubscription<Uint8List>? _dataSubscription;
  ValueNotifier<int> deviceStatusNotifier = ValueNotifier<int>(Device.disconnected);

  bool _isReconnecting = false;
  bool _isConnectingNow = false;
  bool _isConnected = false;
  bool _isTryingToReconnect = false;
  Timer? _watchBluetoothStatus;
  OperationOptions operationOptions = OperationOptions();
  DefaultInitializationSettings defaultInicializationSettings = DefaultInitializationSettings();
  Map<String, dynamic> operationOptionsData = {};
  Map<String, dynamic> defaultInicializationSettingsOptions = {};

  // Duplicate detection at source level
  final Set<String> _processedDataHashes = <String>{};
  String? _lastProcessedData;
  DateTime? _lastDataTimestamp;
  ValueNotifier<String> defaultInterfaceFSM = ValueNotifier<String>("I0C0B0E0M0J0W0");

  BluetoothModel get state => bluetoothState; // Getter para o estado atual

  Future<void> initialize() async {
    defaultInicializationSettingsOptions = jsonDecode(await SecureStorageKey.main.instance.read(key: 'default_initialization_settings') as String);
    defaultInicializationSettings = DefaultInitializationSettings.fromJson(defaultInicializationSettingsOptions);
    GetIt.I<LoggerService>().d("Default initialization settings: ${jsonEncode(defaultInicializationSettings)}");

    operationOptionsData = jsonDecode(await SecureStorageKey.main.instance.read(key: 'operation_options') as String);
    operationOptions = OperationOptions.fromJson(operationOptionsData);
    GetIt.I<LoggerService>().d("Operation options: ${operationOptions.toString()}");

    GetIt.I<LoggerService>().i("BluetoothService inicializado.");
    _macAddress = await SecureStorageKey.main.instance.read(key: "interface_bluetooth_mac") ?? "00:00:00:00:00:00"; // Lê o MAC Address do dispositivo Bluetooth do armazenamento

    if (_macAddress == "00:00:00:00:00:00") {
      _updateState(statusMessage: "Dispositivo desconectado.", deviceStatus: Device.disconnected);
      GetIt.I<LoggerService>().e("MAC Address inválido. Verifique as configurações.");
      return;
    }

    await Future.delayed(Duration(seconds: 1));
    await platform.invokeMethod('enableBluetooth');

    // Aguarda o UI dar o primeiro frame antes de começar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() async {
        GetIt.I<LoggerService>().i("🕓 Esperando UI estabilizar...");
        await Future.delayed(const Duration(seconds: 3));

        // Executa pareamento e conexão inicial isoladamente
        _initBluetoothListeners();
        _startBluetoothWatchConnectionTimer();
        await _safeInitialPairAndConnect();
      });
    });
  }

  Future<void> _safeInitialPairAndConnect() async {
    if (_isReconnecting) return;
    _isReconnecting = true;

    try {
      GetIt.I<LoggerService>().d("🔐 Executando pareamento inicial...");
      await Future.microtask(() async {
        await platform.invokeMethod('pairDevice', {"mac": _macAddress});
      });

      await Future.delayed(const Duration(milliseconds: 500)); // extra gap

      GetIt.I<LoggerService>().d("Tentando conexão inicial...");
      final connected = await _connectInterface();

      if (connected) {
        GetIt.I<LoggerService>().i("Conectado com sucesso após inicialização.");
      } else {
        GetIt.I<LoggerService>().w("Não conseguiu conectar no boot.");
      }
    } catch (e) {
      GetIt.I<LoggerService>().e("Erro no pareamento/conexão inicial: $e");
    } finally {
      _isReconnecting = false;
    }
  }

  //* Timer monitora o status a cada 3 segundos e reconecta se necessário
  void _startBluetoothWatchConnectionTimer() {
    _watchBluetoothStatus = Timer.periodic(Duration(seconds: 20), (_) async {
      if (_isConnected) return;
      if (_isTryingToReconnect) return;

      GetIt.I<LoggerService>().w("Desconectado. Disparando reconexão...");
      final fsmZero = "I0C0B0E0M0J0W2";
      _updateState(fsmData: fsmZero, statusMessage: "Desconectado!", deviceStatus: Device.disconnected);
      await reconnect();
    });

    // Additional timer for duplicate tracking cleanup (every 5 minutes)
    Timer.periodic(Duration(minutes: 5), (_) {
      if (_processedDataHashes.length > 100) {
        _processedDataHashes.clear();
        GetIt.I<LoggerService>().i("🧹 Limpeza de hashes de dados duplicados realizada");
      }
    });
  }

  //* Inicializa os Listeners do Bluetooth Classic ao iniciar a classe
  void _initBluetoothListeners() {
    GetIt.I<LoggerService>().d("🔄 Configurando Listeners Bluetooth...");

    _statusSubscription ??= _bluetoothClassic.onDeviceStatusChanged().listen(
      (event) async {
        deviceStatusNotifier.value = event;

        if (event == Device.connected) {
          _isConnected = true;
          _updateState(statusMessage: "Dispositivo conectado.", deviceStatus: Device.connected);
        } else if (event == Device.disconnected) {
          _isConnected = false;
          _updateState(statusMessage: "Dispositivo desconectado.", deviceStatus: Device.disconnected);
          final fsmZero = "I0C0B0E0M0J0W2";
          _updateState(fsmData: fsmZero, statusMessage: "Desconectado!", deviceStatus: Device.disconnected);

          await Future.delayed(Duration(milliseconds: 500)); // Pequeno delay para garantir que o stack limpou
          if (!_isReconnecting) {
            await _triggerReconnection();
          }
        }
      },
      onError: (e) {
        GetIt.I<LoggerService>().e("Erro ao monitorar status: $e");
      },
    );

    _dataSubscription ??= _bluetoothClassic.onDeviceDataReceived().listen((data) {
      handleReceivedData(data);
    });
  }

  //* Dispara a reconexão fora do listener
  Future<void> _triggerReconnection() async {
    await Future.delayed(Duration(seconds: 15));
    await Future.microtask(() async {
      await reconnect();
    });
  }

  //* Reconexão
  Future<void> reconnect({int maxAttempts = 5}) async {
    if (_isTryingToReconnect) {
      GetIt.I<LoggerService>().i("Já tentando reconectar, abortando nova tentativa.");
      return;
    }

    _isTryingToReconnect = true;
    GetIt.I<LoggerService>().w("🔄 Tentando reconectar...");
    final fsmZero = "I0C0B0E0M0J0W0";
    _updateState(fsmData: fsmZero, statusMessage: "Desconectado!", deviceStatus: Device.connecting);

    int attempts = 0;

    while (attempts < maxAttempts) {
      GetIt.I<LoggerService>().w("🔄 Tentativa de reconexão #$attempts");

      try {
        bool connected = false;
        //await Future.microtask(() async {
        connected = await _connectInterface();
        //});
        if (connected) {
          GetIt.I<LoggerService>().i("✅ Reconexão bem-sucedida!");
          break;
        }
      } catch (e) {
        GetIt.I<LoggerService>().e("Erro na tentativa de reconexão: $e");
      }

      attempts++;
      GetIt.I<LoggerService>().d("⌛ Esperando 10s antes de nova tentativa...");
      await Future.delayed(const Duration(seconds: 10));
    }

    if (attempts >= maxAttempts) {
      GetIt.I<LoggerService>().w("❌ Falha após $maxAttempts tentativas.");
    }

    _isTryingToReconnect = false;
  }

  Future<bool> _connectBluetooth(String macAddress) async {
    try {
      final result = await platform.invokeMethod('pairDevice', {"mac": macAddress});
      if (result == true) {
        await _bluetoothClassic.connect(macAddress, "00001101-0000-1000-8000-00805f9b34fb");
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  //* Conexão inicial
  Future<bool> _connectInterface() async {
    if (_isConnected || _isConnectingNow) {
      GetIt.I<LoggerService>().i("Já conectado ou tentando conectar. Abortando.");
      return true;
    }

    _isConnectingNow = true;

    try {
      GetIt.I<LoggerService>().d("Tentando conectar via RFCOMM...");

      bool connected = false;
      //await Future.microtask(() async {
      connected = await _connectBluetooth(_macAddress);
      //});

      if (connected) {
        GetIt.I<LoggerService>().i("✅ Conectado via RFCOMM!");
        _isConnected = true;
        _updateState(statusMessage: "Conectado via RFCOMM!", deviceStatus: Device.connected);
        writeToInterface("CMD-SYNC_RTC-${Utils.generateLocalEpochAsIdTransaction()}");
        // Aguarda 1 segundo para garantir que a conexão está estável
        // Sincronizar com a interface o agendamento de funcionamento da máquina
        await Future.delayed(const Duration(seconds: 1));
        GetIt.I<LoggerService>().i("Enviando comando de agendamento de funcionamento da máquina...${jsonEncode(operationOptionsData)}");
        writeToInterface(Utils.buildRtcScheduleCommand(operationOptions, defaultInicializationSettings));
        return true;
      } else {
        GetIt.I<LoggerService>().e("❌ Falha ao conectar.");
        return false;
      }
    } catch (e, stack) {
      GetIt.I<LoggerService>().e("❌ Erro ao conectar: $e");
      GetIt.I<LoggerService>().d(stack);
      return false;
    } finally {
      _isConnectingNow = false;

      if (!_isConnected) {
        try {
          await disconnect();
          GetIt.I<LoggerService>().w("⚠️ Desconexão forçada após falha.");
        } catch (e) {
          GetIt.I<LoggerService>().e("Erro ao forçar desconexão final: $e");
        }
      }
    }
  }

  Future<void> disconnect() async {
    if (_isConnected) {
      try {
        await Future.microtask(() async {
          await _bluetoothClassic.disconnect();
        });

        _isConnected = false;
        // Atualiza FSM para zerado ao desconectar
        final fsmZero = "I0C0B0E0M0J0W2";
        _updateState(fsmData: fsmZero, statusMessage: "Desconectado!", deviceStatus: Device.disconnected);
        GetIt.I<LoggerService>().i("Dispositivo desconectado com sucesso.");
      } catch (e) {
        GetIt.I<LoggerService>().e("Erro ao desconectar: $e");
      }
    } else {
      // Mesmo já estando desconectado, garante que o FSM está zerado
      final fsmZero = "I0C0B0E0M0J0W2";
      _updateState(fsmData: fsmZero, statusMessage: "Desconectado!", deviceStatus: Device.disconnected);
      GetIt.I<LoggerService>().i("Bluetooth já estava desconectado.");
    }
  }

  void handleReceivedData(Uint8List data) {
    String receivedString = String.fromCharCodes(data);

    GetIt.I<LoggerService>().d("📦 Dados brutos recebidos: $receivedString");

    // Split multiple encrypted messages that may be concatenated
    // Messages are formatted as: #ENCRYPTED_DATA.
    List<String> encryptedMessages = _splitEncryptedMessages(receivedString);

    for (String message in encryptedMessages) {
      if (message.isEmpty) continue;

      GetIt.I<LoggerService>().d("🔓 Tentando descriptografar: $message");
      String dataDecrypted = Utils.decryptInterfaceData(message) ?? "";

      // Source-level duplicate detection
      if (dataDecrypted.isEmpty) {
        GetIt.I<LoggerService>().w("🚫 Dados vazios após descriptografia, ignorando: $message");
        continue;
      }

      String type = dataDecrypted.split("-").first;

      // Special handling for PING/PONG - they should NEVER be blocked as duplicates
      if (dataDecrypted == "CMD-PONG" || dataDecrypted.startsWith("CMD-PING")) {
        GetIt.I<LoggerService>().w("📡 PING/PONG RECEBIDO: $dataDecrypted - SEMPRE PROCESSADO");
        Map<String, dynamic> dataFormatted = {'raw_data': message, 'result': dataDecrypted, 'type': type};
        _updateTransactionData(dataFormatted);
        continue;
      }

      // Check for exact data duplicate (but not for PING/PONG)
      if (_lastProcessedData == dataDecrypted) {
        DateTime now = DateTime.now();
        if (_lastDataTimestamp != null && now.difference(_lastDataTimestamp!).inSeconds < 2) {
          GetIt.I<LoggerService>().w("🚫 FONTE DUPLICADA - Dados idênticos recebidos há ${now.difference(_lastDataTimestamp!).inSeconds}s: $dataDecrypted - IGNORANDO");
          continue;
        }
      }

      // Update tracking
      _lastProcessedData = dataDecrypted;
      _lastDataTimestamp = DateTime.now();

      GetIt.I<LoggerService>().w("📡 DADOS FONTE: tipo=$type, dados=$dataDecrypted");

      Map<String, dynamic> dataFormatted = {'raw_data': message, 'result': dataDecrypted, 'type': type};
      _updateTransactionData(dataFormatted);
    }
  }

  /// Splits concatenated encrypted messages that arrive in format: #DATA1.#DATA2.#DATA3.
  List<String> _splitEncryptedMessages(String receivedString) {
    List<String> messages = [];

    // Find all messages in format #...
    RegExp messagePattern = RegExp(r'#([^#]+?)(?=\.|$)');
    Iterable<RegExpMatch> matches = messagePattern.allMatches(receivedString);

    for (RegExpMatch match in matches) {
      String encryptedPart = match.group(1) ?? "";
      if (encryptedPart.isNotEmpty) {
        // Reconstruct the message with delimiters
        String fullMessage = "#$encryptedPart.";
        messages.add(fullMessage);
        GetIt.I<LoggerService>().d("📋 Mensagem extraída: $fullMessage");
      }
    }

    // Fallback: if no matches found, try the original string
    if (messages.isEmpty && receivedString.isNotEmpty) {
      GetIt.I<LoggerService>().w("⚠️ Padrão não encontrado, usando dados originais: $receivedString");
      messages.add(receivedString);
    }

    GetIt.I<LoggerService>().i("📨 Total de mensagens extraídas: ${messages.length}");
    return messages;
  }

  void _proccessResponse(String transactionTypeResult, String result, String message) async {
    if (result.isEmpty) {
      GetIt.I<LoggerService>().e("Resultado vazio, não enviando ACK.");
      return;
    }

    // CMD-PONG is a special case, we don't send ACK
    if (result == "CMD-PONG") {
      GetIt.I<LoggerService>().i("CMD-PONG recebido, não enviando ACK.");
      _updateState(commandResult: result, statusMessage: message, deviceStatus: Device.connected);
      return;
    }

    // CMD-SET_RTC_SCHEDULE is a special case, we don't send ACK
    if (result.startsWith("CMD-SET_RTC_SCHEDULE")) {
      GetIt.I<LoggerService>().i("CMD-SET_RTC_SCHEDULE recebido, não enviando ACK.");
      _updateState(commandResult: result, statusMessage: message, deviceStatus: Device.connected);
      return;
    }

    // CMD-SYS_INFO is also a special case, we don't send ACK
    if (result.startsWith("CMD-SYS_INFO")) {
      GetIt.I<LoggerService>().i("CMD-SYS_INFO recebido, não enviando ACK.");
      _updateState(commandResult: result, statusMessage: message, deviceStatus: Device.connected);
      return;
    }

    String data = "ACK-$result";
    try {
      GetIt.I<LoggerService>().i("Enviando ACK: $data");
      await writeToInterface(data);

      if (transactionTypeResult == "TEF") {
        _updateState(transactionTEFResult: result, statusMessage: message, deviceStatus: Device.connected);
      } else if (transactionTypeResult == "NOTE") {
        _updateState(transactionBanknoteResult: result, statusMessage: message, deviceStatus: Device.connected);
      } else if (transactionTypeResult == "COIN") {
        _updateState(transactionCoinResult: result, statusMessage: message, deviceStatus: Device.connected);
      } else if (transactionTypeResult == "PRODUCT") {
        _updateState(productCollected: result, statusMessage: message, deviceStatus: Device.connected);
      } else if (transactionTypeResult == "CMD") {
        _updateState(commandResult: result, statusMessage: message, deviceStatus: Device.connected);
      } else {
        GetIt.I<LoggerService>().d("Resultado não reconhecido: $result");
      }
    } catch (e) {
      GetIt.I<LoggerService>().e("Erro ao enviar ACK: $e");
    }
  }

  void _updateTransactionData(Map<String, dynamic> data) {
    if (data['raw_data'] == null || data['result'] == null) {
      GetIt.I<LoggerService>().e("Dados recebidos inválidos: \\${data['raw_data']}");
      return;
    }

    String result = data['result'].toString().trim();
    // // the W1 have to be updated with bluetooth device status
    // if (result.isNotEmpty && result.contains("W")) {
    //   result = Utils.updateWStatus(fsm: result, newStatus: bluetoothState.deviceStatus.toString());
    // }

    switch (data['type']) {
      case "FSM":
        // Se o status do device não for conectado, envia FSM zerado
        if (bluetoothState.deviceStatus == Device.connected) {
          result = Utils.updateWStatus(fsm: result.split("-").last, newStatus: "1");
          _updateState(fsmData: result, statusMessage: "Dados FSM recebidos.", deviceStatus: bluetoothState.deviceStatus);
        } else if (bluetoothState.deviceStatus == Device.connecting) {
          result = Utils.updateWStatus(fsm: result.split("-").last, newStatus: "0");
          _updateState(fsmData: result, statusMessage: "Dados FSM recebidos.", deviceStatus: bluetoothState.deviceStatus);
        } else if (bluetoothState.deviceStatus == Device.disconnected) {
          result = Utils.updateWStatus(fsm: result.split("-").last, newStatus: "2");
          _updateState(fsmData: result, statusMessage: "Dados FSM recebidos.", deviceStatus: bluetoothState.deviceStatus);
        } else {
          _updateState(fsmData: result.split("-").last, statusMessage: "Dados FSM recebidos.", deviceStatus: bluetoothState.deviceStatus);
        }
        break;
      case "TEF":
        _proccessResponse(data['type'], result, "Transação TEF recebida.");
        break;
      case "NOTE":
        _proccessResponse(data['type'], result, "Transação nota recebida.");
        break;
      case "COIN":
        _proccessResponse(data['type'], result, "Transação moeda recebida.");
        break;
      case "PRODUCT":
        _proccessResponse(data['type'], result, "Dados do produto recebido.");
        break;
      case "CMD":
        _proccessResponse(data['type'], result, "Dados de comando recebido.");
        break;
      default:
        GetIt.I<LoggerService>().d("Dados recebidos: $result");
    }
  }

  Future<void> writeToInterface(String data) async {
    try {
      GetIt.I<LoggerService>().i("Enviando para a interface: $data");
      String encryptedData = Utils.encryptInterfaceData(data);
      GetIt.I<LoggerService>().d(encryptedData);
      await _bluetoothClassic.write(encryptedData);
      await Future.delayed(Duration(seconds: 1));
      GetIt.I<LoggerService>().d("Dados enviados com sucesso: $data");
      _updateState(statusMessage: "Dados enviados com sucesso!", deviceStatus: Device.connected);
    } catch (e) {
      GetIt.I<LoggerService>().e("Erro ao enviar dados: $e");
      _updateState(statusMessage: "Erro ao enviar dados: $e", deviceStatus: Device.disconnected);
    }
  }

  void _updateState({
    String? interfaceINFO,
    String? statusMessage,
    int? deviceStatus,
    String? transactionBanknoteResult,
    String? transactionCoinResult,
    String? transactionTEFResult,
    String? commandResult,
    String? productCollected,
    String? fsmData,
  }) {
    // Atualiza o estado local imediatamente
    bluetoothState = bluetoothState.copyWith(
      interfaceINFO: interfaceINFO ?? bluetoothState.interfaceINFO,
      statusMessage: statusMessage ?? bluetoothState.statusMessage,
      deviceStatus: deviceStatus ?? bluetoothState.deviceStatus,
      transactionBanknoteResult: transactionBanknoteResult,
      transactionCoinResult: transactionCoinResult,
      transactionTEFResult: transactionTEFResult,
      commandResult: commandResult,
      productCollected: productCollected,
      fsmData: fsmData ?? bluetoothState.fsmData,
    );

    // Send ALL updates immediately - no debounce needed for hardware events
    GetIt.I<LoggerService>().w(
      "📤 ENVIANDO IMEDIATAMENTE: banknote=$transactionBanknoteResult, coin=$transactionCoinResult, tef=$transactionTEFResult, cmd=$commandResult, product=$productCollected, fsm=$fsmData, status=$statusMessage",
    );
    _bluetoothController.add(bluetoothState);
  }

  void disposeBluetoothService() {
    _statusSubscription?.cancel();
    _dataSubscription?.cancel();
    _watchBluetoothStatus?.cancel();
    _bluetoothController.close();
    _bluetoothClassic.disconnect();

    // Clear duplicate detection tracking
    _processedDataHashes.clear();
    _lastProcessedData = null;
    _lastDataTimestamp = null;
  }
}
