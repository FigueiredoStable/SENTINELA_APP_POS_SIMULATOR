class ApiInititializationGlobalSettings {
  bool? success;
  String? message;
  Configuration? configuration;

  ApiInititializationGlobalSettings({this.success, this.message, this.configuration});

  ApiInititializationGlobalSettings.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    configuration = json['configuration'] != null ? Configuration.fromJson(json['configuration']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (configuration != null) {
      data['configuration'] = configuration!.toJson();
    }
    return data;
  }
}

class Configuration {
  String? id;
  String? name;
  bool? registered;
  bool? blocked;
  bool? available;
  PriceOptions? priceOptions;
  CounterOptions? counterOptions;
  PaymentsTypes? paymentsTypes;
  SupportInformation? supportInformation;
  String? interfaceMacAddress;
  OperationOptions? operationOptions;
  DefaultInitializationSettings? defaultInitializationSettings;
  String? pos;

  Configuration({
    this.id,
    this.name,
    this.registered,
    this.blocked,
    this.available,
    this.priceOptions,
    this.counterOptions,
    this.paymentsTypes,
    this.supportInformation,
    this.interfaceMacAddress,
    this.operationOptions,
    this.defaultInitializationSettings,
    this.pos,
  });

  Configuration.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    registered = json['registered'];
    blocked = json['blocked'];
    available = json['available'];
    priceOptions = json['price_options'] != null ? PriceOptions.fromJson(json['price_options']) : null;
    counterOptions = json['counter_options'] != null ? CounterOptions.fromJson(json['counter_options']) : null;
    paymentsTypes = json['payments_types'] != null ? PaymentsTypes.fromJson(json['payments_types']) : null;
    supportInformation = json['support_information'] != null ? SupportInformation.fromJson(json['support_information']) : null;
    interfaceMacAddress = json['interface_mac_address'];
    operationOptions = json['operation_options'] != null ? OperationOptions.fromJson(json['operation_options']) : null;
    defaultInitializationSettings = json['default_initialization_settings'] != null ? DefaultInitializationSettings.fromJson(json['default_initialization_settings']) : null;
    pos = json['pos'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['registered'] = registered;
    data['blocked'] = blocked;
    data['available'] = available;
    if (priceOptions != null) {
      data['price_options'] = priceOptions!.toJson();
    }
    if (counterOptions != null) {
      data['counter_options'] = counterOptions!.toJson();
    }
    if (paymentsTypes != null) {
      data['payments_types'] = paymentsTypes!.toJson();
    }
    if (supportInformation != null) {
      data['support_information'] = supportInformation!.toJson();
    }
    data['interface_mac_address'] = interfaceMacAddress;
    if (operationOptions != null) {
      data['operation_options'] = operationOptions!.toJson();
    }
    if (defaultInitializationSettings != null) {
      data['default_initialization_settings'] = defaultInitializationSettings!.toJson();
    }
    data['pos'] = pos;
    return data;
  }
}

class PriceOptions {
  List<PriceOpts>? priceOpts;

  PriceOptions({this.priceOpts});

  PriceOptions.fromJson(Map<String, dynamic> json) {
    if (json['price_opts'] != null) {
      priceOpts = <PriceOpts>[];
      json['price_opts'].forEach((v) {
        priceOpts!.add(PriceOpts.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (priceOpts != null) {
      data['price_opts'] = priceOpts!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class PriceOpts {
  String? price;
  bool? active;
  String? credits;

  PriceOpts({this.price, this.active, this.credits});

  PriceOpts.fromJson(Map<String, dynamic> json) {
    price = json['price'];
    active = json['active'];
    credits = json['credits'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['price'] = price;
    data['active'] = active;
    data['credits'] = credits;
    return data;
  }
}

class CounterOptions {
  int? countError;
  int? countSuccess;
  int? counterCardRemoved;
  int? counterWaitingCard;
  int? counterWaitingPass;
  int? countFinalizedSaleTransaction;
  int? countWaitInsertCreditOnInterface;
  int? interfacePingTimeout;
  int? countAbortTransaction;
  int? sendHeartBeatTimer;
  int? supabaseFunctionGlobalTimeout;

  CounterOptions({
    this.countError,
    this.countSuccess,
    this.counterCardRemoved,
    this.counterWaitingCard,
    this.counterWaitingPass,
    this.countFinalizedSaleTransaction,
    this.countWaitInsertCreditOnInterface,
    this.interfacePingTimeout,
    this.countAbortTransaction,
    this.sendHeartBeatTimer,
    this.supabaseFunctionGlobalTimeout,
  });

  CounterOptions.fromJson(Map<String, dynamic> json) {
    countError = json['countError'];
    countSuccess = json['countSuccess'];
    counterCardRemoved = json['counterCardRemoved'];
    counterWaitingCard = json['counterWaitingCard'];
    counterWaitingPass = json['counterWaitingPass'];
    countFinalizedSaleTransaction = json['countFinalizedSaleTransaction'];
    countWaitInsertCreditOnInterface = json['countWaitInsertCreditOnInterface'];
    interfacePingTimeout = json['interfacePingTimeout'];
    countAbortTransaction = json['countAbortTransaction'];
    sendHeartBeatTimer = json['sendHeartBeatTimer'];
    supabaseFunctionGlobalTimeout = json['supabaseFunctionGlobalTimeout'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['countError'] = countError;
    data['countSuccess'] = countSuccess;
    data['counterCardRemoved'] = counterCardRemoved;
    data['counterWaitingCard'] = counterWaitingCard;
    data['counterWaitingPass'] = counterWaitingPass;
    data['countFinalizedSaleTransaction'] = countFinalizedSaleTransaction;
    data['countWaitInsertCreditOnInterface'] = countWaitInsertCreditOnInterface;
    data['interfacePingTimeout'] = interfacePingTimeout;
    data['countAbortTransaction'] = countAbortTransaction;
    data['sendHeartBeatTimer'] = sendHeartBeatTimer;
    data['supabaseFunctionGlobalTimeout'] = supabaseFunctionGlobalTimeout;
    return data;
  }
}

class PaymentsTypes {
  String? title;
  List<Types>? types;

  PaymentsTypes({this.title, this.types});

  PaymentsTypes.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    if (json['types'] != null) {
      types = <Types>[];
      json['types'].forEach((v) {
        types!.add(Types.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    if (types != null) {
      data['types'] = types!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Types {
  String? type;
  bool? active;
  String? description;

  Types({this.type, this.active, this.description});

  Types.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    active = json['active'];
    description = json['description'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['active'] = active;
    data['description'] = description;
    return data;
  }
}

class SupportInformation {
  String? title;
  String? contact;
  String? message;

  SupportInformation({this.title, this.contact, this.message});

  SupportInformation.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    contact = json['contact'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    data['contact'] = contact;
    data['message'] = message;
    return data;
  }
}

class OperationOptions {
  String? workingHoursEnd;
  String? workingHoursStart;
  List<String>? workingDays;

  OperationOptions({this.workingHoursEnd, this.workingHoursStart, this.workingDays});

  OperationOptions.fromJson(Map<String, dynamic> json) {
    workingHoursEnd = json['working_hours_end'];
    workingHoursStart = json['working_hours_start'];
    workingDays = json['working_days'] != null ? List<String>.from(json['working_days']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['working_hours_end'] = workingHoursEnd;
    data['working_hours_start'] = workingHoursStart;
    data['working_days'] = workingDays;
    return data;
  }
}

class DefaultInitializationSettings {
  bool? defaultStateTef;
  bool? defaultStateColectorCoin;
  bool? activateMachineOperationScheduling;
  bool? disableTefPaymentIfInterfaceIsOffline;
  String? maintenanceCode;

  DefaultInitializationSettings({
    this.defaultStateTef,
    this.defaultStateColectorCoin,
    this.activateMachineOperationScheduling,
    this.disableTefPaymentIfInterfaceIsOffline,
    this.maintenanceCode,
  });

  DefaultInitializationSettings.fromJson(Map<String, dynamic> json) {
    defaultStateTef = json['default_state_tef'];
    defaultStateColectorCoin = json['default_state_colector_coin'];
    activateMachineOperationScheduling = json['activate_machine_operation_scheduling'];
    disableTefPaymentIfInterfaceIsOffline = json['disable_tef_payment_if_interface_is_offline'];
    maintenanceCode = json['maintenance_code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['default_state_tef'] = defaultStateTef;
    data['default_state_colector_coin'] = defaultStateColectorCoin;
    data['activate_machine_operation_scheduling'] = activateMachineOperationScheduling;
    data['disable_tef_payment_if_interface_is_offline'] = disableTefPaymentIfInterfaceIsOffline;
    data['maintenance_code'] = maintenanceCode;
    return data;
  }
}
