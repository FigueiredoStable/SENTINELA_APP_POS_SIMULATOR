import 'package:flutter/material.dart';
import 'package:sentinela_app_pos_simulator/utils/constants.dart';

class CountLabel extends StatelessWidget {
  const CountLabel({super.key, required this.countMessage, this.error = false});

  final ValueNotifier<int> countMessage;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 1,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          // color: Color(0xFF213A58),
          color: error ? Colors.red : Color(0xFF46DFB1),
        ),
        child: Center(
          child: Text(
            countMessage.value.toString(),
            style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class PaymentStatusCircle extends StatelessWidget {
  const PaymentStatusCircle({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    var mediaSize = MediaQuery.of(context).size;

    return Container(width: mediaSize.width * 0.4, height: mediaSize.width * 0.4, decoration: Constants.kIconCircleHolder, child: child);
  }
}

class CountDownIndicator extends StatelessWidget {
  final ValueNotifier<double> circleCount;
  final bool error;
  const CountDownIndicator({super.key, required this.circleCount, this.error = false});

  @override
  Widget build(BuildContext context) {
    var mediaSize = MediaQuery.of(context).size;
    return SizedBox(
      //! countdown widget
      width: mediaSize.width * 0.42,
      height: mediaSize.width * 0.42,
      child: ValueListenableBuilder(
        valueListenable: circleCount,
        builder: (context, value, child) {
          return CircularProgressIndicator(
            color: error ? Colors.red : Color(0xFF46DFB1),
            // color: Colors.red,
            value: value,
            strokeWidth: 12,
          );
        },
      ),
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    var mediaSize = MediaQuery.of(context).size;
    return SizedBox(
      width: mediaSize.width * 0.42,
      height: mediaSize.width * 0.42,
      child: CircularProgressIndicator(color: Color(0xFF46DFB1), strokeWidth: 12),
    );
  }
}
