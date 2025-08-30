import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentinela_app_pos_simulator/enums/interface_event_types_enum.dart';
import 'package:sentinela_app_pos_simulator/models/api_initialization_global_settings_model.dart';
import 'package:sentinela_app_pos_simulator/models/command_event_model.dart';
import 'package:sentinela_app_pos_simulator/models/product_event_model.dart';
import 'package:sentinela_app_pos_simulator/models/sale_transaction_model.dart';
import 'package:sentinela_app_pos_simulator/services/logger_service.dart';
import 'package:sentinela_app_pos_simulator/utils/constants.dart';
import 'package:sentinela_app_pos_simulator/utils/currency_input_formater.dart';
import 'package:sentinela_app_pos_simulator/utils/secure_storage_keys.dart';
import 'package:uuid/uuid.dart';

class Utils {
  Utils._();
  static final uuid = Uuid();
  static final statusMappings = <String, Map<String, String>>{
    'I': {'0': 'CHECANDO', '1': 'ONLINE', '2': 'OFFLINE'},
    'C': {'0': 'CHECANDO', '1': 'ONLINE', '2': 'OFFLINE'},
    'B': {'0': 'CHECANDO', '1': 'NORMAL', '2': 'TRAVADO'},
    'E': {'0': 'CHECANDO', '1': 'SEM ERRO', '2': 'COM ERRO'},
    'M': {'0': 'CHECANDO', '1': 'LIGADA', '2': 'DESLIGADA'},
    'J': {'0': 'CHECANDO', '1': 'OCIOSA', '2': 'EM USO'},
    'W': {'0': 'CONECTANDO', '1': 'CONECTADA', '2': 'DESCONECTADA'},
  };
  static CurrencyInputFormatter currencyInputFormatter = CurrencyInputFormatter();

  static List<String> decryptInterfaceDataWithMultiple(String encryptedStream) {
    // Divide o stream bruto em partes usando delimitadores que a ESP32 pode usar
    final chunks = encryptedStream.split(RegExp(r'[.#]'));
    final results = <String>[];

    for (var chunk in chunks) {
      final decrypted = decryptInterfaceData(chunk);
      if (decrypted != null) {
        results.add(decrypted);
      }
    }

    return results;
  }

  static String? decryptInterfaceData(String encryptedBase64) {
    // Remove delimitadores externos
    encryptedBase64 = encryptedBase64.trim();
    if (encryptedBase64.startsWith("#")) {
      encryptedBase64 = encryptedBase64.substring(1);
    }
    if (encryptedBase64.endsWith(".")) {
      encryptedBase64 = encryptedBase64.substring(0, encryptedBase64.length - 1);
    }

    // Verifica se contém o delimitador esperado
    if (!encryptedBase64.contains("|")) {
      GetIt.I<LoggerService>().e("Dados recebidos sem delimitador '|': $encryptedBase64");
      return null;
    }

    final parts = encryptedBase64.split("|");
    if (parts.length != 2) {
      GetIt.I<LoggerService>().e("Formato inválido (esperado: IV|DATA): $encryptedBase64");
      return null;
    }

    final ivBase64 = parts[0];
    final dataBase64 = parts[1];

    // Verifica se IV tem exatamente 16 bytes
    final ivBytes = utf8.encode(ivBase64);
    if (ivBytes.length != 16) {
      GetIt.I<LoggerService>().e("IV inválido: '$ivBase64' com ${ivBytes.length} bytes.");
      return null;
    }

    final keyInBytes = utf8.encode(Constants.AES_KEY_DECRYPT);

    try {
      final iv = encrypt.IV(Uint8List.fromList(ivBytes));
      final key = encrypt.Key(Uint8List.fromList(keyInBytes));

      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: "PKCS7"));

      final decrypted = encrypter.decrypt64(dataBase64, iv: iv);
      return decrypted;
    } catch (e) {
      GetIt.I<LoggerService>().e("Erro ao descriptografar: $e");
      return null;
    }
  }

  // Gera um IV de 16 bytes e converte para string ASCII legível
  static String generateIVString() {
    final random = math.Random.secure();
    const String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"; // ASCII seguro

    return List.generate(16, (i) => chars[random.nextInt(chars.length)]).join();
  }

  // Converte a String IV para `Uint8List` (para criptografia)
  static Uint8List ivStringToBytes(String ivString) {
    return Uint8List.fromList(utf8.encode(ivString).sublist(0, 16));
  }

  // Função para criptografar
  static String encryptInterfaceData(String plaintext) {
    // Gerar IV como texto puro
    final ivString = generateIVString();
    final ivBytes = ivStringToBytes(ivString);

    // Converter chave AES para bytes
    final keyInBytes = utf8.encode(Constants.AES_KEY_ENCRYPT);
    final key = encrypt.Key(Uint8List.fromList(keyInBytes));

    // Criar encriptador AES CBC com PKCS7
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: "PKCS7"));
    final iv = encrypt.IV(ivBytes);

    // Criptografar e converter para Base64
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    final encryptedBase64 = encrypted.base64;

    // Concatenar IV (texto puro) + "|" + Texto Criptografado
    return "#$ivString|$encryptedBase64.";
  }

  static String translateValueReceivedFromInterface({required String value}) {
    String onlyValue = value.split("-")[1];
    if (onlyValue.length == 3) {
      double valueInDouble = double.parse(onlyValue);
      return valueInDouble.toString();
    }
    return double.parse(onlyValue).toString();
  }

  static String formatBRLMoney(num value) {
    double valueFormated = value.toDouble();
    return currencyInputFormatter.formatDoubleToCurrency(valueFormated);
  }

  static String epochToUTCDateTime(int epoch) {
    final local = DateTime.fromMillisecondsSinceEpoch(epoch * 1000); // local timezone do device
    final utc = local.toUtc();
    return DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(utc);
  }

  static String epochToLocalDateTime(int epoch) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(epoch * 1000, isUtc: false).toLocal();
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  static String getUTCDateTimeFromPOS() {
    return DateTime.now().toUtc().toIso8601String();
  }

  static String getLocalDateTimeFromPOS() {
    return DateTime.now().toIso8601String();
  }

  static String utcToLocalTime(String timestamp) {
    var dateTime = DateFormat("yyyy-MM-dd'T'HH:mm:ss").parse(timestamp, true);
    var dateLocal = dateTime.toLocal();
    var formated = DateFormat("dd-MM-yy HH:mm").format(dateLocal);
    return formated.toString();
  }

  static String formatDateTime(String timestamp) {
    var dateTime = DateFormat("yyyy-MM-dd HH:mm:ss.SSS").parse(timestamp, true);
    var formatted = DateFormat("dd-MM-yy HH:mm").format(dateTime);
    return formatted.toString();
  }

  static String generateLocalEpochAsIdTransaction() {
    final now = DateTime.now();
    final adjustedEpoch = now.toUtc().add(now.timeZoneOffset).millisecondsSinceEpoch ~/ 1000;
    return adjustedEpoch.toString();
  }

  static int formatPrice(double value) {
    if (value > 0.0) {
      return (value * 100).toInt();
    } else {
      return 0;
    }
  }

  static void showAllStorageData() async {
    // Read all values
    Map<String, String> allValues = await SecureStorageKey.main.instance.readAll();
    allValues.forEach((key, value) {
      log("Key: $key, Value: $value", name: "[SECURE STORAGE DATA] - ");
    });
  }

  static Future<Map<String, String>> getAppVersionInfo() async {
    final info = await PackageInfo.fromPlatform();
    return {'appName': info.appName, 'packageName': info.packageName, 'version': info.version, 'buildNumber': info.buildNumber};
  }

  static String generateRandomID() {
    // Gera um UUID v4
    return const Uuid().v4();
  }

  static Future<bool> addEventPendingToSync(dynamic newEvent) async {
    try {
      List<dynamic> existingEvents;
      InterfaceEventTypesEnum type;
      String key;
      SecureStorageKey storage;

      if (newEvent is SaleTransactionModel) {
        type = InterfaceEventTypesEnum.SALE_TRANSACTION;
        key = 'pending_transactions';
        storage = SecureStorageKey.transactions;
      } else if (newEvent is ProductEventModel) {
        type = InterfaceEventTypesEnum.PRODUCT;
        key = 'pending_products';
        storage = SecureStorageKey.products;
      } else if (newEvent is CommandEventModel) {
        type = InterfaceEventTypesEnum.COMMAND;
        key = 'pending_commands';
        storage = SecureStorageKey.commands;
      } else {
        throw ArgumentError('Tipo de evento não suportado.');
      }

      existingEvents = await getLocalPendingEventsToSync(type: type);

      bool exists = existingEvents.any((e) {
        if (newEvent is SaleTransactionModel && e is SaleTransactionModel) {
          return e.eventId == newEvent.eventId && e.timestamp == newEvent.timestamp;
        } else if (newEvent is ProductEventModel && e is ProductEventModel) {
          return e.eventId == newEvent.eventId && e.timestamp == newEvent.timestamp;
        } else if (newEvent is CommandEventModel && e is CommandEventModel) {
          return e.eventId == newEvent.eventId && e.interfaceEpochTimestamp == newEvent.interfaceEpochTimestamp;
        }
        return false;
      });

      if (!exists) {
        existingEvents.add(newEvent);

        final List listToSave = existingEvents.map((e) => e.toJson()).toList();
        final String jsonString = jsonEncode(listToSave);

        await storage.instance.write(key: key, value: jsonString);
      }

      return true;
    } catch (e) {
      GetIt.I<LoggerService>().e("Erro ao adicionar evento pendente: $e");
      return false;
    }
  }

  static Future<bool> updateSaleTransactionByEventId({
    required String eventId,
    required Map<String, dynamic> patchSnakeCase, // ex.: {'product_delivered_status': 'DELIVERED'}
  }) async {
    try {
      // Carrega a lista existente de transações pendentes
      final type = InterfaceEventTypesEnum.SALE_TRANSACTION;
      final List<dynamic> events = await getLocalPendingEventsToSync(type: type);

      // Acha pelo event_id (atenção: snake_case!)
      final int idx = events.indexWhere((e) {
        if (e is Map<String, dynamic>) return e['event_id'] == eventId;
        final dynamic d = e;
        return (d.eventId as String?) == eventId;
      });
      if (idx < 0) return false;

      // Converte o item para Map (garante forma mutável)
      Map<String, dynamic> json = (events[idx] is Map<String, dynamic>)
          ? Map<String, dynamic>.from(events[idx] as Map<String, dynamic>)
          : (events[idx] as dynamic).toJson() as Map<String, dynamic>;

      // Merge com *snake_case*
      json.addAll(patchSnakeCase);

      // Reconstrói tipado e salva a lista inteira de volta
      events[idx] = SaleTransactionModel.fromJson(json);

      final listToSave = events.map((e) => (e as dynamic).toJson()).toList();
      await SecureStorageKey.transactions.instance.write(key: 'pending_transactions', value: jsonEncode(listToSave));

      return true;
    } catch (e) {
      GetIt.I<LoggerService>().e("Erro no updateSaleTransactionByEventId($eventId): $e");
      return false;
    }
  }

  static Map<String, dynamic> salePatchDelivered({
    required InterfaceEventTypesEnum status, // DELIVERED / FAILED_DELIVERED / TIMEOUT
    required String transactionStatus, // 'PAID' ou 'ERROR'
    required String transactionStatusDescription,
    required Map<String, dynamic> receipt,
    required bool saleStatus, // true quando DELIVERED
    required String timestampIsoUtc, // Utils.getUTCDateTimeFromPOS()
  }) {
    return {
      'product_delivered_status': status.name,
      'transaction_status': transactionStatus,
      'transaction_status_description': transactionStatusDescription,
      'receipt': receipt,
      'sale_status': saleStatus,
      'timestamp': timestampIsoUtc,
    };
  }

  static Map<String, dynamic> salePatchTimeout({required String timestampIsoUtc}) {
    return {
      'product_delivered_status': InterfaceEventTypesEnum.TIMEOUT.name,
      'transaction_status': 'ERROR',
      'transaction_status_description': 'Timeout expirado',
      'sale_status': false,
      'timestamp': timestampIsoUtc,
    };
  }

  static Future<bool> updateEventByEventId({
    required InterfaceEventTypesEnum type, // USE: SALE_TRANSACTION / PRODUCT / COMMAND
    required String eventId,
    required Map<String, dynamic> patch, // campos a sobrescrever
  }) async {
    try {
      // ===== mapeia bucket (igual ao add) =====
      late String key;
      late SecureStorageKey storage;
      late dynamic Function(Map<String, dynamic>) fromJson;

      switch (type) {
        case InterfaceEventTypesEnum.SALE_TRANSACTION:
          key = 'pending_transactions';
          storage = SecureStorageKey.transactions;
          fromJson = (m) => SaleTransactionModel.fromJson(m);
          break;
        case InterfaceEventTypesEnum.PRODUCT:
          key = 'pending_products';
          storage = SecureStorageKey.products;
          fromJson = (m) => ProductEventModel.fromJson(m);
          break;
        case InterfaceEventTypesEnum.COMMAND:
          key = 'pending_commands';
          storage = SecureStorageKey.commands;
          fromJson = (m) => CommandEventModel.fromJson(m);
          break;
        default:
          throw ArgumentError('Tipo inválido para update: use SALE_TRANSACTION/PRODUCT/COMMAND');
      }

      // ===== carrega lista =====
      final List<dynamic> events = await getLocalPendingEventsToSync(type: type);

      // ===== encontra índice pelo eventId (tipado ou Map) =====
      int idx = events.indexWhere((e) {
        try {
          if (e is Map<String, dynamic>) return e['eventId'] == eventId;
          final dynamic d = e;
          return (d.eventId as String?) == eventId;
        } catch (_) {
          return false;
        }
      });

      if (idx < 0) {
        GetIt.I<LoggerService>().w("updateEventByEventId: eventId $eventId NÃO encontrado no bucket $key");
        return false;
      }

      // ===== merge patch =====
      Map<String, dynamic> json = (events[idx] is Map<String, dynamic>)
          ? Map<String, dynamic>.from(events[idx] as Map<String, dynamic>)
          : (events[idx] as dynamic).toJson() as Map<String, dynamic>;

      // log antes
      GetIt.I<LoggerService>().i("updateEventByEventId[before][$key][$eventId]: ${jsonEncode(json)}");

      json.addAll(patch); // sobrescreve campos

      // reconstrói tipado
      events[idx] = fromJson(json);

      // ===== persiste =====
      final String jsonString = jsonEncode(events.map((e) => (e as dynamic).toJson()).toList());
      await storage.instance.write(key: key, value: jsonString);

      // log depois
      GetIt.I<LoggerService>().i("updateEventByEventId[after][$key][$eventId]: ${jsonEncode((events[idx] as dynamic).toJson())}");
      return true;
    } catch (e) {
      GetIt.I<LoggerService>().e("Erro no updateEventByEventId($eventId): $e");
      return false;
    }
  }

  static Future<List<dynamic>> getLocalPendingEventsToSync({required InterfaceEventTypesEnum type}) async {
    if (type == InterfaceEventTypesEnum.SALE_TRANSACTION) {
      try {
        final String? jsonString = await SecureStorageKey.transactions.instance.read(key: 'pending_transactions');
        if (jsonString == null || jsonString.isEmpty) return [];

        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.map((item) => SaleTransactionModel.fromJson(item as Map<String, dynamic>)).toList();
      } catch (e) {
        GetIt.I<LoggerService>().e("Erro ao obter transações pendentes: $e");
        return [];
      }
    } else if (type == InterfaceEventTypesEnum.PRODUCT) {
      try {
        final String? jsonString = await SecureStorageKey.products.instance.read(key: 'pending_products');
        if (jsonString == null || jsonString.isEmpty) return [];

        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.map((item) => ProductEventModel.fromJson(item as Map<String, dynamic>)).toList();
      } catch (e) {
        GetIt.I<LoggerService>().e("Erro ao obter produtos pendentes: $e");
        return [];
      }
    } else if (type == InterfaceEventTypesEnum.COMMAND) {
      try {
        final String? jsonString = await SecureStorageKey.commands.instance.read(key: 'pending_commands');
        if (jsonString == null || jsonString.isEmpty) return [];

        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.map((item) => CommandEventModel.fromJson(item as Map<String, dynamic>)).toList();
      } catch (e) {
        GetIt.I<LoggerService>().e("Erro ao obter comandos pendentes: $e");
        return [];
      }
    } else {
      throw ArgumentError('Tipo de transação não suportado.');
    }
  }

  static Future<void> removePendingEventSyncedById({required String eventId, required InterfaceEventTypesEnum type}) async {
    if (type == InterfaceEventTypesEnum.SALE_TRANSACTION) {
      try {
        final String? pendingJson = await SecureStorageKey.transactions.instance.read(key: 'pending_transactions');
        if (pendingJson == null || pendingJson.isEmpty) return;

        final List<dynamic> decoded = jsonDecode(pendingJson);
        final List<SaleTransactionModel> pendingList = decoded.map((e) => SaleTransactionModel.fromJson(e as Map<String, dynamic>)).toList();

        pendingList.removeWhere((item) => item.eventId == eventId);

        final List<Map<String, dynamic>> updatedList = pendingList.map((e) => e.toJson()).toList();
        await SecureStorageKey.transactions.instance.write(key: 'pending_transactions', value: jsonEncode(updatedList));
      } catch (e) {
        GetIt.I<LoggerService>().e("Erro ao remover transação sincronizada: $e");
      }
    } else if (type == InterfaceEventTypesEnum.PRODUCT) {
      try {
        final String? pendingJson = await SecureStorageKey.products.instance.read(key: 'pending_products');
        if (pendingJson == null || pendingJson.isEmpty) return;

        final List<dynamic> decoded = jsonDecode(pendingJson);
        final List<ProductEventModel> pendingList = decoded.map((e) => ProductEventModel.fromJson(e as Map<String, dynamic>)).toList();

        pendingList.removeWhere((item) => item.eventId == eventId);

        final List<Map<String, dynamic>> updatedList = pendingList.map((e) => e.toJson()).toList();
        await SecureStorageKey.products.instance.write(key: 'pending_products', value: jsonEncode(updatedList));
      } catch (e) {
        GetIt.I<LoggerService>().e("Erro ao remover transação sincronizada: $e");
      }
    } else if (type == InterfaceEventTypesEnum.COMMAND) {
      try {
        final String? pendingJson = await SecureStorageKey.commands.instance.read(key: 'pending_commands');
        if (pendingJson == null || pendingJson.isEmpty) return;

        final List<dynamic> decoded = jsonDecode(pendingJson);
        final List<CommandEventModel> pendingList = decoded.map((e) => CommandEventModel.fromJson(e as Map<String, dynamic>)).toList();

        pendingList.removeWhere((item) => item.eventId == eventId);

        final List<Map<String, dynamic>> updatedList = pendingList.map((e) => e.toJson()).toList();
        await SecureStorageKey.commands.instance.write(key: 'pending_commands', value: jsonEncode(updatedList));
      } catch (e) {
        GetIt.I<LoggerService>().e("Erro ao remover transação sincronizada: $e");
      }
    } else {
      throw ArgumentError('Tipo de transação não suportado.');
    }
  }

  static String formatTefCommandWithEpoch(double price) {
    int intPrice = price.toInt();
    String paddedPrice = intPrice.toString().padLeft(3, '0');

    // Corrigir o Epoch, sem somar offset
    final adjustedEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return 'TEF-$paddedPrice-$adjustedEpoch';
  }

  static bool isCurrentTimeAfterOrEqual(int targetHour, int targetMinute) {
    final now = DateTime.now();
    final target = DateTime(now.year, now.month, now.day, targetHour, targetMinute);

    return now.isAfter(target) || now.isAtSameMomentAs(target);
  }

  static String? extractBetweenSecondDashAndColon(String input) {
    final match = RegExp(r'^[^-]+-[^-]+-([^:]+):').firstMatch(input);
    return match?.group(1);
  }

  static String? extractOnlyEpochWithoutStatus(String input) {
    final match = RegExp(r'^[^-]+-[^-]+-([0-9]+)').firstMatch(input);
    return match?.group(1);
  }

  static String? extractOnlyEventId(String input) {
    // Extract the event ID which is the last segment before the colon
    // Pattern: anything-anything-timestamp-EVENTID:remaining
    final match = RegExp(r'-([^-:]+)(?=:)').firstMatch(input);
    return match?[1];
  }

  static Map<String, dynamic> processFSMStatus({required String fsm}) {
    final parts = fsm.split(RegExp(r'(?=[A-Z])'));
    final result = <String, String>{};

    for (var part in parts) {
      final key = part[0]; // Ex: 'I'
      final value = part.substring(1); // Ex: '1'
      final mapped = statusMappings[key]?[value] ?? 'desconhecido';
      result[key] = mapped;
    }

    return result;
  }

  static int getCurrentEpoch() {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  static Future<bool> clearMainStorage() async {
    try {
      await SecureStorageKey.main.instance.deleteAll();
      return true;
    } catch (e) {
      GetIt.I<LoggerService>().e("Erro ao limpar o armazenamento principal: $e");
      return false;
    }
  }

  static Future<bool> clearCommandStorage() async {
    try {
      await SecureStorageKey.commands.instance.deleteAll();
      return true;
    } catch (e) {
      GetIt.I<LoggerService>().e("Erro ao limpar o armazenamento de comandos: $e");
      return false;
    }
  }

  static Future<bool> clearProductStorage() async {
    try {
      await SecureStorageKey.products.instance.deleteAll();
      return true;
    } catch (e) {
      GetIt.I<LoggerService>().e("Erro ao limpar o armazenamento de produtos: $e");
      return false;
    }
  }

  static Future<bool> clearTransactionStorage() async {
    try {
      await SecureStorageKey.transactions.instance.deleteAll();
      return true;
    } catch (e) {
      GetIt.I<LoggerService>().e("Erro ao limpar o armazenamento de transações: $e");
      return false;
    }
  }

  static Map<String, String> splitByLastDash(String input) {
    int lastDash = input.lastIndexOf('-');

    if (lastDash == -1) {
      // Não encontrou nenhum hífen
      return {'before': input, 'after': ''};
    }

    String before = input.substring(0, lastDash);
    String after = input.substring(lastDash + 1);

    return {'before': before, 'after': after};
  }

  static int calcularCreditos(double valor, PriceOptions optionsList) {
    final options = optionsList.priceOpts;
    if (options == null || options.isEmpty) return 0;

    // Encontrar a melhor opção com menor preço por crédito
    final melhorOpcao = options.reduce((a, b) {
      final precoA = double.parse(a.price!);
      final creditosA = int.parse(a.credits!);
      final precoB = double.parse(b.price!);
      final creditosB = int.parse(b.credits!);

      return (precoA / creditosA) < (precoB / creditosB) ? a : b;
    });

    final precoUnitario = double.parse(melhorOpcao.price!) / int.parse(melhorOpcao.credits!);
    final totalCreditos = (valor / precoUnitario).toInt();

    return totalCreditos;
  }

  static bool checkIfIsNotReleaseMode() {
    // Verifica se o app está rodando em modo de depuração
    if (kDebugMode || kProfileMode) {
      return true;
    } else {
      return false;
    }
  }

  static String updateWStatus({required String fsm, required String newStatus}) {
    return fsm.replaceAllMapped(RegExp(r'W[012]'), (match) => 'W$newStatus');
  }

  static String buildRtcScheduleCommand(OperationOptions data, DefaultInitializationSettings defaultSettings) {
    // Mapeamento dia -> bit (0 = domingo ... 6 = sábado)
    final Map<String, int> dayToBit = {"sunday": 0, "monday": 1, "tuesday": 2, "wednesday": 3, "thursday": 4, "friday": 5, "saturday": 6};

    // Cria máscara de dias
    int mask = 0;
    for (final rawDay in data.workingDays ?? []) {
      final day = rawDay.toString().trim().toLowerCase();
      final bit = dayToBit[day];
      if (bit != null) {
        mask |= (1 << bit);
      }
    }

    // Se não tiver nenhum dia válido → liga todos os dias
    if (mask == 0) {
      mask = 0x7F; // 127 decimal = 0b1111111
    }

    // Extrai hora início e fim
    final startParts = (data.workingHoursStart)?.split(":") ?? ["00", "00"];
    final endParts = (data.workingHoursEnd)?.split(":") ?? ["00", "00"];

    final startHour = startParts[0].padLeft(2, '0');
    final startMin = startParts[1].padLeft(2, '0');
    final endHour = endParts[0].padLeft(2, '0');
    final endMin = endParts[1].padLeft(2, '0');

    // Converte máscara para string binária com 7 bits (Dom-Sab)
    final daysBinary = mask.toRadixString(2).padLeft(7, '0');

    // Monta comando final
    int scheduleIsActive = defaultSettings.activateMachineOperationScheduling != null
        ? defaultSettings.activateMachineOperationScheduling!
              ? 1
              : 0
        : 1;
    return "CMD-SET_RTC_SCHEDULE=$startHour:$startMin-$endHour:$endMin-$daysBinary-$scheduleIsActive";
  }
}
