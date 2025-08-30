import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:restart_app/restart_app.dart' show Restart;
import 'package:sentinela_app_pos_simulator/routes/navigation_service.dart';
import 'package:sentinela_app_pos_simulator/src/pages/loading/loading_controller.dart';
import 'package:sentinela_app_pos_simulator/utils/constants.dart';
import 'package:sentinela_app_pos_simulator/utils/utils.dart';

class RegisterReport extends StatelessWidget {
  final LoadingController controller;
  const RegisterReport({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ValueListenableBuilder(
              valueListenable: controller.machineConfiguredInfos,
              builder: (context, value, child) {
                return Column(
                  children: [
                    SizedBox(height: 10),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 18,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AutoSizeText(
                              'MÁQUINA REGISTRADA',
                              style: TextStyle(color: Colors.teal.shade900, fontSize: 18, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              minFontSize: 16,
                              maxFontSize: 18,
                            ),
                            AutoSizeText(
                              value['id'],
                              style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              minFontSize: 10,
                              maxFontSize: 12,
                            ),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                AutoSizeText(
                                  'NOME: ',
                                  style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  minFontSize: 14,
                                  maxFontSize: 16,
                                ),
                                AutoSizeText(
                                  value['name'].toUpperCase(),
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  minFontSize: 14,
                                  maxFontSize: 16,
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                AutoSizeText(
                                  'ENDEREÇO: ',
                                  style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  minFontSize: 14,
                                  maxFontSize: 16,
                                ),
                                AutoSizeText(
                                  value['address'].toUpperCase(),
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  minFontSize: 14,
                                  maxFontSize: 16,
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                AutoSizeText(
                                  'TIPO: ',
                                  style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  minFontSize: 14,
                                  maxFontSize: 16,
                                ),
                                AutoSizeText(
                                  value['machine_type']?['machine_type'].toUpperCase(),
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  minFontSize: 14,
                                  maxFontSize: 16,
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                AutoSizeText(
                                  'CATEGORIA DE PRODUTOS: ',
                                  style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  minFontSize: 14,
                                  maxFontSize: 16,
                                ),
                                AutoSizeText(
                                  value['machine_type']?['product_class'].toUpperCase(),
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  minFontSize: 14,
                                  maxFontSize: 16,
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                AutoSizeText(
                                  'SEGMENTO: ',
                                  style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  minFontSize: 14,
                                  maxFontSize: 16,
                                ),
                                AutoSizeText(
                                  value['machine_type']?['machine_class'].toUpperCase(),
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  minFontSize: 14,
                                  maxFontSize: 16,
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                AutoSizeText(
                                  'DESCRIÇÃO: ',
                                  style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold),
                                ),
                                Flexible(
                                  child: AutoSizeText(
                                    value['machine_type']?['describe'].toUpperCase(),
                                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                    softWrap: true,
                                    maxLines: 3,
                                    minFontSize: 12,
                                    maxFontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                AutoSizeText(
                                  'CRIADO EM: ',
                                  style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  minFontSize: 14,
                                  maxFontSize: 16,
                                ),
                                AutoSizeText(
                                  Utils.utcToLocalTime(value['machine_type']?['created_at']),
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  minFontSize: 14,
                                  maxFontSize: 16,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(gradient: Constants.darkGradient, borderRadius: BorderRadius.circular(12)),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 12,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: Colors.transparent,
                        ),
                        onPressed: () async {
                          GetIt.I.reset(); // limpa todas as instâncias registradas
                          Restart.restartApp(); // reinicia o app para garantir que as instâncias sejam criadas novamente e assuma a nova configuração
                        },
                        child: Text(
                          'FINALIZAR',
                          style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      //width: MediaQuery.of(context).size.width * 0.6,
                      width: double.infinity,
                      decoration: BoxDecoration(gradient: Constants.redGradient, borderRadius: BorderRadius.circular(12)),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 12,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: Colors.transparent,
                        ),
                        onPressed: () {
                          controller.cancelRegisterDevice().then((value) {
                            if (value) {
                              GetIt.I<NavigationService>().pop();
                              controller.loadingViewState.value = LoadingViewState.getAvailableMachines;
                            }
                          });
                        },
                        child: Text(
                          'CANCELAR',
                          style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
