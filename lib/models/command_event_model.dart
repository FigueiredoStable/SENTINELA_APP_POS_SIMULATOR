class CommandEventModel {
  final String client;
  final String machine;
  final String commandDescription;
  final String interfaceResponse;
  final String interfaceEpochTimestamp;
  final bool executed;
  final String eventId;

  CommandEventModel({
    required this.client,
    required this.machine,
    required this.commandDescription,
    required this.interfaceResponse,
    required this.interfaceEpochTimestamp,
    required this.executed,
    required this.eventId,
  });

  factory CommandEventModel.fromJson(Map<String, dynamic> json) {
    return CommandEventModel(
      client: json['client'],
      machine: json['machine'],
      commandDescription: json['command_description'],
      interfaceResponse: json['interface_response'],
      interfaceEpochTimestamp: json['interface_epoch_timestamp'],
      executed: json['executed'],
      eventId: json['event_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client': client,
      'machine': machine,
      'command_description': commandDescription,
      'interface_response': interfaceResponse,
      'interface_epoch_timestamp': interfaceEpochTimestamp,
      'executed': executed,
      'event_id': eventId,
    };
  }

  @override
  String toString() {
    return toJson().toString();
  }
}
