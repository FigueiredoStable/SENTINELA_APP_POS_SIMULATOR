// ignore_for_file: constant_identifier_names

enum PaymentViewTypeEnum {
  SELECT("Selecione uma das opções\nde pagamento abaixo"),
  CREDIT("CRÉDITO À VISTA"),
  CREDIT_INSTALLMENT("CRÉDITO PARCELADO"),
  DEBIT("DÉBITO"),
  PIX("PIX"),
  VOUCHER("VOUCHER (ALIMENTAÇÃO)");

  // value off ENUM
  final String description;
  const PaymentViewTypeEnum(this.description);
}
