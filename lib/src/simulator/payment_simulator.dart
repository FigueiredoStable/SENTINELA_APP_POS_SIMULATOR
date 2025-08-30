import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:get_it/get_it.dart';
import 'package:restart_app/restart_app.dart';
import 'package:sentinela_app_pos_simulator/services/logger_service.dart';

/// Interface que simula as operações de pagamento do PagSeguro
abstract class PaymentHandler {
  void onTransactionSuccess();
  void onError(String message);
  void onMessage(String message);
  void onFinishedResponse(String message);
  void onLoading(bool show);
  void writeToFile({String? transactionCode, String? transactionId, String? response});
  void onAbortedSuccessfully();
  void disposeDialog();
  void onActivationDialog();
  void onAuthProgress(String message);
  void onTransactionInfo({String? transactionCode, String? transactionId, String? response});
}

/// Simulador que substitui a funcionalidade real do PagSeguro
class PaymentSimulator {
  static PaymentSimulator? _instance;
  PaymentHandler? _paymentHandler;
  Timer? _transactionTimer;
  bool _isInitialized = false;
  bool _isProcessingPayment = false;

  PaymentSimulator._();

  static PaymentSimulator instance() {
    _instance ??= PaymentSimulator._();
    return _instance!;
  }

  Payment get payment => Payment._internal(this);

  /// Inicializa o simulador com o handler de pagamento
  void initPayment(PaymentHandler handler) {
    _paymentHandler = handler;
    GetIt.I<LoggerService>().i("🎭 PaymentSimulator inicializado");
  }

  /// Simula a ativação do pinpad
  Future<bool> _activePinpad(String activationCode) async {
    GetIt.I<LoggerService>().i("🎭 Simulando ativação do pinpad com código: $activationCode");

    // Simula delay da ativação
    await Future.delayed(const Duration(milliseconds: 500));

    // Simula mensagens de progresso
    _paymentHandler?.onAuthProgress("Ativando terminal...");
    await Future.delayed(const Duration(milliseconds: 1000));

    _paymentHandler?.onAuthProgress("Terminal ativado");
    await Future.delayed(const Duration(milliseconds: 500));

    _paymentHandler?.onLoading(true);
    _isInitialized = true;

    return true;
  }

  /// Verifica se está autenticado (sempre true no simulador)
  Future<bool> _isAuthenticated() async {
    return _isInitialized;
  }

  /// Simula pagamento por crédito
  Future<bool> _creditPayment(int amount, {bool printReceipt = false}) async {
    return _simulatePayment("CRÉDITO", amount, printReceipt: printReceipt);
  }

  /// Simula pagamento por débito
  Future<bool> _debitPayment(int amount, {bool printReceipt = false}) async {
    return _simulatePayment("DÉBITO", amount, printReceipt: printReceipt);
  }

  /// Simula pagamento PIX
  Future<bool> _pixPayment(int amount, {bool printReceipt = false}) async {
    return _simulatePayment("PIX", amount, printReceipt: printReceipt);
  }

  /// Simula cancelamento de transação
  Future<bool> _abortTransaction() async {
    GetIt.I<LoggerService>().i("🎭 Simulando cancelamento de transação");

    if (_transactionTimer != null) {
      _transactionTimer!.cancel();
      _transactionTimer = null;
    }

    _isProcessingPayment = false;

    await Future.delayed(const Duration(milliseconds: 300));
    _paymentHandler?.onMessage("B018 - OPERACAO CANCELADA");
    await Future.delayed(const Duration(milliseconds: 500));
    _paymentHandler?.onAbortedSuccessfully();

    return true;
  }

  /// Simula reinicialização do dispositivo
  Future<bool> _rebootDevice() async {
    GetIt.I<LoggerService>().i("🎭 Simulando reinicialização do dispositivo");
    await Future.delayed(const Duration(milliseconds: 200));
    GetIt.I.reset(); // limpa todas as instâncias registradas
    Restart.restartApp(); // reinicia o app para garantir que as instâncias sejam criadas novamente e assuma a nova
    return true;
  }

  /// Método central que simula diferentes tipos de pagamento
  Future<bool> _simulatePayment(String paymentType, int amount, {bool printReceipt = false}) async {
    if (_isProcessingPayment) {
      GetIt.I<LoggerService>().w("🎭 Pagamento já em andamento");
      return false;
    }

    _isProcessingPayment = true;
    GetIt.I<LoggerService>().i("🎭 Simulando pagamento $paymentType de R\$ ${amount / 100}");

    try {
      // Etapa 1: Aguardando cartão
      _paymentHandler?.onMessage("APROXIME, INSIRA OU PASSE O CARTAO");
      await Future.delayed(const Duration(seconds: 2));

      // Simula diferentes cenários baseado no valor para testing
      final shouldSucceed = _shouldPaymentSucceed(amount);

      if (!shouldSucceed) {
        return _simulatePaymentError();
      }

      // Etapa 2: Processando
      _paymentHandler?.onMessage("PROCESSANDO");
      await Future.delayed(const Duration(seconds: 1));

      // Etapa 3: Transação autorizada
      _paymentHandler?.onMessage("TRANSAÇÃO AUTORIZADA");
      await Future.delayed(const Duration(milliseconds: 800));

      // Etapa 4: Remover cartão (se não for PIX)
      if (paymentType != "PIX") {
        _paymentHandler?.onMessage("RETIRE O CARTÃO");
        await Future.delayed(const Duration(seconds: 1));
      }

      // Etapa 5: Finalização bem-sucedida
      final mockResponse = _generateMockResponse(paymentType, amount);
      _paymentHandler?.onFinishedResponse(jsonEncode(mockResponse));

      await Future.delayed(const Duration(milliseconds: 300));
      _paymentHandler?.onTransactionSuccess();

      // Informações da transação
      _paymentHandler?.onTransactionInfo(transactionCode: mockResponse['transactionCode'], transactionId: mockResponse['transactionId'], response: jsonEncode(mockResponse));

      return true;
    } catch (e) {
      GetIt.I<LoggerService>().e("🎭 Erro na simulação de pagamento", e);
      return false;
    } finally {
      _isProcessingPayment = false;
    }
  }

  /// Simula erro no pagamento
  Future<bool> _simulatePaymentError() async {
    final errorMessages = ["CARTÃO NEGADO", "SALDO INSUFICIENTE", "CARTÃO BLOQUEADO", "ERRO DE COMUNICAÇÃO"];

    final randomError = errorMessages[Random().nextInt(errorMessages.length)];
    _paymentHandler?.onMessage(randomError);
    await Future.delayed(const Duration(seconds: 1));
    _paymentHandler?.onError(randomError);

    return false;
  }

  /// Define se o pagamento deve ser bem-sucedido baseado no valor
  /// Para facilitar os testes, valores específicos podem forçar falhas
  bool _shouldPaymentSucceed(int amount) {
    // Valores que sempre falham (para teste)
    if (amount == 1 || amount == 666 || amount == 999) {
      return false;
    }

    // 90% de chance de sucesso
    return Random().nextInt(100) < 90;
  }

  /// Gera resposta mock para transação bem-sucedida
  Map<String, dynamic> _generateMockResponse(String paymentType, int amount) {
    final now = DateTime.now();
    final transactionCode = _generateTransactionCode();
    final transactionId = _generateTransactionId();

    return {
      'transactionCode': transactionCode,
      'transactionId': transactionId,
      'amount': amount,
      'paymentType': paymentType,
      'approved': true,
      'date': now.toIso8601String(),
      'cardBrand': _getRandomCardBrand(),
      'cardMask': '**** **** **** ${Random().nextInt(9999).toString().padLeft(4, '0')}',
      'authorizationCode': Random().nextInt(999999).toString().padLeft(6, '0'),
      'receipt': _generateReceiptData(paymentType, amount, transactionCode),
    };
  }

  /// Gera código de transação mock
  String _generateTransactionCode() {
    return 'SIM${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Gera ID de transação mock
  String _generateTransactionId() {
    return Random().nextInt(999999999).toString().padLeft(9, '0');
  }

  /// Retorna bandeira de cartão aleatória
  String _getRandomCardBrand() {
    final brands = ['VISA', 'MASTERCARD', 'ELO', 'AMEX'];
    return brands[Random().nextInt(brands.length)];
  }

  /// Gera dados do comprovante
  Map<String, dynamic> _generateReceiptData(String paymentType, int amount, String transactionCode) {
    return {
      'establishment': 'SENTINELA SIMULATOR',
      'merchant': '12345678901234',
      'terminal': 'SIM001',
      'paymentType': paymentType,
      'amount': amount,
      'transactionCode': transactionCode,
      'date': DateTime.now().toIso8601String(),
    };
  }
}

/// Classe que simula a interface Payment do PagSeguro
class Payment {
  final PaymentSimulator _simulator;

  Payment._internal(this._simulator);

  Future<bool> activePinpad(String activationCode) => _simulator._activePinpad(activationCode);
  Future<bool> isAuthenticated() => _simulator._isAuthenticated();
  Future<bool> creditPayment(int amount, {bool printReceipt = false}) => _simulator._creditPayment(amount, printReceipt: printReceipt);
  Future<bool> debitPayment(int amount, {bool printReceipt = false}) => _simulator._debitPayment(amount, printReceipt: printReceipt);
  Future<bool> pixPayment(int amount, {bool printReceipt = false}) => _simulator._pixPayment(amount, printReceipt: printReceipt);
  Future<bool> abortTransaction() => _simulator._abortTransaction();
  Future<bool> rebootDevice() => _simulator._rebootDevice();
}
