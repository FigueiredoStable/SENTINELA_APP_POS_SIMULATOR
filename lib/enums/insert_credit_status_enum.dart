// ignore_for_file: constant_identifier_names

enum InsertCreditStatusEnum {
  INSERTING("Inserindo crédito"),
  INSERTED("Crédito inserido"),
  ERROR("Erro ao inserir crédito");

  // value off ENUM
  final String description;
  const InsertCreditStatusEnum(this.description);
}
