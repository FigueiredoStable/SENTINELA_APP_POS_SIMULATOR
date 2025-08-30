// ignore_for_file: constant_identifier_names

enum InterfaceEventTypesEnum {
  SALE_TRANSACTION('TRANSAÇOES TEF, CÉDULA, MOEDA'),
  PRODUCT('PRODUTO, PRÊMIO'),
  COMMAND('COMANDOS'),
  DELIVERED('DELIVERED'),
  FAILED_DELIVERED('FAILED_DELIVERED'),
  NOT_DELIVERED('NOT_DELIVERED'),
  TIMEOUT('TIMEOUT');

  final String description;
  const InterfaceEventTypesEnum(this.description);
}
