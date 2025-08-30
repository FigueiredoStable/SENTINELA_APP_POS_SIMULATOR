import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:sentinela_app_pos_simulator/components/get_available_machines.dart';
import 'package:sentinela_app_pos_simulator/components/register_report.dart';
import 'package:sentinela_app_pos_simulator/components/user_serial_form.dart';
import 'package:sentinela_app_pos_simulator/services/logger_service.dart';
import 'package:sentinela_app_pos_simulator/src/pages/loading/loading_controller.dart';
import 'package:sentinela_app_pos_simulator/utils/constants.dart';

class LoadingView extends StatefulWidget {
  const LoadingView({super.key});

  @override
  State<LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<LoadingView> {
  final LoadingController loadingController = LoadingController();

  @override
  void initState() {
    super.initState();
    GetIt.I<LoggerService>().i('✅ LoadingView initState');
  }

  @override
  void dispose() {
    loadingController.disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // Bloqueia completamente a tentativa de voltar
        debugPrint("Voltar bloqueado. didPop: $didPop, result: $result");
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: Constants.kbackgroundGradient),
          child: ValueListenableBuilder(
            valueListenable: loadingController.loadingViewState,
            builder: (context, value, child) {
              switch (value) {
                case LoadingViewState.getAvailableMachines:
                  return GetAvailableMachinesForm(controller: loadingController);
                case LoadingViewState.registerReport:
                  return RegisterReport(controller: loadingController);
                default:
                  return UserSerialForm(controller: loadingController);
              }
            },
          ),
        ),
      ),
    );
  }
}
