class BluetoothModel {
  final String interfaceINFO;
  final String statusMessage;
  final int deviceStatus;
  final String? transactionBanknoteResult;
  final String? transactionCoinResult;
  final String? transactionTEFResult;
  final String? commandResult;
  final String? productCollected;
  final String fsmData;

  const BluetoothModel({
    required this.interfaceINFO,
    required this.statusMessage,
    required this.deviceStatus,
    required this.transactionBanknoteResult,
    required this.transactionCoinResult,
    required this.transactionTEFResult,
    required this.commandResult,
    required this.productCollected,
    required this.fsmData,
  });

  BluetoothModel copyWith({
    String? interfaceINFO,
    String? statusMessage,
    int? deviceStatus,
    String? transactionBanknoteResult,
    String? transactionCoinResult,
    String? transactionTEFResult,
    String? commandResult,
    String? productCollected,
    String? interactionStatus,
    String? fsmData,
  }) {
    return BluetoothModel(
      interfaceINFO: interfaceINFO ?? this.interfaceINFO,
      statusMessage: statusMessage ?? this.statusMessage,
      deviceStatus: deviceStatus ?? this.deviceStatus,
      transactionBanknoteResult: transactionBanknoteResult,
      transactionCoinResult: transactionCoinResult,
      transactionTEFResult: transactionTEFResult,
      commandResult: commandResult,
      productCollected: productCollected,
      fsmData: fsmData ?? this.fsmData,
    );
  }
}
