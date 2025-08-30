import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:sentinela_app_pos_simulator/enums/status_transaction_enum.dart';
import 'package:sentinela_app_pos_simulator/services/logger_service.dart';
import 'package:sentinela_app_pos_simulator/src/simulator/payment_simulator.dart';

class PaymentHandlerController extends PaymentHandler {
  ValueNotifier<StatusTransactionEnum> actionEnum = ValueNotifier(StatusTransactionEnum.WAITING);
  ValueNotifier<String> rawMessagePagbankReturn = ValueNotifier("Aguardando pagamento.");
  ValueNotifier<Map<String, dynamic>> onFinishResponseReceipt = ValueNotifier({});

  final ValueNotifier<bool> _initialized = ValueNotifier(false);
  final ValueNotifier<bool> posAuthenticationStatus = ValueNotifier(false);

  String? transactionCode;
  String? transactionId;
  String? response;
  bool _isInitializing = false;

  final Completer<void> _readyCompleter = Completer<void>();

  PaymentHandlerController() {
    GetIt.I<LoggerService>().i("📦 PaymentHandlerController instanciado.");
    //_initAsync();
  }

  Future<void> get ready => _readyCompleter.future;
  ValueNotifier<bool> get isInitialized => _initialized;

  //! usar a auto inicialização apenas se esse número for único e não mutável verificar com a PAGBANK
  // Future<void> _initAsync() async {
  //   //await init(pinpadId: "749879");
  //   await init(pinpadId: "000000");
  // }

  Future<void> init({required String pinpadId}) async {
    if (_initialized.value || _isInitializing) {
      GetIt.I<LoggerService>().w("⚠️ init() chamado novamente, mas já está inicializando ou pronto.");
      return;
    }

    _isInitializing = true;
    GetIt.I<LoggerService>().i("🔧 Inicializando PaymentHandlerController...");
    PaymentSimulator.instance().initPayment(this);

    try {
      final result = await PaymentSimulator.instance().payment.activePinpad(pinpadId);

      if (result) {
        GetIt.I<LoggerService>().i("💡 Pinpad ativado com sucesso");
        _initialized.value = true;
        if (!_readyCompleter.isCompleted) _readyCompleter.complete();
      } else {
        GetIt.I<LoggerService>().w("⚠️ Falha ao ativar o Pinpad");
        if (!_readyCompleter.isCompleted) {
          _readyCompleter.completeError("Falha ao ativar o Pinpad");
        }
      }
    } catch (e, s) {
      GetIt.I<LoggerService>().e("Erro na ativação do Pinpad", e, s);
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.completeError(e);
      }
    } finally {
      _isInitializing = false;
    }
  }

  Future<bool> getIfPagbankIsAuthenticated() async {
    return PaymentSimulator.instance().payment.isAuthenticated();
  }

  void disposePaymentHandlerController() {
    GetIt.I<LoggerService>().i("🗑️ Destruindo PaymentHandlerController...");
    actionEnum.dispose();
    rawMessagePagbankReturn.dispose();
    onFinishResponseReceipt.dispose();
    posAuthenticationStatus.dispose();
    _initialized.dispose();
    _readyCompleter.complete();
    _initialized.value = false;
  }

  @override
  void disposeDialog() {}

  @override
  void onAbortedSuccessfully() {
    GetIt.I<LoggerService>().w("[ON ABORTED SUCCESSFULLY] - Transacao cancelada com sucesso");
  }

  @override
  void onActivationDialog() {}

  @override
  void onAuthProgress(String message) {
    //* Responsible for showing the authorization progress of the POS terminal
    GetIt.I<LoggerService>().i("[ON AUTH PROGRESS] - $message");
    if (message == "Terminal ativado") {
      GetIt.I.signalReady(this); //* sinaliza corretamente que fez a ativação
      posAuthenticationStatus.value = true;
    } else {
      posAuthenticationStatus.value = false;
    }
  }

  @override
  void onError(String message) {
    GetIt.I<LoggerService>().e("[ON ERROR] - $message");
    actionEnum.value = StatusTransactionEnum.TECHNICAL_ERROR;
  }

  @override
  void onMessage(String message) {
    rawMessagePagbankReturn.value = message.toUpperCase();

    if (message == 'APROXIME, INSIRA OU PASSE O CARTAO') {
      actionEnum.value = StatusTransactionEnum.TRANSACTION_WAITING_CARD;
    } else if (message == 'TRANSAÇÃO AUTORIZADA') {
      actionEnum.value = StatusTransactionEnum.WAITING;
    } else if (message == 'B018 - OPERACAO CANCELADA') {
      actionEnum.value = StatusTransactionEnum.CANCELLED;
    } else if (message == 'RETIRE O CARTÃO') {
      actionEnum.value = StatusTransactionEnum.TRANSACTION_REMOVE_CARD;
    } else if (message == 'PROCESSANDO') {
      actionEnum.value = StatusTransactionEnum.WAITING;
    }
  }

  @override
  void onFinishedResponse(String message) {
    GetIt.I<LoggerService>().i("[ON FINISHED RESPONSE] - $message");
    onFinishResponseReceipt.value = jsonDecode(message);
    actionEnum.value = StatusTransactionEnum.APPROVED;
    rawMessagePagbankReturn.value = StatusTransactionEnum.APPROVED.descriptiom;
  }

  @override
  void onTransactionSuccess() {
    GetIt.I<LoggerService>().i("[ON TRANSACTION SUCCESS] - Transacao concluida com sucesso");
  }

  @override
  void writeToFile({String? transactionCode, String? transactionId, String? response}) {}

  @override
  void onLoading(bool show) {
    if (show && !_initialized.value) {
      _initialized.value = true;
      if (!_readyCompleter.isCompleted) _readyCompleter.complete();
      GetIt.I<LoggerService>().i("[ON LOADING] - POS ativado via onLoading");
    }
  }

  @override
  void onTransactionInfo({String? transactionCode, String? transactionId, String? response}) {
    this.transactionCode = transactionCode;
    this.transactionId = transactionId;
    this.response = response;
    GetIt.I<LoggerService>().i("[ON TRANSACTION INFO] - $transactionCode, transactionId: $transactionId, response: $response");
  }
}
