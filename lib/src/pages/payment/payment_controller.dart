import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:sentinela_app_pos_simulator/enums/insert_credit_status_enum.dart';
import 'package:sentinela_app_pos_simulator/enums/interface_event_types_enum.dart' show InterfaceEventTypesEnum;
import 'package:sentinela_app_pos_simulator/enums/payment_view_stage.dart';
import 'package:sentinela_app_pos_simulator/enums/payment_view_state.dart';
import 'package:sentinela_app_pos_simulator/enums/payment_view_type.dart';
import 'package:sentinela_app_pos_simulator/enums/status_transaction_enum.dart';
import 'package:sentinela_app_pos_simulator/models/api_initialization_global_settings_model.dart';
import 'package:sentinela_app_pos_simulator/models/sale_transaction_model.dart';
import 'package:sentinela_app_pos_simulator/routes/navigation_service.dart';
import 'package:sentinela_app_pos_simulator/services/bluetooth_service.dart';
import 'package:sentinela_app_pos_simulator/services/logger_service.dart';
import 'package:sentinela_app_pos_simulator/src/pagbank.dart';
import 'package:sentinela_app_pos_simulator/src/pages/home/home_controller.dart';
import 'package:sentinela_app_pos_simulator/src/simulator/payment_simulator.dart';
import 'package:sentinela_app_pos_simulator/utils/secure_storage_keys.dart';
import 'package:sentinela_app_pos_simulator/utils/utils.dart';

class PaymentViewController {
  Uint8List image = Uint8List(0);
  ValueNotifier<bool> imageDone = ValueNotifier(false);
  ValueNotifier transactionSuccefull = ValueNotifier<bool>(false);
  ValueNotifier startSendTEFInterface = ValueNotifier<bool>(false);
  SupportInformation supportInfo = SupportInformation();

  ValueNotifier<PaymentViewStage> paymentViewStage = ValueNotifier(PaymentViewStage.options);
  ValueNotifier<PaymentViewState> paymentViewState = ValueNotifier(PaymentViewState.loading);
  ValueNotifier<PaymentViewTypeEnum> paymentViewType = ValueNotifier(PaymentViewTypeEnum.SELECT);

  // counter
  ValueNotifier<double> circleCount = ValueNotifier<double>(0.0);
  ValueNotifier<int> countMessage = ValueNotifier<int>(0);
  int countTime = 0;
  double countSteps = 0.0;
  bool counting = false;
  bool cancelCount = false;
  bool pingSuccess = false;
  bool _pingInProgress = false;

  // payment status view variables
  final ValueNotifier<String> animationAssetPayment = ValueNotifier('assets/lottie/anim-wait.json');

  // inset credit messages
  ValueNotifier<InsertCreditStatusEnum> messageInsertCredit = ValueNotifier(InsertCreditStatusEnum.INSERTING);

  ValueNotifier<bool> viewStateError = ValueNotifier(false);

  int countSeconds = 0;
  int countWaitingCard = 30;
  int countWaitingPass = 30;
  int countCardRemoved = 5;
  int countError = 10;
  int countSuccess = 10;
  int countAbortTransaction = 15;
  int countFinalizedSaleTransaction = 15;
  int countWaitInsertCreditOnInterface = 45;
  int interfacePingTimeout = 30; // Timeout para o PING em segundos

  String? _expectedTefCommand; // Guarda qual comando foi enviado
  Timer? _timeoutTefTimer;
  Timer? _timeoutPingTimer;
  Completer<bool>? _pingCompleter;
  String? _currentEventId; // correlaciona insert -> updates
  bool _tefFinalized = false; // evita double-finalize

  void initListeners() {
    GetIt.I<PaymentHandlerController>().rawMessagePagbankReturn.addListener(_onMessageChanged);
    GetIt.I<PaymentHandlerController>().actionEnum.addListener(_onActionChanged);
  }

  void disposeListeners() {
    GetIt.I<PaymentHandlerController>().rawMessagePagbankReturn.removeListener(_onMessageChanged);
    GetIt.I<PaymentHandlerController>().actionEnum.removeListener(_onActionChanged);
  }

  void _onMessageChanged() {
    GetIt.I<LoggerService>().i('[PAGBANK HANDLER CONTROLLER] Raw Message: ${GetIt.I<PaymentHandlerController>().rawMessagePagbankReturn.value}');
  }

  void _onActionChanged() {
    GetIt.I<LoggerService>().i('[PAGBANK HANDLER CONTROLLER] Action: ${GetIt.I<PaymentHandlerController>().actionEnum.value}');
    updatePaymentViewState();
  }

  Future<void> initialize() async {
    Map<String, dynamic> supportInfos = jsonDecode(await SecureStorageKey.main.instance.read(key: 'support_information') as String);
    supportInfo = SupportInformation.fromJson(supportInfos);
    GetIt.I<LoggerService>().d("Support infos: ${supportInfo.toJson()}");

    Map<String, dynamic> countersList = jsonDecode(await SecureStorageKey.main.instance.read(key: 'counter_options') as String);
    final countersSettings = CounterOptions.fromJson(countersList);

    // * Set ao inicio padrão do fluxo de pagamento
    animationAssetPayment.value = 'assets/lottie/anim-wait.json';
    GetIt.I<PaymentHandlerController>().actionEnum.value = StatusTransactionEnum.WAITING;
    GetIt.I<PaymentHandlerController>().rawMessagePagbankReturn.value = StatusTransactionEnum.WAITING.descriptiom;

    paymentViewStage.value = PaymentViewStage.options;
    paymentViewState.value = PaymentViewState.loading;
    paymentViewType.value = PaymentViewTypeEnum.SELECT;

    circleCount.value = 0.0;
    countMessage.value = 0;
    countTime = 0;
    countSteps = 0.0;
    counting = false;
    cancelCount = false;

    transactionSuccefull.value = false;

    countWaitingCard = countersSettings.counterWaitingCard!;
    countWaitingPass = countersSettings.counterWaitingPass!;
    countCardRemoved = countersSettings.counterCardRemoved!;
    countError = countersSettings.countError!;
    countSuccess = countersSettings.countSuccess!;
    countFinalizedSaleTransaction = countersSettings.countFinalizedSaleTransaction!;
    countWaitInsertCreditOnInterface = countersSettings.countWaitInsertCreditOnInterface!;
    interfacePingTimeout = countersSettings.interfacePingTimeout!;
    countAbortTransaction = countersSettings.countAbortTransaction!;

    GetIt.I<LoggerService>().i("Timeout Settings: $countersList");
    GetIt.I<LoggerService>().i('Payments Options: ${GetIt.I<HomeController>().paymentsTypesEnabled.toJson()}');
    GetIt.I<LoggerService>().w('Pagbang Handler Controller instance ID: ${identityHashCode(GetIt.I<PaymentHandlerController>())}');
    GetIt.I<LoggerService>().w('Home Controller instance ID: ${identityHashCode(GetIt.I<HomeController>())}');
    GetIt.I<LoggerService>().w('PaymentSimulator instance ID: ${identityHashCode(PaymentSimulator.instance().payment)}');

    initListeners();

    GetIt.I<LoggerService>().i('PaymentView initialized');
  }

  void startPaymentSelected(String type) {
    final PaymentViewTypeEnum selectedType = PaymentViewTypeEnum.values.firstWhere((e) => e.name == type);
    switch (selectedType) {
      case PaymentViewTypeEnum.CREDIT:
        creditPayment();
        break;
      case PaymentViewTypeEnum.DEBIT:
        debitPayment();
        break;
      case PaymentViewTypeEnum.PIX:
        pixPayment();
        break;
      default:
        GetIt.I<LoggerService>().e('Invalid payment type selected: $type');
    }
  }

  Future<void> creditPayment() async {
    paymentViewStage.value = PaymentViewStage.actions; // change view
    int priceInt = Utils.formatPrice(double.parse(GetIt.I<HomeController>().buyData.value.price));
    GetIt.I<HomeController>().buyData.value = GetIt.I<HomeController>().buyData.value.copyWith(type: PaymentViewTypeEnum.CREDIT);

    if (GetIt.I<HomeController>().defaultInicializationSettings.disableTefPaymentIfInterfaceIsOffline == true) {
      // * Check if the interface is ready to process the payment
      final pongReceived = await sendPingInterface();
      if (!pongReceived) {
        GetIt.I<LoggerService>().e("Ping failed, cannot proceed with credit payment.");
        animationAssetPayment.value = 'assets/lottie/anim-fail.json';
        countSeconds = countError;
        viewStateError.value = true;
        paymentViewState.value = PaymentViewState.error;
        return;
      } else {
        //await PaymentSimulator.instance().payment.abortTransaction();
        await Future.delayed(const Duration(milliseconds: 100));
        await PaymentSimulator.instance().payment.creditPayment(priceInt, printReceipt: false);
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 100));
      await PaymentSimulator.instance().payment.creditPayment(priceInt, printReceipt: false);
    }
  }

  Future<void> debitPayment() async {
    paymentViewStage.value = PaymentViewStage.actions; // change view
    int priceInt = Utils.formatPrice(double.parse(GetIt.I<HomeController>().buyData.value.price));
    GetIt.I<HomeController>().buyData.value = GetIt.I<HomeController>().buyData.value.copyWith(type: PaymentViewTypeEnum.DEBIT);

    if (GetIt.I<HomeController>().defaultInicializationSettings.disableTefPaymentIfInterfaceIsOffline == true) {
      // * Check if the interface is ready to process the payment
      final pongReceived = await sendPingInterface();
      if (!pongReceived) {
        GetIt.I<LoggerService>().e("Ping failed, cannot proceed with credit payment.");
        animationAssetPayment.value = 'assets/lottie/anim-fail.json';
        countSeconds = countError;
        viewStateError.value = true;
        paymentViewState.value = PaymentViewState.error;
        return;
      } else {
        //await PaymentSimulator.instance().payment.abortTransaction();
        await Future.delayed(const Duration(milliseconds: 100));
        await PaymentSimulator.instance().payment.debitPayment(priceInt, printReceipt: false);
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 100));
      await PaymentSimulator.instance().payment.debitPayment(priceInt, printReceipt: false);
    }
  }

  Future<void> pixPayment() async {
    paymentViewStage.value = PaymentViewStage.actions; // change view
    imageDone.value = false;
    int priceInt = Utils.formatPrice(double.parse(GetIt.I<HomeController>().buyData.value.price));
    GetIt.I<HomeController>().buyData.value = GetIt.I<HomeController>().buyData.value.copyWith(type: PaymentViewTypeEnum.PIX);

    if (GetIt.I<HomeController>().defaultInicializationSettings.disableTefPaymentIfInterfaceIsOffline == true) {
      // * Check if the interface is ready to process the payment
      final pongReceived = await sendPingInterface();
      if (!pongReceived) {
        GetIt.I<LoggerService>().e("Ping failed, cannot proceed with credit payment.");
        animationAssetPayment.value = 'assets/lottie/anim-fail.json';
        countSeconds = countError;
        viewStateError.value = true;
        paymentViewState.value = PaymentViewState.error;
        return;
      } else {
        //await PaymentSimulator.instance().payment.abortTransaction();
        await Future.delayed(const Duration(milliseconds: 100));
        await PaymentSimulator.instance().payment.pixPayment(priceInt, printReceipt: false);
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 100));
      await PaymentSimulator.instance().payment.pixPayment(priceInt, printReceipt: false);
    }
  }

  // made this one to prevent multiple instances of count at the same time
  // as other methods didnt work as expected
  startCountDownToExecuteFunction(int seconds, void Function() function) async {
    if (seconds == 0) {
      GetIt.I<LoggerService>().d('count not needed');
      return;
    }
    cancelCount = true;
    await Future.delayed(Duration(milliseconds: 1200));
    countDownToExecuteFunction(seconds, function);
  }

  countDownToExecuteFunction(int seconds, void Function() function) async {
    cancelCount = false;
    int i = seconds;
    double count = 1;
    double countStep = 1 / seconds;
    while (i > 0) {
      if (cancelCount) {
        GetIt.I<LoggerService>().d('count cancelled');
        return;
      } //! checking if cancelled
      circleCount.value = count;
      countMessage.value = i;
      await Future.delayed(Duration(seconds: 1));
      i--;
      count -= countStep;
    }
    circleCount.value = count;
    countMessage.value = i;

    function();
  }

  Future<void> abortTransaction() async {
    try {
      //! Tem uma questão aqui, quando o servidor está offline, o cancelamento retorna OK mas não cancela a transação na Pagbank
      //! Então na proxima transação vai retornar - [ON ERROR] - SV03 - Serviço ocupado. Aguarde ou termine a execução do processo anterior antes de iniciar um novo.
      //! Quando a lib executa o timeout dela: [ON ERROR] - C13 - OPERACAO CANCELADA
      GetIt.I<LoggerService>().e("Transaction cancelled by user");
      animationAssetPayment.value = 'assets/lottie/anim-fail.json';
      countSeconds = countError;
      viewStateError.value = true;
      paymentViewState.value = PaymentViewState.error;
      final result = await PaymentSimulator.instance().payment.abortTransaction();
      GetIt.I<LoggerService>().i('Abort result: $result');
    } catch (e) {
      GetIt.I<LoggerService>().e('Cancel payment error exception: $e');
    }
  }

  Future<bool> sendPingInterface() async {
    // Prevent multiple concurrent pings
    if (_pingInProgress) {
      GetIt.I<LoggerService>().w("⚠️ Ping já em andamento, ignorando nova solicitação");
      return _pingCompleter?.future ?? Future.value(false);
    }

    _pingInProgress = true;

    // Cancela qualquer ping anterior pendente
    _timeoutPingTimer?.cancel();
    if (_pingCompleter != null && !_pingCompleter!.isCompleted) {
      _pingCompleter!.complete(false);
    }

    _pingCompleter = Completer<bool>();
    pingSuccess = false;

    GetIt.I<HomeController>().onCommandResponseListener = (response) {
      GetIt.I<LoggerService>().w("🎯 Resposta recebida: $response");
      if (response.trim().startsWith("CMD-PONG")) {
        if (!_pingCompleter!.isCompleted) {
          GetIt.I<LoggerService>().i("✅ Ping recebido!");
          cancelPingTimeout();
          pingSuccess = true;
          _pingCompleter!.complete(true);
        }
      }
    };

    try {
      GetIt.I<LoggerService>().i("📤 Enviando CMD-PING...");
      await GetIt.I<BluetoothService>().writeToInterface("CMD-PING");
      _setupPingTimeout();
    } catch (e) {
      GetIt.I<LoggerService>().e("Erro ao enviar PING: $e");
      if (!_pingCompleter!.isCompleted) {
        _pingCompleter!.complete(false);
      }
    }

    final result = await _pingCompleter!.future;
    _pingInProgress = false; // Reset flag
    return result;
  }

  void _setupPingTimeout() {
    _timeoutPingTimer?.cancel();
    _timeoutPingTimer = Timer(Duration(seconds: interfacePingTimeout), () {
      if (_pingCompleter != null && !_pingCompleter!.isCompleted) {
        GetIt.I<LoggerService>().w("⏰ Timeout esperando resposta PING.");
        _pingCompleter!.complete(false);
      }
      _pingCompleter = null;
      GetIt.I<HomeController>().onCommandResponseListener = null;
    });
  }

  void cancelPingTimeout() {
    _timeoutPingTimer?.cancel();
    _timeoutPingTimer = null;
    _pingInProgress = false;
    GetIt.I<LoggerService>().w("⏰ Timeout PING cancelado.");
    GetIt.I<HomeController>().onCommandResponseListener = null;
  }

  Future<void> sendTEF() async {
    try {
      startSendTEFInterface.value = true;

      final String tefCommandInterface = Utils.formatTefCommandWithEpoch(double.parse(GetIt.I<HomeController>().buyData.value.price));

      _expectedTefCommand = tefCommandInterface;
      _currentEventId = Utils.generateRandomID();
      _tefFinalized = false;

      // monta PENDENTE antes de enviar
      final pending = SaleTransactionModel(
        client: await SecureStorageKey.main.instance.read(key: 'client_uuid') ?? "",
        machine: await SecureStorageKey.main.instance.read(key: 'machine_id') ?? "",
        price: double.parse(Utils.translateValueReceivedFromInterface(value: tefCommandInterface)),
        product: GetIt.I<HomeController>().buyData.value.credit,
        type: "TEF",
        method: GetIt.I<HomeController>().buyData.value.type.name,
        productDeliveredStatus: InterfaceEventTypesEnum.NOT_DELIVERED.name,
        transactionStatusDescription: "",
        transactionStatus: "PENDING",
        receipt: {},
        eventId: _currentEventId!,
        interfaceEpochTimestamp: Utils.epochToUTCDateTime(int.parse(Utils.extractOnlyEpochWithoutStatus(tefCommandInterface)!)),
        timestamp: Utils.getUTCDateTimeFromPOS(),
        saleStatus: false,
      );

      await Utils.addEventPendingToSync(pending); // INSERT do pendente

      GetIt.I<HomeController>().onTefResponseListener = handleTefResponse;
      GetIt.I<LoggerService>().w("Comando TEF Criado: $_expectedTefCommand");

      animationAssetPayment.value = 'assets/lottie/inserting_credit.json';
      viewStateError.value = false;
      paymentViewState.value = PaymentViewState.insertCredit;
      messageInsertCredit.value = InsertCreditStatusEnum.INSERTING;

      await GetIt.I<BluetoothService>().writeToInterface(_expectedTefCommand!);
    } catch (e) {
      startSendTEFInterface.value = false;
      viewStateError.value = true;
      paymentViewState.value = PaymentViewState.error;
      messageInsertCredit.value = InsertCreditStatusEnum.ERROR;
      animationAssetPayment.value = 'assets/lottie/anim-fail.json';
      GetIt.I<LoggerService>().e("Erro ao enviar comando TEF: $e");
    }
    _setupTefTimeout();
  }

  Future<void> updateDeliveredStatus({required InterfaceEventTypesEnum status, required String reasonOrResponse}) async {
    if (_currentEventId == null || _tefFinalized) return;

    // The transaction is ALWAYS PAID at this point since payment was confirmed by PagBank
    // We only update the delivery status and sale status
    String productDeliveredStatus;
    bool saleStatus;

    switch (status) {
      case InterfaceEventTypesEnum.DELIVERED:
        productDeliveredStatus = InterfaceEventTypesEnum.DELIVERED.name;
        saleStatus = true; // Delivery successful = sale complete
        break;
      case InterfaceEventTypesEnum.FAILED_DELIVERED:
        productDeliveredStatus = InterfaceEventTypesEnum.FAILED_DELIVERED.name;
        saleStatus = false; // Delivery failed = sale incomplete
        break;
      case InterfaceEventTypesEnum.TIMEOUT:
        productDeliveredStatus = InterfaceEventTypesEnum.TIMEOUT.name;
        saleStatus = false; // Delivery timeout = sale incomplete
        break;
      default:
        productDeliveredStatus = InterfaceEventTypesEnum.FAILED_DELIVERED.name;
        saleStatus = false;
    }

    await Utils.updateSaleTransactionByEventId(
      eventId: _currentEventId!,
      patchSnakeCase: Utils.salePatchDelivered(
        status: status,
        transactionStatus: 'PAID', // Always PAID - payment already confirmed
        transactionStatusDescription: reasonOrResponse,
        receipt: status == InterfaceEventTypesEnum.DELIVERED ? GetIt.I<PaymentHandlerController>().onFinishResponseReceipt.value : {},
        saleStatus: saleStatus, // This changes based on delivery success/failure
        timestampIsoUtc: Utils.getUTCDateTimeFromPOS(),
      ),
    );

    GetIt.I<LoggerService>().i("Delivery status updated: ${_currentEventId!} - Delivery: $productDeliveredStatus - Sale Complete: $saleStatus - Reason: $reasonOrResponse");

    _tefFinalized = true;
  }

  void handleTefResponse(String response) {
    GetIt.I<LoggerService>().w("Resposta TEF recebida: $response");
    GetIt.I<LoggerService>().w("Resposta TEF esperada: $_expectedTefCommand");

    if (_expectedTefCommand != null && response.trim().isNotEmpty && response != "null" && response.startsWith(_expectedTefCommand!)) {
      // Parse new TEF response format: "TEF-002-1755095095:1:2:0"
      // validation_status:processing_status:sent_status
      final tefParts = response.split(':');

      if (tefParts.length >= 4) {
        // Expecting 4 parts minimum (command + 3 status fields)
        final validationStatus = tefParts[1]; // "1" = success, "0" = error
        final processingStatus = tefParts[2]; // "2" = complete (should always be 2 when you receive it)
        final sentStatus = tefParts[3]; // "0" = sent successfully

        GetIt.I<LoggerService>().i("TEF Validation: $validationStatus, Processing: $processingStatus, Sent: $sentStatus");

        // Only check validation status since processing should always be complete (2) when received
        if (validationStatus == "1") {
          // Transaction processed successfully by external hardware
          GetIt.I<LoggerService>().i("Transação TEF confirmada com sucesso!");
          _handleSuccessfulTefResponse(interfaceResponse: response);
        } else if (validationStatus == "0") {
          // External hardware reported an error
          GetIt.I<LoggerService>().e("Hardware externo reportou erro na validação!");
          _handleFailedTefResponse("Hardware externo reportou erro - Response: $response - Status: $validationStatus");
        } else {
          // Unknown validation status
          GetIt.I<LoggerService>().e("Status de validação desconhecido: $validationStatus - Response: $response");
          _handleFailedTefResponse("Status de validação desconhecido: $validationStatus - Response: $response");
        }
      } else {
        // Invalid format - not enough parts
        GetIt.I<LoggerService>().e("Formato de resposta TEF inválido! Esperado 4 partes, recebido: ${tefParts.length}");
        _handleFailedTefResponse("Formato de resposta inválido: $response");
      }
    } else if (response == "null") {
      GetIt.I<LoggerService>().e("Resposta nula recebida!");
      _handleFailedTefResponse("Resposta nula/mismatch");
    } else {
      GetIt.I<LoggerService>().e("Resposta não confere com comando esperado!");
      _handleFailedTefResponse("Resposta inválida: $response");
    }
  }

  void _handleSuccessfulTefResponse({String interfaceResponse = ""}) {
    cancelTefTimeout();

    // Update transaction status
    updateDeliveredStatus(status: InterfaceEventTypesEnum.DELIVERED, reasonOrResponse: GetIt.I<PaymentHandlerController>().rawMessagePagbankReturn.value + interfaceResponse);

    // Update UI state
    transactionSuccefull.value = true;
    countSeconds = countFinalizedSaleTransaction;
    paymentViewState.value = PaymentViewState.creditInserted;
    messageInsertCredit.value = InsertCreditStatusEnum.INSERTED;
    animationAssetPayment.value = 'assets/lottie/anim-success.json';
  }

  void _handleFailedTefResponse(String reason) {
    cancelTefTimeout();

    // Update transaction status
    updateDeliveredStatus(status: InterfaceEventTypesEnum.FAILED_DELIVERED, reasonOrResponse: reason);

    // Update UI state
    transactionSuccefull.value = false;
    paymentViewState.value = PaymentViewState.error;
    messageInsertCredit.value = InsertCreditStatusEnum.ERROR;
    animationAssetPayment.value = 'assets/lottie/anim-fail.json';
  }

  void _setupTefTimeout() {
    _timeoutTefTimer?.cancel();
    _timeoutTefTimer = Timer(Duration(seconds: countWaitInsertCreditOnInterface), () {
      GetIt.I<LoggerService>().w("⏰ Timeout esperando resposta TEF.");
      GetIt.I<HomeController>().onTefResponseListener = null;
      GetIt.I<LoggerService>().e("❌ Timeout expirado, transação TEF não confirmada.");

      transactionSuccefull.value = false;
      paymentViewState.value = PaymentViewState.error;
      messageInsertCredit.value = InsertCreditStatusEnum.ERROR;
      animationAssetPayment.value = 'assets/lottie/anim-fail.json';

      updateDeliveredStatus(status: InterfaceEventTypesEnum.TIMEOUT, reasonOrResponse: "Timeout expirado");
    });
  }

  void cancelTefTimeout() {
    _timeoutTefTimer?.cancel();
    _timeoutTefTimer = null;
    GetIt.I<LoggerService>().w("⏰ Timeout cancelado.");
    GetIt.I<HomeController>().onTefResponseListener = null; // limpa
  }

  updatePaymentViewState() {
    // waiting
    if (GetIt.I<PaymentHandlerController>().actionEnum.value == StatusTransactionEnum.WAITING ||
        GetIt.I<PaymentHandlerController>().actionEnum.value == StatusTransactionEnum.PENDING) {
      animationAssetPayment.value = 'assets/lottie/anim-wait.json';
    }
    // waiting card
    else if (GetIt.I<PaymentHandlerController>().actionEnum.value == StatusTransactionEnum.TRANSACTION_WAITING_CARD) {
      animationAssetPayment.value = 'assets/lottie/anim-cardbounce.json';
      countSeconds = countWaitingCard;
      viewStateError.value = false;
      paymentViewState.value = PaymentViewState.waitingCard;
    }
    // waiting password
    else if (GetIt.I<PaymentHandlerController>().actionEnum.value == StatusTransactionEnum.TRANSACTION_WAITING_PASSWORD) {
      animationAssetPayment.value = 'assets/lottie/anim-cardbounce.json'; //! get new animation for password
      countSeconds = countWaitingPass;
      viewStateError.value = false;
      paymentViewState.value = PaymentViewState.waitingPassword;
    }
    // waiting transaction pending
    else if (GetIt.I<PaymentHandlerController>().actionEnum.value == StatusTransactionEnum.TRANSACTION_SENDING) {
      animationAssetPayment.value = 'assets/lottie/anim-wait.json';
      paymentViewState.value = PaymentViewState.loading;
    }
    // waiting remove card
    else if (GetIt.I<PaymentHandlerController>().actionEnum.value == StatusTransactionEnum.TRANSACTION_REMOVE_CARD) {
      animationAssetPayment.value = 'assets/lottie/anim-cardbounce.json';
      paymentViewState.value = PaymentViewState.removeCard;
    }
    // count card removed
    else if (GetIt.I<PaymentHandlerController>().actionEnum.value == StatusTransactionEnum.TRANSACTION_CARD_REMOVED) {
      paymentViewState.value = PaymentViewState.cardRemoved;
      countSeconds = countCardRemoved;
    }
    // count pix
    else if (GetIt.I<PaymentHandlerController>().actionEnum.value == StatusTransactionEnum.TRANSACTION_WAITING_QRCODE_SCAN) {
      //! add pix qrcode widget
      paymentViewState.value = PaymentViewState.pix;
    }
    // count approved
    else if (GetIt.I<PaymentHandlerController>().actionEnum.value == StatusTransactionEnum.APPROVED ||
        GetIt.I<PaymentHandlerController>().actionEnum.value == StatusTransactionEnum.PARTIAL_APPROVED) {
      animationAssetPayment.value = 'assets/lottie/anim-success.json';
      countSeconds = countSuccess;
      viewStateError.value = false;
      paymentViewState.value = PaymentViewState.success;
      sendTEF();
    }
    // count errors
    else if (GetIt.I<PaymentHandlerController>().actionEnum.value == StatusTransactionEnum.UNKNOWN ||
        GetIt.I<PaymentHandlerController>().actionEnum.value == StatusTransactionEnum.CANCELLED ||
        GetIt.I<PaymentHandlerController>().actionEnum.value == StatusTransactionEnum.DECLINED ||
        GetIt.I<PaymentHandlerController>().actionEnum.value == StatusTransactionEnum.DECLINED_BY_CARD ||
        GetIt.I<PaymentHandlerController>().actionEnum.value == StatusTransactionEnum.REJECTED ||
        GetIt.I<PaymentHandlerController>().actionEnum.value == StatusTransactionEnum.TECHNICAL_ERROR ||
        // actionEnum.value == StatusTransactionEnum.WITH_ERROR ||
        GetIt.I<PaymentHandlerController>().actionEnum.value == StatusTransactionEnum.REVERSED ||
        GetIt.I<PaymentHandlerController>().actionEnum.value == StatusTransactionEnum.PENDING_REVERSAL ||
        GetIt.I<PaymentHandlerController>().actionEnum.value == StatusTransactionEnum.REVERSING_TRANSACTION_WITH_ERROR) {
      animationAssetPayment.value = 'assets/lottie/anim-fail.json';
      countSeconds = countError;
      viewStateError.value = true;
      paymentViewState.value = PaymentViewState.error;
    } else {
      GetIt.I<LoggerService>().w("Status não reconhecido");
    }
  }

  void backToHome() {
    GetIt.I<NavigationService>().forceGoHome();
  }

  void disposePaymentController() async {
    imageDone.dispose();
    transactionSuccefull.dispose();
    paymentViewStage.dispose();
    paymentViewState.dispose();
    paymentViewType.dispose();
    circleCount.dispose();
    countMessage.dispose();
    animationAssetPayment.dispose();
    viewStateError.dispose();
    disposeListeners();
    _expectedTefCommand = null; // limpa depois de tratar
    _timeoutTefTimer?.cancel();
    _timeoutTefTimer = null; // limpa depois de tratar
    _timeoutPingTimer?.cancel();
    _timeoutPingTimer = null; // limpa depois de tratar
    cancelCount = true; // cancela contagem
    counting = false; // cancela contagem
    GetIt.I<LoggerService>().w("Destruindo PaymentViewController...");
  }
}
