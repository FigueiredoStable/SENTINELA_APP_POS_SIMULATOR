import 'package:sentinela_app_pos_simulator/enums/payment_view_type.dart';

class BuyDataModel {
  late String price;
  late String credit;
  late PaymentViewTypeEnum type;

  BuyDataModel({required this.price, required this.credit, required this.type});

  // CopyWith method
  BuyDataModel copyWith({String? price, String? credit, PaymentViewTypeEnum? type}) {
    return BuyDataModel(price: price ?? this.price, credit: credit ?? this.credit, type: type ?? this.type);
  }

  // fromJson method
  BuyDataModel.fromJson(Map<String, dynamic> json) {
    price = json['price'];
    credit = json['credit'];
    type = type;
  }

  // toJson method
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['priceToPay'] = price;
    data['credit'] = credit;
    data['type'] = type;
    return data;
  }
}
