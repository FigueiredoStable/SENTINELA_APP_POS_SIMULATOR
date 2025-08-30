import 'package:flutter/material.dart';
import 'package:sentinela_app_pos_simulator/src/pages/loading/loading_controller.dart';

class WaitingView extends StatefulWidget {
  final LoadingController controller;
  const WaitingView({super.key, required this.controller});

  @override
  State<WaitingView> createState() => _WaitingViewState();
}

class _WaitingViewState extends State<WaitingView> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // Bloqueia completamente a tentativa de voltar
        debugPrint("Voltar bloqueado. didPop: $didPop, result: $result");
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.tealAccent), //
            SizedBox(height: 10),
            ValueListenableBuilder(
              //
              valueListenable: widget.controller.loadingStatus, //
              builder: (context, value, child) {
                return Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
