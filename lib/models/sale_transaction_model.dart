class SaleTransactionModel {
  final String client;
  final String machine;
  final double price;
  final String product;
  final String type;
  final String method;
  final String productDeliveredStatus;
  final String transactionStatusDescription;
  final String transactionStatus;
  final Map<String, dynamic> receipt;
  final String eventId;
  final String interfaceEpochTimestamp;
  final String timestamp;
  final bool saleStatus;

  SaleTransactionModel({
    required this.client,
    required this.machine,
    required this.price,
    required this.product,
    required this.type,
    required this.method,
    required this.productDeliveredStatus,
    required this.transactionStatusDescription,
    required this.transactionStatus,
    required this.receipt,
    required this.eventId,
    required this.interfaceEpochTimestamp,
    required this.timestamp,
    required this.saleStatus,
  });

  factory SaleTransactionModel.fromJson(Map<String, dynamic> json) {
    return SaleTransactionModel(
      client: json['client'],
      machine: json['machine'],
      price: json['price'],
      product: json['product'],
      type: json['type'],
      method: json['method'],
      productDeliveredStatus: json['product_delivered_status'],
      transactionStatusDescription: json['transaction_status_description'],
      transactionStatus: json['transaction_status'],
      receipt: Map<String, dynamic>.from(json['receipt']),
      eventId: json['event_id'],
      interfaceEpochTimestamp: json['interface_epoch_timestamp'],
      timestamp: json['timestamp'],
      saleStatus: json['sale_status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client': client,
      'machine': machine,
      'price': price,
      'product': product,
      'type': type,
      'method': method,
      'product_delivered_status': productDeliveredStatus,
      'transaction_status_description': transactionStatusDescription,
      'transaction_status': transactionStatus,
      'receipt': receipt,
      'event_id': eventId,
      'interface_epoch_timestamp': interfaceEpochTimestamp,
      'timestamp': timestamp,
      'sale_status': saleStatus,
    };
  }

  @override
  String toString() {
    return toJson().toString();
  }
}
