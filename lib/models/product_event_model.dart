class ProductEventModel {
  final String client;
  final String machine;
  final String interfaceEpochTimestamp;
  final String timestamp;
  final String eventId;

  ProductEventModel({required this.client, required this.machine, required this.interfaceEpochTimestamp, required this.timestamp, required this.eventId});

  factory ProductEventModel.fromJson(Map<String, dynamic> json) {
    return ProductEventModel(
      client: json['client'],
      machine: json['machine'],
      interfaceEpochTimestamp: json['interface_epoch_timestamp'],
      timestamp: json['timestamp'],
      eventId: json['event_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'client': client, 'machine': machine, 'interface_epoch_timestamp': interfaceEpochTimestamp, 'timestamp': timestamp, 'event_id': eventId};
  }

  @override
  String toString() {
    return toJson().toString();
  }
}
